package main

import (
	"fmt"
	"os"
	

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/price"
)

func main() {
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")
	if stripe.Key == "" {
		fmt.Println("Error: STRIPE_SECRET_KEY environment variable not set.")
		return
	}

	monthlyPriceID := "price_1RzNCQBO0KsxxPgtqALYncGp"
	yearlyPriceID := "price_1RzN3OBO0KsxxPgtkwx0kuZJ"

	fmt.Printf("Verifying monthly price ID: %s\n", monthlyPriceID)
	pMonthly, err := price.Get(monthlyPriceID, nil)
	if err != nil {
		fmt.Printf("Error fetching monthly price: %v\n", err)
	} else {
		fmt.Printf("Monthly Price Details:\n")
		fmt.Printf("  ID: %s\n", pMonthly.ID)
		fmt.Printf("  Nickname: %s\n", pMonthly.Nickname)
		fmt.Printf("  Unit Amount: %d %s\n", pMonthly.UnitAmount, pMonthly.Currency)
		fmt.Printf("  Recurring Interval: %s\n", pMonthly.Recurring.Interval)
	}

	fmt.Printf("\nVerifying yearly price ID: %s\n", yearlyPriceID)
	pYearly, err := price.Get(yearlyPriceID, nil)
	if err != nil {
		fmt.Printf("Error fetching yearly price: %v\n", err)
	} else {
		fmt.Printf("Yearly Price Details:\n")
		fmt.Printf("  ID: %s\n", pYearly.ID)
		fmt.Printf("  Nickname: %s\n", pYearly.Nickname)
		fmt.Printf("  Unit Amount: %d %s\n", pYearly.UnitAmount, pYearly.Currency)
		fmt.Printf("  Recurring Interval: %s\n", pYearly.Recurring.Interval)
	}
}
