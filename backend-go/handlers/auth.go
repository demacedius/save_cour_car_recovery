package handlers

import (
	"backend-go/database"
	"backend-go/models"
	"backend-go/utils"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

func Register(c *gin.Context) {
	var req models.UserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Vérifier si l'email existe déjà
	var exists bool
	err := database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", req.Email).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur serveur"})
		return
	}

	if exists {
		c.JSON(http.StatusConflict, gin.H{"message": "Un compte avec cet email existe déjà"})
		return
	}

	// Hasher le mot de passe
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lors du hashage"})
		return
	}

	// Valeur par défaut pour fullName
	if req.FullName == "" {
		req.FullName = "Utilisateur"
	}

	// Insérer l'utilisateur
	var userID int
	err = database.DB.QueryRow(
		"INSERT INTO users (email, password, full_name) VALUES ($1, $2, $3) RETURNING id",
		req.Email, string(hashedPassword), req.FullName,
	).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lors de la création"})
		return
	}

	// Générer un token JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"email":   req.Email,
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 jours
	})

	tokenString, err := token.SignedString([]byte(os.Getenv("JWT_SECRET")))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur génération token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Compte créé avec succès",
		"user": models.UserResponse{
			ID:       userID,
			Email:    req.Email,
			FullName: req.FullName,
		},
		"token": tokenString,
	})
}

func Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides"})
		return
	}

	// Chercher l'utilisateur
	var user models.User
	err := database.DB.QueryRow(
		"SELECT id, email, password, full_name FROM users WHERE email = $1",
		req.Email,
	).Scan(&user.ID, &user.Email, &user.Password, &user.FullName)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Email ou mot de passe incorrect"})
		return
	}

	// Vérifier le mot de passe
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Email ou mot de passe incorrect"})
		return
	}

	// Générer un token JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"email":   user.Email,
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 jours
	})

	tokenString, err := token.SignedString([]byte(os.Getenv("JWT_SECRET")))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur génération token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user": models.UserResponse{
			ID:       user.ID,
			Email:    user.Email,
			FullName: user.FullName,
		},
		"token": tokenString,
	})
}

func RegisterWithVehicle(c *gin.Context) {
	var req models.RegisterWithVehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		println("❌ Erreur binding JSON:", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	println("✅ Données reçues:", req.Email, req.Plate, req.Model, req.Brand)
	println("✅ Year:", req.Year)
	println("✅ ImageURL:", req.ImageURL)
	println("✅ BrandImageURL:", req.BrandImageURL)
	println("✅ TechnicalControlDate:", req.TechnicalControlDate)

	// Vérifier si l'email existe déjà
	var exists bool
	err := database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", req.Email).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur serveur"})
		return
	}

	if exists {
		c.JSON(http.StatusConflict, gin.H{"message": "Un compte avec cet email existe déjà"})
		return
	}

	// Hasher le mot de passe
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lors du hashage"})
		return
	}

	// Valeur par défaut pour fullName
	if req.FullName == "" {
		req.FullName = "Utilisateur"
	}

	// Commencer une transaction
	tx, err := database.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur transaction"})
		return
	}
	defer tx.Rollback()

	// Insérer l'utilisateur
	var userID int
	err = tx.QueryRow(
		"INSERT INTO users (email, password, full_name) VALUES ($1, $2, $3) RETURNING id",
		req.Email, string(hashedPassword), req.FullName,
	).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création utilisateur"})
		return
	}

	// Convertir la date de contrôle technique si elle existe
	var technicalControlDate interface{} = nil
	if req.TechnicalControlDate != nil && *req.TechnicalControlDate != "" {
		// Parser la date au format ISO ou dd-mm-yyyy
		if parsedDate, err := time.Parse("2006-01-02T15:04:05Z07:00", *req.TechnicalControlDate); err == nil {
			technicalControlDate = parsedDate
		} else if parsedDate, err := time.Parse("02-01-2006", *req.TechnicalControlDate); err == nil {
			technicalControlDate = parsedDate
		}
	}

	// Insérer le véhicule
	println("🚗 Insertion véhicule:", req.Plate, req.Model, req.Brand)
	if req.ImageURL != nil {
		println("🚗 Image véhicule:", *req.ImageURL)
	}
	if req.BrandImageURL != nil {
		println("🚗 Image marque:", *req.BrandImageURL)
	}
	
	_, err = tx.Exec(
		"INSERT INTO vehicles (user_id, plate, model, brand, year, mileage, technical_control_date, image_url, brand_image_url, engine_type, displacement) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)",
		userID, req.Plate, req.Model, req.Brand, req.Year, req.Mileage, technicalControlDate, req.ImageURL, req.BrandImageURL, req.EngineType, req.Displacement,
	)

	if err != nil {
		println("❌ Erreur insertion véhicule:", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création véhicule", "error": err.Error()})
		return
	}

	// Valider la transaction
	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur validation transaction"})
		return
	}

	// Générer un token JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"email":   req.Email,
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 jours
	})

	tokenString, err := token.SignedString([]byte(os.Getenv("JWT_SECRET")))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur génération token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Compte et véhicule créés avec succès",
		"user": models.UserResponse{
			ID:       userID,
			Email:    req.Email,
			FullName: req.FullName,
		},
		"token": tokenString,
	})
}

