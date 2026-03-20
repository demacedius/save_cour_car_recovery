package handlers

import (
	"backend-go/database"
	"backend-go/models"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
)

func CreateVehicle(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	var req models.VehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	var vehicleID int
	err := database.DB.QueryRow(
		"INSERT INTO vehicles (user_id, plate, model, brand, year, mileage, technical_control_date, image_url, brand_image_url, engine_type, displacement) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id",
		userID, req.Plate, req.Model, req.Brand, req.Year, req.Mileage, req.TechnicalControlDate, req.ImageURL, req.BrandImageURL, req.EngineType, req.Displacement,
	).Scan(&vehicleID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création véhicule"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":    "Véhicule créé avec succès",
		"vehicle_id": vehicleID,
	})
}

func GetUserVehicles(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	rows, err := database.DB.Query(
		"SELECT id, plate, model, brand, year, mileage, technical_control_date, image_url, brand_image_url, engine_type, displacement, created_at, updated_at FROM vehicles WHERE user_id = $1",
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération véhicules"})
		return
	}
	defer rows.Close()

	var vehicles []models.Vehicle
	for rows.Next() {
		var v models.Vehicle
		err := rows.Scan(&v.ID, &v.Plate, &v.Model, &v.Brand, &v.Year, &v.Mileage, &v.TechnicalControlDate, &v.ImageURL, &v.BrandImageURL, &v.EngineType, &v.Displacement, &v.CreatedAt, &v.UpdatedAt)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lecture véhicules"})
			return
		}
		v.UserID = userID.(int)
		vehicles = append(vehicles, v)
	}

	c.JSON(http.StatusOK, gin.H{
		"vehicles": vehicles,
	})
}

