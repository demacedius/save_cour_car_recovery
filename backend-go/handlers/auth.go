package handlers

import (
	"backend-go/database"
	"backend-go/models"
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
		"INSERT INTO vehicles (user_id, plate, model, brand, year, mileage, technical_control_date, image_url, brand_image_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
		userID, req.Plate, req.Model, req.Brand, req.Year, req.Mileage, technicalControlDate, req.ImageURL, req.BrandImageURL,
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

	// TODO: Envoyer l'email avec le lien de réinitialisation
	// Pour l'instant, on retourne le token (à ne pas faire en production)
	resetLink := fmt.Sprintf("http://yourapp.com/reset-password?token=%s", resetToken)
	
	// En développement, log le lien
	fmt.Printf("🔗 Lien de réinitialisation pour %s: %s\n", email, resetLink)

	c.JSON(http.StatusOK, gin.H{
		"message": "Si cet email existe, un lien de réinitialisation a été envoyé.",
		"resetLink": resetLink, // Temporaire pour les tests
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