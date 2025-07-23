package models

import (
	"time"
)

type Subscription struct {
	ID                   int       `json:"id"`
	UserID               int       `json:"user_id"`
	StripeCustomerID     string    `json:"stripe_customer_id"`
	StripeSubscriptionID string    `json:"stripe_subscription_id"`
	StripePriceID        string    `json:"stripe_price_id"`
	Status               string    `json:"status"`
	CurrentPeriodStart   time.Time `json:"current_period_start"`
	CurrentPeriodEnd     time.Time `json:"current_period_end"`
	TrialStart           *time.Time `json:"trial_start,omitempty"`
	TrialEnd             *time.Time `json:"trial_end,omitempty"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}

type CreateSubscriptionRequest struct {
	PriceID         string `json:"price_id" binding:"required"`
	TrialPeriodDays int    `json:"trial_period_days"`
}

type SubscriptionResponse struct {
	ID                 int       `json:"id"`
	Status             string    `json:"status"`
	CurrentPeriodStart time.Time `json:"current_period_start"`
	CurrentPeriodEnd   time.Time `json:"current_period_end"`
	TrialStart         *time.Time `json:"trial_start,omitempty"`
	TrialEnd           *time.Time `json:"trial_end,omitempty"`
	PriceID            string    `json:"price_id"`
	IsActive           bool      `json:"is_active"`
	IsTrialing         bool      `json:"is_trialing"`
}

// Status possibles pour les abonnements
const (
	SubscriptionStatusIncomplete        = "incomplete"
	SubscriptionStatusIncompleteExpired = "incomplete_expired"
	SubscriptionStatusTrialing          = "trialing"
	SubscriptionStatusActive            = "active"
	SubscriptionStatusPastDue           = "past_due"
	SubscriptionStatusCanceled          = "canceled"
	SubscriptionStatusUnpaid            = "unpaid"
	SubscriptionStatusPaused            = "paused"
)

// IsActive vérifie si l'abonnement est actif
func (s *Subscription) IsActive() bool {
	return s.Status == SubscriptionStatusActive || s.Status == SubscriptionStatusTrialing
}

// IsTrialing vérifie si l'abonnement est en période d'essai
func (s *Subscription) IsTrialing() bool {
	return s.Status == SubscriptionStatusTrialing
}

// GetStatusDisplayName retourne le nom d'affichage du statut
func GetSubscriptionStatusDisplayName(status string) string {
	switch status {
	case SubscriptionStatusIncomplete:
		return "Incomplet"
	case SubscriptionStatusIncompleteExpired:
		return "Expiré"
	case SubscriptionStatusTrialing:
		return "Essai gratuit"
	case SubscriptionStatusActive:
		return "Actif"
	case SubscriptionStatusPastDue:
		return "En retard"
	case SubscriptionStatusCanceled:
		return "Annulé"
	case SubscriptionStatusUnpaid:
		return "Impayé"
	case SubscriptionStatusPaused:
		return "En pause"
	default:
		return "Inconnu"
	}
}