func GetVehicleFromPlate(c *gin.Context) {
	var req struct {
		Plate string `json:"plate" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Plaque d'immatriculation requise"})
		return
	}

	// Appel à l'API SIV RapidAPI
	url := "https://api-siv-systeme-d-immatriculation-des-vehicules.p.rapidapi.com/" + req.Plate

	request, err := http.NewRequest("GET", url, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création requête"})
		return
	}

	request.Header.Add("x-rapidapi-key", os.Getenv("RAPIDAPI_KEY"))
	request.Header.Add("x-rapidapi-host", "api-siv-systeme-d-immatriculation-des-vehicules.p.rapidapi.com")

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur appel API SIV"})
		return
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lecture réponse"})
		return
	}

	if response.StatusCode != 200 {
		// Log pour voir ce que retourne l'API en cas d'erreur
		println("❌ API SIV Error - Status:", response.StatusCode)
		println("❌ Response body:", string(body))
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé dans la base SIV"})
		return
	}

	// Parser la réponse JSON de l'API SIV
	var sivData map[string]interface{}
	if err := json.Unmarshal(body, &sivData); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur parsing données SIV"})
		return
	}

	// Log pour voir la structure exacte des données SIV (optionnel)
	fmt.Printf("🔍 Réponse brute de l'API SIV: %s\n", string(body))
	fmt.Printf("🔍 Données parsées: %+v\n", sivData)

	// Extraire les données du champ "data"
	dataField, ok := sivData["data"].(map[string]interface{})
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Format de données SIV invalide"})
		return
	}

	// Retourner les données dans le format attendu par Flutter
	vehicleData := gin.H{
		"plate":                req.Plate,
		"brand":                dataField["AWN_marque"],
		"model":                dataField["AWN_modele"],
		"year":                 dataField["AWN_annee_de_debut_modele"],
		"imageUrl":             dataField["AWN_model_image"],
		"brandImageUrl":        dataField["AWN_url_image"],
		"technicalControlDate": dataField["AWN_date_derniere_cg"],
	}

	c.JSON(http.StatusOK, vehicleData)
}

func UpdateVehicle(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID véhicule invalide"})
		return
	}

	var req models.VehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Vérifier que le véhicule appartient à l'utilisateur
	var exists_vehicle bool
	err = database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM vehicles WHERE id = $1 AND user_id = $2)", vehicleID, userID).Scan(&exists_vehicle)
	if err != nil || !exists_vehicle {
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé"})
		return
	}

	_, err = database.DB.Exec(
		"UPDATE vehicles SET plate = $1, model = $2, brand = $3, year = $4, mileage = $5, technical_control_date = $6, image_url = $7, brand_image_url = $8, engine_type = $9, displacement = $10, updated_at = CURRENT_TIMESTAMP WHERE id = $11",
		req.Plate, req.Model, req.Brand, req.Year, req.Mileage, req.TechnicalControlDate, req.ImageURL, req.BrandImageURL, req.EngineType, req.Displacement, vehicleID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur mise à jour véhicule"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Véhicule mis à jour avec succès"})
}

func DeleteVehicle(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID véhicule invalide"})
		return
	}

	result, err := database.DB.Exec("DELETE FROM vehicles WHERE id = $1 AND user_id = $2", vehicleID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur suppression véhicule"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Véhicule supprimé avec succès"})
}

func UpdateVehicleBrandImages(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	// Récupérer tous les véhicules de l'utilisateur sans brand_image_url
	rows, err := database.DB.Query(
		"SELECT id, plate FROM vehicles WHERE user_id = $1 AND (brand_image_url IS NULL OR brand_image_url = '')",
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération véhicules"})
		return
	}
	defer rows.Close()

	var updatedCount int
	var errorCount int

	for rows.Next() {
		var vehicleID int
		var plate string
		err := rows.Scan(&vehicleID, &plate)
		if err != nil {
			println("❌ Erreur scan:", err.Error())
			errorCount++
			continue
		}

		println("🔍 Traitement véhicule ID:", vehicleID, "Plaque:", plate)

		// Appel à l'API SIV pour récupérer la brand_image_url
		url := "https://api-siv-systeme-d-immatriculation-des-vehicules.p.rapidapi.com/" + plate

		request, err := http.NewRequest("GET", url, nil)
		if err != nil {
			println("❌ Erreur création requête pour", plate, ":", err.Error())
			errorCount++
			continue
		}

		request.Header.Add("x-rapidapi-key", os.Getenv("RAPIDAPI_KEY"))
		request.Header.Add("x-rapidapi-host", "api-siv-systeme-d-immatriculation-des-vehicules.p.rapidapi.com")

		client := &http.Client{}
		response, err := client.Do(request)
		if err != nil {
			println("❌ Erreur appel API pour", plate, ":", err.Error())
			errorCount++
			continue
		}

		body, err := io.ReadAll(response.Body)
		response.Body.Close()
		if err != nil {
			println("❌ Erreur lecture body pour", plate, ":", err.Error())
			errorCount++
			continue
		}

		if response.StatusCode != 200 {
			println("❌ API SIV Error pour", plate, "- Status:", response.StatusCode)
			println("❌ Response body:", string(body))
			errorCount++
			continue
		}

		// Parser la réponse JSON
		var sivData map[string]interface{}
		if err := json.Unmarshal(body, &sivData); err != nil {
			println("❌ Erreur parsing JSON pour", plate, ":", err.Error())
			errorCount++
			continue
		}

		// Extraire les données
		dataField, ok := sivData["data"].(map[string]interface{})
		if !ok {
			println("❌ Pas de field 'data' pour", plate)
			errorCount++
			continue
		}

		// Log de toutes les clés disponibles pour debug
		println("🔍 Clés disponibles pour", plate, ":")
		for key := range dataField {
			println("  -", key)
		}

		// Essayons plusieurs noms de champs possibles
		brandImageURL := ""
		if url, ok := dataField["AWN_brand_img_full_path"].(string); ok {
			brandImageURL = url
		} else if url, ok := dataField["AWN_url_image"].(string); ok {
			brandImageURL = url
		} else if url, ok := dataField["brand_image_url"].(string); ok {
			brandImageURL = url
		} else if url, ok := dataField["AWN_brand_img"].(string); ok {
			brandImageURL = url
		}
		
		println("🔍 Brand image URL trouvée pour", plate, ":", brandImageURL)
		
		if brandImageURL != "" {
			// Mettre à jour le véhicule avec la brand_image_url
			_, err = database.DB.Exec(
				"UPDATE vehicles SET brand_image_url = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
				brandImageURL, vehicleID,
			)
			if err != nil {
				println("❌ Erreur UPDATE DB pour", plate, ":", err.Error())
				errorCount++
			} else {
				println("✅ Véhicule", plate, "mis à jour avec brand_image_url")
				updatedCount++
			}
		} else {
			println("❌ Brand image URL vide pour", plate)
			errorCount++
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Mise à jour terminée",
		"updated": updatedCount,
		"errors":  errorCount,
	})
}

func TransferVehicle(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID véhicule invalide"})
		return
	}

	var req models.TransferVehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Email du nouveau propriétaire requis", "error": err.Error()})
		return
	}

	// Vérifier que le véhicule appartient à l'utilisateur
	var vehicleExists bool
	err = database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM vehicles WHERE id = $1 AND user_id = $2)", vehicleID, userID).Scan(&vehicleExists)
	if err != nil || !vehicleExists {
		c.JSON(http.StatusNotFound, gin.H{"message": "Véhicule non trouvé"})
		return
	}

	// Vérifier si l'utilisateur destinataire existe
	var newOwnerID int
	err = database.DB.QueryRow("SELECT id FROM users WHERE email = $1", req.NewOwnerEmail).Scan(&newOwnerID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Utilisateur destinataire non trouvé. L'utilisateur doit d'abord créer un compte."})
		return
	}

	// Démarrer une transaction pour transférer le véhicule et ses documents
	tx, err := database.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur démarrage transaction"})
		return
	}
	defer tx.Rollback()

	// Transférer le véhicule
	_, err = tx.Exec("UPDATE vehicles SET user_id = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", newOwnerID, vehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur transfert véhicule"})
		return
	}

	// Transférer tous les documents associés au véhicule
	_, err = tx.Exec("UPDATE documents SET user_id = $1, updated_at = CURRENT_TIMESTAMP WHERE vehicle_id = $2", newOwnerID, vehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur transfert documents"})
		return
	}

	// Transférer tous les rendez-vous associés au véhicule
	_, err = tx.Exec("UPDATE appointments SET user_id = $1, updated_at = CURRENT_TIMESTAMP WHERE vehicle_id = $2", newOwnerID, vehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur transfert rendez-vous"})
		return
	}

	// Compter le nombre de documents transférés
	var documentCount int
	err = tx.QueryRow("SELECT COUNT(*) FROM documents WHERE vehicle_id = $1", vehicleID).Scan(&documentCount)
	if err != nil {
		documentCount = 0
	}

	// Compter le nombre de rendez-vous transférés
	var appointmentCount int
	err = tx.QueryRow("SELECT COUNT(*) FROM appointments WHERE vehicle_id = $1", vehicleID).Scan(&appointmentCount)
	if err != nil {
		appointmentCount = 0
	}

	// Valider la transaction
	if err = tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur validation transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Véhicule transféré avec succès",
		"newOwnerEmail": req.NewOwnerEmail,
		"documentsTransferred": documentCount,
		"appointmentsTransferred": appointmentCount,
	})
}
