package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type resendEmail struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	Html    string   `json:"html"`
}

func SendPasswordResetEmail(toEmail, resetLink string) error {
	apiKey := os.Getenv("RESEND_API_KEY")

	htmlBody := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
  <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 16px; padding: 40px;">
    <h2 style="color: #6C63FF; text-align: center;">Save Your Car</h2>
    <h3 style="color: #333;">Réinitialisation de votre mot de passe</h3>
    <p style="color: #555;">Bonjour,</p>
    <p style="color: #555;">Vous avez demandé à réinitialiser votre mot de passe. Cliquez sur le bouton ci-dessous pour choisir un nouveau mot de passe :</p>
    <div style="text-align: center; margin: 32px 0;">
      <a href="%s"
         style="background-color: #6C63FF; color: white; padding: 14px 32px; text-decoration: none; border-radius: 25px; font-weight: bold; font-size: 16px;">
        Réinitialiser mon mot de passe
      </a>
    </div>
    <p style="color: #888; font-size: 13px;">⏱ Ce lien expire dans <strong>1 heure</strong>.</p>
    <p style="color: #888; font-size: 13px;">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
    <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
    <p style="color: #bbb; font-size: 12px; text-align: center;">© Save Your Car</p>
  </div>
</body>
</html>`, resetLink)

	payload := resendEmail{
		From:    "Save Your Car <onboarding@resend.dev>",
		To:      []string{toEmail},
		Subject: "Réinitialisez votre mot de passe Save Your Car",
		Html:    htmlBody,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("erreur sérialisation email: %v", err)
	}

	req, err := http.NewRequest("POST", "https://api.resend.com/emails", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("erreur création requête: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("erreur envoi email: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		return fmt.Errorf("Resend API erreur: status %d", resp.StatusCode)
	}

	return nil
}
