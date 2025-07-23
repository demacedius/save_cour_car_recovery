package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"backend-go/database"
	"backend-go/models"
)

func UploadDocument(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Utilisateur non authentifié"})
		return
	}

	var req models.DocumentRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Vérifier que le véhicule appartient à l'utilisateur
	var vehicleExists bool
	err := database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM vehicles WHERE id = $1 AND user_id = $2)", req.VehicleID, userID).Scan(&vehicleExists)
	if err != nil || !vehicleExists {
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé"})
		return
	}

	// Récupérer le fichier uploadé
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Fichier requis", "error": err.Error()})
		return
	}
	defer file.Close()

	// Créer le dossier uploads s'il n'existe pas
	uploadsDir := "uploads/documents"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création dossier"})
		return
	}

	// Générer un nom de fichier unique
	timestamp := time.Now().Unix()
	fileName := fmt.Sprintf("%d_%s", timestamp, header.Filename)
	filePath := filepath.Join(uploadsDir, fileName)

	// Sauvegarder le fichier
	dst, err := os.Create(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur sauvegarde fichier"})
		return
	}
	defer dst.Close()

	fileSize, err := io.Copy(dst, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur copie fichier"})
		return
	}

	// Créer l'entrée en base de données
	var documentID int
	err = database.DB.QueryRow(`
		INSERT INTO documents (vehicle_id, user_id, name, type, description, file_path, file_name, file_size, mime_type, created_at, updated_at) 
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) 
		RETURNING id`,
		req.VehicleID, userID.(int), req.Name, req.Type, req.Description, 
		filePath, header.Filename, fileSize, header.Header.Get("Content-Type"), 
		time.Now(), time.Now(),
	).Scan(&documentID)

	if err != nil {
		// Supprimer le fichier si erreur BDD
		os.Remove(filePath)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur sauvegarde en base"})
		return
	}

	// Retourner la réponse
	response := models.DocumentResponse{
		ID:          documentID,
		VehicleID:   req.VehicleID,
		Name:        req.Name,
		Type:        req.Type,
		Description: req.Description,
		FileName:    header.Filename,
		FileSize:    fileSize,
		DownloadURL: fmt.Sprintf("/documents/%d/download", documentID),
		CreatedAt:   time.Now(),
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Document uploadé avec succès", "document": response})
}

func GetVehicleDocuments(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Utilisateur non authentifié"})
		return
	}

	vehicleIDStr := c.Param("vehicle_id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID véhicule invalide"})
		return
	}

	// Vérifier que le véhicule appartient à l'utilisateur
	var vehicleExists bool
	err = database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM vehicles WHERE id = $1 AND user_id = $2)", vehicleID, userID).Scan(&vehicleExists)
	if err != nil || !vehicleExists {
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé"})
		return
	}

	// Récupérer les documents du véhicule
	rows, err := database.DB.Query(`
		SELECT id, vehicle_id, name, type, description, file_name, file_size, created_at 
		FROM documents 
		WHERE vehicle_id = $1 
		ORDER BY created_at DESC`, vehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération documents"})
		return
	}
	defer rows.Close()

	// Convertir en réponse
	var responses []models.DocumentResponse
	for rows.Next() {
		var doc models.DocumentResponse
		var description *string
		err := rows.Scan(&doc.ID, &doc.VehicleID, &doc.Name, &doc.Type, &description, &doc.FileName, &doc.FileSize, &doc.CreatedAt)
		if err != nil {
			continue
		}
		doc.Description = description
		doc.DownloadURL = fmt.Sprintf("/documents/%d/download", doc.ID)
		responses = append(responses, doc)
	}

	c.JSON(http.StatusOK, gin.H{"documents": responses})
}

func DownloadDocument(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Utilisateur non authentifié"})
		return
	}

	documentIDStr := c.Param("document_id")
	documentID, err := strconv.Atoi(documentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID document invalide"})
		return
	}

	// Récupérer le document et vérifier les permissions
	var filePath, fileName, mimeType string
	err = database.DB.QueryRow(`
		SELECT file_path, file_name, mime_type 
		FROM documents 
		WHERE id = $1 AND user_id = $2`, documentID, userID).Scan(&filePath, &fileName, &mimeType)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Document non trouvé"})
		return
	}

	// Vérifier que le fichier existe
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"message": "Fichier non trouvé"})
		return
	}

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", fileName))
	c.Header("Content-Type", mimeType)
	c.File(filePath)
}

func DeleteDocument(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Utilisateur non authentifié"})
		return
	}

	documentIDStr := c.Param("document_id")
	documentID, err := strconv.Atoi(documentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID document invalide"})
		return
	}

	// Récupérer le document et vérifier les permissions
	var filePath string
	err = database.DB.QueryRow(`
		SELECT file_path 
		FROM documents 
		WHERE id = $1 AND user_id = $2`, documentID, userID).Scan(&filePath)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Document non trouvé"})
		return
	}

	// Supprimer l'entrée en base d'abord
	_, err = database.DB.Exec("DELETE FROM documents WHERE id = $1 AND user_id = $2", documentID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur suppression en base"})
		return
	}

	// Supprimer le fichier physique
	if err := os.Remove(filePath); err != nil {
		fmt.Printf("Erreur suppression fichier: %v\n", err)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Document supprimé avec succès"})
}