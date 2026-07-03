package utils

import (
	"crypto/tls"
	"fmt"
	"net/smtp"
	"os"
)

func SendPasswordResetEmail(toEmail, resetLink string) error {
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASSWORD")
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")

	if smtpHost == "" {
		smtpHost = "smtp.gmail.com"
	}
	if smtpPort == "" {
		smtpPort = "465"
	}
	if smtpUser == "" || smtpPass == "" {
		return fmt.Errorf("SMTP_USER ou SMTP_PASSWORD non configuré")
	}

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
          <tr>
            <td align="center" style="background-color:#6C63FF;padding:32px 24px;">
              <p style="margin:0;font-size:28px;font-weight:bold;color:#ffffff;letter-spacing:1px;">Save Your Car</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 24px;">
              <p style="margin:0 0 8px 0;font-size:20px;font-weight:bold;color:#333333;">Réinitialisation de mot de passe</p>
              <p style="margin:0 0 24px 0;font-size:15px;color:#666666;line-height:1.6;">
                Bonjour,<br><br>
                Vous avez demandé à réinitialiser votre mot de passe. Appuyez sur le bouton ci-dessous pour choisir un nouveau mot de passe.
              </p>
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

	subject := "Réinitialisez votre mot de passe Save Your Car"
	msg := "From: Save Your Car <" + smtpUser + ">\r\n" +
		"To: " + toEmail + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/html; charset=UTF-8\r\n" +
		"\r\n" +
		htmlBody

	tlsConfig := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         smtpHost,
	}

	conn, err := tls.Dial("tcp", smtpHost+":"+smtpPort, tlsConfig)
	if err != nil {
		return fmt.Errorf("erreur connexion SMTP: %v", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, smtpHost)
	if err != nil {
		return fmt.Errorf("erreur client SMTP: %v", err)
	}
	defer client.Quit()

	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	if err = client.Auth(auth); err != nil {
		return fmt.Errorf("erreur authentification SMTP: %v", err)
	}

	if err = client.Mail(smtpUser); err != nil {
		return fmt.Errorf("erreur expéditeur: %v", err)
	}
	if err = client.Rcpt(toEmail); err != nil {
		return fmt.Errorf("erreur destinataire: %v", err)
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("erreur data: %v", err)
	}
	_, err = fmt.Fprint(w, msg)
	if err != nil {
		return fmt.Errorf("erreur écriture email: %v", err)
	}
	if err = w.Close(); err != nil {
		return fmt.Errorf("erreur fermeture: %v", err)
	}

	return nil
}
