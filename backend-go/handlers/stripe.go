package handlers

import (
	"backend-go/database"
	"backend-go/models"
	"database/sql"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/customer"
	"github.com/stripe/stripe-go/v76/subscription"
	"github.com/stripe/stripe-go/webhook"
)

func init() {
	// Initialiser Stripe avec la clé secrète
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")
}

// CreateSubscription crée un nouvel abonnement Stripe
func CreateSubscription(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	var req models.CreateSubscriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Vérifier si l'utilisateur a déjà un abonnement
	var existingSubID int
	err := database.DB.QueryRow("SELECT id FROM subscriptions WHERE user_id = $1", userID).Scan(&existingSubID)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"message": "L'utilisateur a déjà un abonnement"})
		return
	}

	// Récupérer les infos utilisateur
	var userEmail, userName string
	err = database.DB.QueryRow("SELECT email, full_name FROM users WHERE id = $1", userID).Scan(&userEmail, &userName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération utilisateur"})
		return
	}

	// Créer ou récupérer le customer Stripe
	customerParams := &stripe.CustomerParams{
		Email: stripe.String(userEmail),
		Name:  stripe.String(userName),
		Metadata: map[string]string{
			"user_id": strconv.Itoa(userID.(int)),
		},
	}

	stripeCustomer, err := customer.New(customerParams)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création customer Stripe", "error": err.Error()})
		return
	}

	// Créer l'abonnement
	subscriptionParams := &stripe.SubscriptionParams{
		Customer: stripe.String(stripeCustomer.ID),
		Items: []*stripe.SubscriptionItemsParams{
			{
				Price: stripe.String(req.PriceID),
			},
		},
		PaymentSettings: &stripe.SubscriptionPaymentSettingsParams{
			SaveDefaultPaymentMethod: stripe.String("on_subscription"),
		},
	}

	// Configuration différente selon la présence d'essai gratuit
	if req.TrialPeriodDays > 0 {
		// Pour les essais gratuits : pas de paiement immédiat
		subscriptionParams.TrialPeriodDays = stripe.Int64(int64(req.TrialPeriodDays))
		subscriptionParams.PaymentBehavior = stripe.String("default_incomplete")
		subscriptionParams.Expand = []*string{stripe.String("pending_setup_intent")}
	} else {
		// Pour les abonnements sans essai : paiement immédiat
		subscriptionParams.PaymentBehavior = stripe.String("default_incomplete")
		subscriptionParams.Expand = []*string{stripe.String("latest_invoice.payment_intent")}
	}

	stripeSubscription, err := subscription.New(subscriptionParams)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création abonnement", "error": err.Error()})
		return
	}

	// Sauvegarder l'abonnement en base
	var trialStart, trialEnd *time.Time
	if stripeSubscription.TrialStart != 0 {
		ts := time.Unix(stripeSubscription.TrialStart, 0)
		trialStart = &ts
	}
	if stripeSubscription.TrialEnd != 0 {
		te := time.Unix(stripeSubscription.TrialEnd, 0)
		trialEnd = &te
	}

	_, err = database.DB.Exec(`
		INSERT INTO subscriptions 
		(user_id, stripe_customer_id, stripe_subscription_id, stripe_price_id, status, 
		 current_period_start, current_period_end, trial_start, trial_end)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		userID,
		stripeCustomer.ID,
		stripeSubscription.ID,
		req.PriceID,
		string(stripeSubscription.Status),
		time.Unix(stripeSubscription.CurrentPeriodStart, 0),
		time.Unix(stripeSubscription.CurrentPeriodEnd, 0),
		trialStart,
		trialEnd,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur sauvegarde abonnement", "error": err.Error()})
		return
	}

	// Retourner le client secret approprié
	var clientSecret string
	var setupRequired bool

	if req.TrialPeriodDays > 0 {
		// Pour les essais gratuits : utiliser setup intent
		if stripeSubscription.PendingSetupIntent != nil {
			clientSecret = stripeSubscription.PendingSetupIntent.ClientSecret
			setupRequired = true
		}
	} else {
		// Pour les abonnements sans essai : utiliser payment intent
		if stripeSubscription.LatestInvoice != nil && stripeSubscription.LatestInvoice.PaymentIntent != nil {
			clientSecret = stripeSubscription.LatestInvoice.PaymentIntent.ClientSecret
			setupRequired = false
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"subscription_id": stripeSubscription.ID,
		"client_secret":   clientSecret,
		"status":          stripeSubscription.Status,
		"setup_required":  setupRequired,
		"trial_period":    req.TrialPeriodDays > 0,
	})
}

// GetSubscriptionStatus récupère le statut d'abonnement de l'utilisateur
func GetSubscriptionStatus(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	var sub models.Subscription
	var trialStart, trialEnd sql.NullTime

	err := database.DB.QueryRow(`
		SELECT id, stripe_customer_id, stripe_subscription_id, stripe_price_id, status,
		       current_period_start, current_period_end, trial_start, trial_end, created_at
		FROM subscriptions WHERE user_id = $1`, userID).Scan(
		&sub.ID,
		&sub.StripeCustomerID,
		&sub.StripeSubscriptionID,
		&sub.StripePriceID,
		&sub.Status,
		&sub.CurrentPeriodStart,
		&sub.CurrentPeriodEnd,
		&trialStart,
		&trialEnd,
		&sub.CreatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "Aucun abonnement trouvé"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération abonnement"})
		return
	}

	// Conversion des NullTime
	if trialStart.Valid {
		sub.TrialStart = &trialStart.Time
	}
	if trialEnd.Valid {
		sub.TrialEnd = &trialEnd.Time
	}

	response := models.SubscriptionResponse{
		ID:                 sub.ID,
		Status:             sub.Status,
		CurrentPeriodStart: sub.CurrentPeriodStart,
		CurrentPeriodEnd:   sub.CurrentPeriodEnd,
		TrialStart:         sub.TrialStart,
		TrialEnd:           sub.TrialEnd,
		PriceID:            sub.StripePriceID,
		IsActive:           sub.IsActive(),
		IsTrialing:         sub.IsTrialing(),
	}

	c.JSON(http.StatusOK, response)
}

// CancelSubscription annule un abonnement
func CancelSubscription(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	// Récupérer l'abonnement de l'utilisateur
	var stripeSubscriptionID string
	err := database.DB.QueryRow("SELECT stripe_subscription_id FROM subscriptions WHERE user_id = $1", userID).Scan(&stripeSubscriptionID)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "Aucun abonnement trouvé"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération abonnement"})
		return
	}

	// Annuler l'abonnement sur Stripe
	cancelParams := &stripe.SubscriptionParams{
		CancelAtPeriodEnd: stripe.Bool(true),
	}

	stripeSubscription, err := subscription.Update(stripeSubscriptionID, cancelParams)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur annulation Stripe", "error": err.Error()})
		return
	}

	// Mettre à jour le statut en base
	_, err = database.DB.Exec("UPDATE subscriptions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2",
		string(stripeSubscription.Status), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur mise à jour base de données"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":              "Abonnement programmé pour annulation",
		"cancel_at_period_end": stripeSubscription.CancelAtPeriodEnd,
		"current_period_end":   time.Unix(stripeSubscription.CurrentPeriodEnd, 0),
	})
}

// GetSubscriptionClientSecret récupère le client secret pour un abonnement incomplet
func GetSubscriptionClientSecret(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	var sub models.Subscription
	err := database.DB.QueryRow("SELECT stripe_subscription_id, status FROM subscriptions WHERE user_id = $1", userID).Scan(&sub.StripeSubscriptionID, &sub.Status)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "Aucun abonnement trouvé pour cet utilisateur"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération abonnement", "error": err.Error()})
		return
	}

	if sub.Status != string(stripe.SubscriptionStatusIncomplete) && sub.Status != string(stripe.SubscriptionStatusTrialing) {
		c.JSON(http.StatusBadRequest, gin.H{"message": "L'abonnement n'est pas dans un état nécessitant un client secret (incomplete ou trialing)"})
		return
	}

	stripeSubscription, err := subscription.Get(sub.StripeSubscriptionID, &stripe.SubscriptionParams{
		Expand: []*string{stripe.String("pending_setup_intent"), stripe.String("latest_invoice.payment_intent")},
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération abonnement Stripe", "error": err.Error()})
		return
	}

	var clientSecret string
	var setupRequired bool

	if stripeSubscription.PendingSetupIntent != nil {
		clientSecret = stripeSubscription.PendingSetupIntent.ClientSecret
		setupRequired = true
	} else if stripeSubscription.LatestInvoice != nil && stripeSubscription.LatestInvoice.PaymentIntent != nil {
		clientSecret = stripeSubscription.LatestInvoice.PaymentIntent.ClientSecret
		setupRequired = false
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Client secret non trouvé pour cet abonnement"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"client_secret":  clientSecret,
		"setup_required": setupRequired,
	})
}

// HandleStripeWebhook gère les événements webhook de Stripe
func HandleStripeWebhook(c *gin.Context) {
	const MaxBodyBytes = int64(65536) // 64KB
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, MaxBodyBytes)
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "Erreur lecture corps requête", "error": err.Error()})
		return
	}

	// Vérifier la signature du webhook
	endpointSecret := os.Getenv("STRIPE_WEBHOOK_SECRET")
	if endpointSecret == "" {
		log.Println("STRIPE_WEBHOOK_SECRET non configuré")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Webhook secret non configuré"})
		return
	}

	signatureHeader := c.GetHeader("Stripe-Signature")
	event, err := webhook.ConstructEvent(body, signatureHeader, endpointSecret)
	if err != nil {
		log.Printf("Erreur vérification signature webhook: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{"message": "Erreur vérification signature webhook"})
		return
	}

	// Gérer les différents types d'événements
	switch event.Type {
	case "customer.subscription.updated":
		var subscription stripe.Subscription
		err := json.Unmarshal(event.Data.Raw, &subscription)
		if err != nil {
			log.Printf("Erreur unmarshalling subscription.updated: %v\n", err)
			c.JSON(http.StatusBadRequest, gin.H{"message": "Erreur parsing événement"})
			return
		}
		log.Printf("Subscription %s updated to status %s\n", subscription.ID, subscription.Status)
		// Mettre à jour le statut dans la base de données locale
		_, err = database.DB.Exec("UPDATE subscriptions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE stripe_subscription_id = $2",
			string(subscription.Status), subscription.ID)
		if err != nil {
			log.Printf("Erreur mise à jour statut abonnement en base: %v\n", err)
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur mise à jour base de données"})
			return
		}
	case "invoice.payment_succeeded":
		var invoice stripe.Invoice
		err := json.Unmarshal(event.Data.Raw, &invoice)
		if err != nil {
			log.Printf("Erreur unmarshalling invoice.payment_succeeded: %v\n", err)
			c.JSON(http.StatusBadRequest, gin.H{"message": "Erreur parsing événement"})
			return
		}
		log.Printf("Invoice %s payment succeeded. Subscription ID: %s\n", invoice.ID, invoice.Subscription.ID)
		// Optionnel: Mettre à jour le statut de l'abonnement si nécessaire (customer.subscription.updated devrait déjà le faire)
	case "payment_intent.succeeded":
		var paymentIntent stripe.PaymentIntent
		err := json.Unmarshal(event.Data.Raw, &paymentIntent)
		if err != nil {
			log.Printf("Erreur unmarshalling payment_intent.succeeded: %v\n", err)
			c.JSON(http.StatusBadRequest, gin.H{"message": "Erreur parsing événement"})
			return
		}
		log.Printf("PaymentIntent %s succeeded. Customer ID: %s\n", paymentIntent.ID, paymentIntent.Customer.ID)
		// Optionnel: Mettre à jour le statut de l'abonnement si nécessaire
	case "payment_intent.payment_failed":
		var paymentIntent stripe.PaymentIntent
		err := json.Unmarshal(event.Data.Raw, &paymentIntent)
		if err != nil {
			log.Printf("Erreur unmarshalling payment_intent.payment_failed: %v\n", err)
			c.JSON(http.StatusBadRequest, gin.H{"message": "Erreur parsing événement"})
			return
		}
		log.Printf("PaymentIntent %s failed. Customer ID: %s\n", paymentIntent.ID, paymentIntent.Customer.ID)
		// Optionnel: Mettre à jour le statut de l'abonnement si nécessaire
	default:
		log.Printf("Type d'événement webhook non géré: %s\n", event.Type)
	}

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}
