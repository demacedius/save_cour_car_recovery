package handlers

import (
	"backend-go/database"
	"backend-go/models"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// GetUserProfile récupère le profil de l'utilisateur connecté
func GetUserProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Utilisateur non authentifié"})
		return
	}

	var user models.User
	query := `
		SELECT id, email, full_name, first_name, last_name, phone, profile_picture, created_at, updated_at 
		FROM users WHERE id = $1
	`

	err := database.DB.QueryRow(query, userID).Scan(
		&user.ID,
		&user.Email,
		&user.FullName,
		&user.FirstName,
		&user.LastName,
		&user.Phone,
		&user.ProfilePicture,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		fmt.Printf("Erreur récupération profil utilisateur: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération du profil"})
		return
	}

	// Construire la réponse
	response := models.UserResponse{
		ID:             user.ID,
		Email:          user.Email,
		FullName:       user.FullName,
		FirstName:      user.FirstName,
		LastName:       user.LastName,
		Phone:          user.Phone,
		ProfilePicture: user.ProfilePicture,
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Profil récupéré avec succès",
		"user":    response,
	})
}

// UpdateUserProfile met à jour le profil de l'utilisateur
func UpdateUserProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Utilisateur non authentifié"})
		return
	}

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Vérifier si l'email est déjà utilisé par un autre utilisateur
	var existingUserID int
	checkEmailQuery := "SELECT id FROM users WHERE email = $1 AND id != $2"
	err := database.DB.QueryRow(checkEmailQuery, req.Email, userID).Scan(&existingUserID)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Cet email est déjà utilisé par un autre utilisateur"})
		return
	}

	// Construire le nom complet à partir du prénom et nom
	var fullName string
	if req.FirstName != nil && req.LastName != nil {
		fullName = strings.TrimSpace(*req.FirstName + " " + *req.LastName)
	} else if req.FirstName != nil {
		fullName = *req.FirstName
	} else if req.LastName != nil {
		fullName = *req.LastName
	}

	// Mettre à jour le profil
	updateQuery := `
		UPDATE users 
		SET email = $1, full_name = $2, first_name = $3, last_name = $4, phone = $5, updated_at = $6
		WHERE id = $7
	`

	_, err = database.DB.Exec(
		updateQuery,
		req.Email,
		fullName,
		req.FirstName,
		req.LastName,
		req.Phone,
		time.Now(),
		userID,
	)

	if err != nil {
		fmt.Printf("Erreur mise à jour profil: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la mise à jour du profil"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Profil mis à jour avec succès",
	})
}

// UpdatePassword change le mot de passe de l'utilisateur
func UpdatePassword(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Utilisateur non authentifié"})
		return
	}

	var req models.UpdatePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Récupérer le mot de passe actuel hashé
	var currentHashedPassword string
	err := database.DB.QueryRow("SELECT password FROM users WHERE id = $1", userID).Scan(&currentHashedPassword)
	if err != nil {
		fmt.Printf("Erreur récupération mot de passe: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la vérification du mot de passe"})
		return
	}

	// Vérifier le mot de passe actuel
	err = bcrypt.CompareHashAndPassword([]byte(currentHashedPassword), []byte(req.CurrentPassword))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Mot de passe actuel incorrect"})
		return
	}

	// Hasher le nouveau mot de passe
	hashedNewPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		fmt.Printf("Erreur hashage nouveau mot de passe: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors du hashage du mot de passe"})
		return
	}

	// Mettre à jour le mot de passe
	updateQuery := "UPDATE users SET password = $1, updated_at = $2 WHERE id = $3"
	_, err = database.DB.Exec(updateQuery, string(hashedNewPassword), time.Now(), userID)
	if err != nil {
		fmt.Printf("Erreur mise à jour mot de passe: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la mise à jour du mot de passe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Mot de passe changé avec succès",
	})
}

// UploadProfilePicture upload et met à jour la photo de profil
func UploadProfilePicture(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Utilisateur non authentifié"})
		return
	}

	// Récupérer le fichier uploadé
	file, header, err := c.Request.FormFile("profile_picture")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Aucun fichier fourni"})
		return
	}
	defer file.Close()

	// Vérifier le type de fichier
	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/gif":  true,
	}

	contentType := header.Header.Get("Content-Type")
	if !allowedTypes[contentType] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Type de fichier non autorisé. Seules les images sont acceptées."})
		return
	}

	// Vérifier la taille du fichier (max 5MB)
	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Le fichier ne peut pas dépasser 5MB"})
		return
	}

	// Créer le dossier de destination s'il n'existe pas
	uploadDir := "uploads/profile_pictures"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		fmt.Printf("Erreur création dossier: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la création du dossier"})
		return
	}

	// Générer un nom de fichier unique
	userIDStr := strconv.Itoa(userID.(int))
	fileExt := filepath.Ext(header.Filename)
	if fileExt == "" {
		// Déterminer l'extension à partir du content type
		switch contentType {
		case "image/jpeg", "image/jpg":
			fileExt = ".jpg"
		case "image/png":
			fileExt = ".png"
		case "image/gif":
			fileExt = ".gif"
		default:
			fileExt = ".jpg"
		}
	}

	fileName := fmt.Sprintf("user_%s_%d%s", userIDStr, time.Now().Unix(), fileExt)
	filePath := filepath.Join(uploadDir, fileName)

	// Supprimer l'ancienne photo de profil si elle existe
	var oldProfilePicture *string
	err = database.DB.QueryRow("SELECT profile_picture FROM users WHERE id = $1", userID).Scan(&oldProfilePicture)
	if err == nil && oldProfilePicture != nil && *oldProfilePicture != "" {
		oldFilePath := *oldProfilePicture
		if _, err := os.Stat(oldFilePath); err == nil {
			os.Remove(oldFilePath)
		}
	}

	// Sauvegarder le nouveau fichier
	dst, err := os.Create(filePath)
	if err != nil {
		fmt.Printf("Erreur création fichier: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la sauvegarde du fichier"})
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		fmt.Printf("Erreur copie fichier: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la sauvegarde du fichier"})
		return
	}

	// Mettre à jour le chemin de la photo de profil en base
	updateQuery := "UPDATE users SET profile_picture = $1, updated_at = $2 WHERE id = $3"
	_, err = database.DB.Exec(updateQuery, filePath, time.Now(), userID)
	if err != nil {
		fmt.Printf("Erreur mise à jour photo profil: %v\n", err)
		// Supprimer le fichier si la mise à jour en base échoue
		os.Remove(filePath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la mise à jour de la photo de profil"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":         "Photo de profil uploadée avec succès",
		"profile_picture": filePath,
	})
}

// ServeProfilePicture sert les photos de profil statiquement
func ServeProfilePicture(c *gin.Context) {
	fileName := c.Param("filename")
	filePath := filepath.Join("uploads/profile_pictures", fileName)

	// Vérifier que le fichier existe
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fichier non trouvé"})
		return
	}

	c.File(filePath)
}
