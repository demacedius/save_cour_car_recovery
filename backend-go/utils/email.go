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

	htmlBody := fmt.Sprintf(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Réinitialisation mot de passe</title>
</head>
<body style="margin:0;padding:0;background-color:#f5f5f5;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f5f5f5;padding:20px 0;">
    <tr>
      <td align="center">
        <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="max-width:500px;background-color:#ffffff;border-radius:16px;overflow:hidden;">
          <!-- Header -->
          <tr>
            <td align="center" style="background-color:#6C63FF;padding:32px 24px;">
              <p style="margin:0;font-size:28px;font-weight:bold;color:#ffffff;letter-spacing:1px;">Save Your Car</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:32px 24px;">
              <p style="margin:0 0 8px 0;font-size:20px;font-weight:bold;color:#333333;">Réinitialisation de mot de passe</p>
              <p style="margin:0 0 24px 0;font-size:15px;color:#666666;line-height:1.6;">
                Bonjour,<br><br>
                Vous avez demandé à réinitialiser votre mot de passe. Appuyez sur le bouton ci-dessous pour choisir un nouveau mot de passe.
              </p>
              <!-- Button -->
              <table width="100%%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td align="center" style="padding:8px 0 24px 0;">
                    <a href="%s" style="display:inline-block;background-color:#6C63FF;color:#ffffff;text-decoration:none;padding:16px 40px;border-radius:50px;font-size:16px;font-weight:bold;">
                      Réinitialiser mon mot de passe
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 8px 0;font-size:13px;color:#999999;">⏱ Ce lien expire dans <strong>1 heure</strong>.</p>
              <p style="margin:0;font-size:13px;color:#999999;">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color:#f9f9f9;padding:16px 24px;text-align:center;border-top:1px solid #eeeeee;">
              <p style="margin:0;font-size:12px;color:#bbbbbb;">© Save Your Car</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
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