func ForgotPassword(c *gin.Context) {
	var req models.ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Email requis", "error": err.Error()})
		return
	}

	// Vérifier si l'utilisateur existe
	var userID int
	var email string
	err := database.DB.QueryRow("SELECT id, email FROM users WHERE email = $1", req.Email).Scan(&userID, &email)
	if err != nil {
		// Ne pas révéler si l'email existe ou non pour des raisons de sécurité
		c.JSON(http.StatusOK, gin.H{"message": "Si cet email existe, un lien de réinitialisation a été envoyé."})
		return
	}

	// Générer un token de réinitialisation sécurisé
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur génération token"})
		return
	}
	resetToken := hex.EncodeToString(tokenBytes)

	// Expiration du token (1 heure)
	expiresAt := time.Now().Add(time.Hour)

	// Insérer le token en base
	_, err = database.DB.Exec(
		"INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)",
		userID, resetToken, expiresAt,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur sauvegarde token"})
		return
	}

	// Construire le lien de réinitialisation (lien HTTPS qui redirige vers le deep link)
	resetLink := fmt.Sprintf("https://saveyourcar.fr/reset-password?token=%s", resetToken)

	// Envoyer l'email via Resend
	if err := utils.SendPasswordResetEmail(email, resetLink); err != nil {
		fmt.Printf("❌ Erreur envoi email reset pour %s: %v\n", email, err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur envoi email"})
		return
	}

	fmt.Printf("✅ Email de réinitialisation envoyé à %s\n", email)

	c.JSON(http.StatusOK, gin.H{
		"message": "Si cet email existe, un lien de réinitialisation a été envoyé.",
	})
}

func ResetPassword(c *gin.Context) {
	var req models.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Vérifier le token
	var userID int
	var expiresAt time.Time
	var used bool
	err := database.DB.QueryRow(
		"SELECT user_id, expires_at, used FROM password_reset_tokens WHERE token = $1",
		req.Token,
	).Scan(&userID, &expiresAt, &used)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Token invalide"})
		return
	}

	// Vérifier l'expiration
	if time.Now().After(expiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Token expiré"})
		return
	}

	// Vérifier si déjà utilisé
	if used {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Token déjà utilisé"})
		return
	}

	// Hasher le nouveau mot de passe
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur hashage mot de passe"})
		return
	}

	// Mettre à jour le mot de passe
	_, err = database.DB.Exec("UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", string(hashedPassword), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur mise à jour mot de passe"})
		return
	}

	// Marquer le token comme utilisé
	_, err = database.DB.Exec("UPDATE password_reset_tokens SET used = TRUE WHERE token = $1", req.Token)
	if err != nil {
		// Log l'erreur mais ne pas faire échouer la requête
		fmt.Printf("Erreur marquage token comme utilisé: %v\n", err)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Mot de passe réinitialisé avec succès"})
}

func ResetPasswordPage(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.Data(http.StatusBadRequest, "text/html; charset=utf-8", []byte("<h1>Lien invalide</h1>"))
		return
	}

	deepLink := fmt.Sprintf("saveyourcar://reset-password?token=%s", token)
	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Réinitialisation - Save Your Car</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
    .card { background: white; border-radius: 20px; padding: 40px 32px; max-width: 400px; width: 100%%; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .icon { font-size: 48px; margin-bottom: 16px; }
    h1 { color: #6C63FF; font-size: 22px; margin-bottom: 12px; }
    p { color: #666; font-size: 15px; line-height: 1.5; margin-bottom: 28px; }
    .btn { display: block; background: #6C63FF; color: white; text-decoration: none; padding: 16px 24px; border-radius: 50px; font-size: 16px; font-weight: bold; margin-bottom: 12px; }
  </style>
  <script>
    window.onload = function() {
      window.location.href = "%s";
    };
  </script>
</head>
<body>
  <div class="card">
    <div class="icon">🔐</div>
    <h1>Save Your Car</h1>
    <p>Cliquez sur le bouton ci-dessous pour ouvrir l'application et réinitialiser votre mot de passe.</p>
    <a class="btn" href="%s">Ouvrir l'application</a>
    <p style="font-size: 13px; color: #999;">Si l'application ne s'ouvre pas, assurez-vous qu'elle est installée sur votre téléphone.</p>
  </div>
</body>
</html>`, deepLink, deepLink)

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
}