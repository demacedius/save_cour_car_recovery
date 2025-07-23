package main

import (
	"fmt"
	"log"
	"os"

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/price"
	"github.com/stripe/stripe-go/v76/product"
)

func main() {
	// Utiliser votre clé secrète de test
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")

	// Créer le produit mensuel
	monthlyProduct, err := product.New(&stripe.ProductParams{
		Name:        stripe.String("Save Your Car Monthly"),
		Description: stripe.String("Abonnement mensuel Save Your Car"),
	})
	if err != nil {
		log.Fatal("Erreur création produit mensuel:", err)
	}

	// Créer le prix mensuel
	monthlyPrice, err := price.New(&stripe.PriceParams{
		Product:    stripe.String(monthlyProduct.ID),
		UnitAmount: stripe.Int64(999), // 9,99€
		Currency:   stripe.String("eur"),
		Recurring: &stripe.PriceRecurringParams{
			Interval: stripe.String("month"),
		},
	})
	if err != nil {
		log.Fatal("Erreur création prix mensuel:", err)
	}

	// Créer le produit annuel
	yearlyProduct, err := product.New(&stripe.ProductParams{
		Name:        stripe.String("Save Your Car Yearly"),
		Description: stripe.String("Abonnement annuel Save Your Car"),
	})
	if err != nil {
		log.Fatal("Erreur création produit annuel:", err)
	}

	// Créer le prix annuel
	yearlyPrice, err := price.New(&stripe.PriceParams{
		Product:    stripe.String(yearlyProduct.ID),
		UnitAmount: stripe.Int64(2999), // 29,99€
		Currency:   stripe.String("eur"),
		Recurring: &stripe.PriceRecurringParams{
			Interval: stripe.String("year"),
		},
	})
	if err != nil {
		log.Fatal("Erreur création prix annuel:", err)
	}

	fmt.Println("✅ Produits et prix créés avec succès!")
	fmt.Printf("📦 Produit mensuel: %s\n", monthlyProduct.ID)
	fmt.Printf("💰 Prix mensuel: %s\n", monthlyPrice.ID)
	fmt.Printf("📦 Produit annuel: %s\n", yearlyProduct.ID)
	fmt.Printf("💰 Prix annuel: %s\n", yearlyPrice.ID)
	fmt.Println("\n🔧 Mettez à jour stripe_config.dart avec ces IDs:")
	fmt.Printf("static const String monthlyPriceId = '%s';\n", monthlyPrice.ID)
	fmt.Printf("static const String yearlyPriceId = '%s';\n", yearlyPrice.ID)
}
