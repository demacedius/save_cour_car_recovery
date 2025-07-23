package handlers

import (
	"backend-go/database"
	"backend-go/models"
	"database/sql"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// CreateAppointment crée un nouveau rendez-vous
func CreateAppointment(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	var req models.CreateAppointmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Parser la date
	appointmentDate, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Format de date invalide (YYYY-MM-DD requis)"})
		return
	}

	// Vérifier que la date n'est pas dans le passé
	if appointmentDate.Before(time.Now().Truncate(24 * time.Hour)) {
		c.JSON(http.StatusBadRequest, gin.H{"message": "La date du rendez-vous doit être dans le futur"})
		return
	}

	var appointmentID int
	err = database.DB.QueryRow(`
		INSERT INTO appointments (user_id, vehicle_id, garage_name, garage_id, date, time, service, description, status) 
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
		RETURNING id`,
		userID, req.VehicleID, req.GarageName, req.GarageID, appointmentDate, req.Time, req.Service, req.Description, models.AppointmentStatusPending,
	).Scan(&appointmentID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur création rendez-vous", "error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Rendez-vous créé avec succès",
		"appointment_id": appointmentID,
	})
}

// GetUserAppointments récupère tous les rendez-vous d'un utilisateur
func GetUserAppointments(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	rows, err := database.DB.Query(`
		SELECT a.id, a.vehicle_id, a.garage_name, a.garage_id, a.date, a.time, 
		       a.service, a.description, a.status, a.created_at,
		       v.id, v.plate, v.model, v.brand, v.year, v.mileage, v.technical_control_date, v.image_url, v.brand_image_url
		FROM appointments a
		LEFT JOIN vehicles v ON a.vehicle_id = v.id
		WHERE a.user_id = $1
		ORDER BY a.date ASC, a.time ASC`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération rendez-vous"})
		return
	}
	defer rows.Close()

	var appointments []models.AppointmentResponse
	for rows.Next() {
		var appointment models.AppointmentResponse
		var vehicle models.VehicleResponse
		var vehicleID sql.NullInt64
		var vehiclePlate, vehicleModel, vehicleBrand sql.NullString
		var vehicleYear, vehicleMileage sql.NullInt64
		var vehicleTechnicalControl sql.NullTime
		var vehicleImageURL, vehicleBrandImageURL sql.NullString

		err := rows.Scan(
			&appointment.ID, &vehicleID, &appointment.GarageName, &appointment.GarageID,
			&appointment.Date, &appointment.Time, &appointment.Service, &appointment.Description,
			&appointment.Status, &appointment.CreatedAt,
			&vehicleID, &vehiclePlate, &vehicleModel, &vehicleBrand, &vehicleYear,
			&vehicleMileage, &vehicleTechnicalControl, &vehicleImageURL, &vehicleBrandImageURL,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lecture rendez-vous"})
			return
		}

		// Si un véhicule est associé, l'ajouter
		if vehicleID.Valid {
			appointment.VehicleID = new(int)
			*appointment.VehicleID = int(vehicleID.Int64)
			
			vehicle.ID = int(vehicleID.Int64)
			if vehiclePlate.Valid {
				vehicle.Plate = vehiclePlate.String
			}
			if vehicleModel.Valid {
				vehicle.Model = vehicleModel.String
			}
			if vehicleBrand.Valid {
				vehicle.Brand = vehicleBrand.String
			}
			if vehicleYear.Valid {
				vehicle.Year = new(int)
				*vehicle.Year = int(vehicleYear.Int64)
			}
			if vehicleMileage.Valid {
				vehicle.Mileage = new(int)
				*vehicle.Mileage = int(vehicleMileage.Int64)
			}
			if vehicleTechnicalControl.Valid {
				vehicle.TechnicalControlDate = &vehicleTechnicalControl.Time
			}
			if vehicleImageURL.Valid {
				vehicle.ImageURL = &vehicleImageURL.String
			}
			if vehicleBrandImageURL.Valid {
				vehicle.BrandImageURL = &vehicleBrandImageURL.String
			}
			appointment.Vehicle = &vehicle
		}

		appointments = append(appointments, appointment)
	}

	c.JSON(http.StatusOK, gin.H{
		"appointments": appointments,
	})
}

// GetAppointment récupère un rendez-vous spécifique
func GetAppointment(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	appointmentID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID de rendez-vous invalide"})
		return
	}

	var appointment models.AppointmentResponse
	var vehicle models.VehicleResponse
	var vehicleID sql.NullInt64
	var vehiclePlate, vehicleModel, vehicleBrand sql.NullString
	var vehicleYear, vehicleMileage sql.NullInt64
	var vehicleTechnicalControl sql.NullTime
	var vehicleImageURL, vehicleBrandImageURL sql.NullString

	err = database.DB.QueryRow(`
		SELECT a.id, a.vehicle_id, a.garage_name, a.garage_id, a.date, a.time, 
		       a.service, a.description, a.status, a.created_at,
		       v.id, v.plate, v.model, v.brand, v.year, v.mileage, v.technical_control_date, v.image_url, v.brand_image_url
		FROM appointments a
		LEFT JOIN vehicles v ON a.vehicle_id = v.id
		WHERE a.id = $1 AND a.user_id = $2`,
		appointmentID, userID,
	).Scan(
		&appointment.ID, &vehicleID, &appointment.GarageName, &appointment.GarageID,
		&appointment.Date, &appointment.Time, &appointment.Service, &appointment.Description,
		&appointment.Status, &appointment.CreatedAt,
		&vehicleID, &vehiclePlate, &vehicleModel, &vehicleBrand, &vehicleYear,
		&vehicleMileage, &vehicleTechnicalControl, &vehicleImageURL, &vehicleBrandImageURL,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "Rendez-vous non trouvé"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur récupération rendez-vous"})
		return
	}

	// Si un véhicule est associé, l'ajouter
	if vehicleID.Valid {
		appointment.VehicleID = new(int)
		*appointment.VehicleID = int(vehicleID.Int64)
		
		vehicle.ID = int(vehicleID.Int64)
		if vehiclePlate.Valid {
			vehicle.Plate = vehiclePlate.String
		}
		if vehicleModel.Valid {
			vehicle.Model = vehicleModel.String
		}
		if vehicleBrand.Valid {
			vehicle.Brand = vehicleBrand.String
		}
		if vehicleYear.Valid {
			vehicle.Year = new(int)
			*vehicle.Year = int(vehicleYear.Int64)
		}
		if vehicleMileage.Valid {
			vehicle.Mileage = new(int)
			*vehicle.Mileage = int(vehicleMileage.Int64)
		}
		if vehicleTechnicalControl.Valid {
			vehicle.TechnicalControlDate = &vehicleTechnicalControl.Time
		}
		if vehicleImageURL.Valid {
			vehicle.ImageURL = &vehicleImageURL.String
		}
		if vehicleBrandImageURL.Valid {
			vehicle.BrandImageURL = &vehicleBrandImageURL.String
		}
		appointment.Vehicle = &vehicle
	}

	c.JSON(http.StatusOK, gin.H{
		"appointment": appointment,
	})
}

// UpdateAppointment met à jour un rendez-vous
func UpdateAppointment(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	appointmentID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID de rendez-vous invalide"})
		return
	}

	var req models.UpdateAppointmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	// Construire la requête de mise à jour dynamiquement
	updateFields := []string{}
	updateValues := []interface{}{}
	paramCount := 1

	if req.Date != "" {
		appointmentDate, err := time.Parse("2006-01-02", req.Date)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Format de date invalide"})
			return
		}
		if appointmentDate.Before(time.Now().Truncate(24 * time.Hour)) {
			c.JSON(http.StatusBadRequest, gin.H{"message": "La date doit être dans le futur"})
			return
		}
		updateFields = append(updateFields, "date = $"+strconv.Itoa(paramCount))
		updateValues = append(updateValues, appointmentDate)
		paramCount++
	}

	if req.Time != "" {
		updateFields = append(updateFields, "time = $"+strconv.Itoa(paramCount))
		updateValues = append(updateValues, req.Time)
		paramCount++
	}

	if req.Service != "" {
		updateFields = append(updateFields, "service = $"+strconv.Itoa(paramCount))
		updateValues = append(updateValues, req.Service)
		paramCount++
	}

	if req.Description != "" {
		updateFields = append(updateFields, "description = $"+strconv.Itoa(paramCount))
		updateValues = append(updateValues, req.Description)
		paramCount++
	}

	if req.Status != "" {
		// Valider le statut
		if !models.IsValidStatus(req.Status) {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Statut invalide"})
			return
		}
		updateFields = append(updateFields, "status = $"+strconv.Itoa(paramCount))
		updateValues = append(updateValues, req.Status)
		paramCount++
	}

	if len(updateFields) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Aucun champ à mettre à jour"})
		return
	}

	// Ajouter updated_at
	updateFields = append(updateFields, "updated_at = CURRENT_TIMESTAMP")

	// Ajouter les paramètres WHERE
	updateValues = append(updateValues, appointmentID, userID)
	whereClause := " WHERE id = $" + strconv.Itoa(paramCount) + " AND user_id = $" + strconv.Itoa(paramCount+1)

	query := "UPDATE appointments SET " + updateFields[0]
	for i := 1; i < len(updateFields); i++ {
		query += ", " + updateFields[i]
	}
	query += whereClause

	result, err := database.DB.Exec(query, updateValues...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur mise à jour rendez-vous"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Rendez-vous non trouvé"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Rendez-vous mis à jour avec succès",
	})
}

// ValidateAppointment valide ou rejette un rendez-vous (pour les garages)
func ValidateAppointment(c *gin.Context) {
	appointmentID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID de rendez-vous invalide"})
		return
	}

	var req struct {
		Action string `json:"action" binding:"required"` // "validate" ou "reject"
		Reason string `json:"reason,omitempty"`          // Raison en cas de rejet
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Données invalides", "error": err.Error()})
		return
	}

	var newStatus string
	switch req.Action {
	case "validate":
		newStatus = models.AppointmentStatusValidated
	case "reject":
		newStatus = models.AppointmentStatusRejected
	default:
		c.JSON(http.StatusBadRequest, gin.H{"message": "Action invalide (validate ou reject requis)"})
		return
	}

	// Mettre à jour le statut
	query := "UPDATE appointments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2"
	result, err := database.DB.Exec(query, newStatus, appointmentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur lors de la validation", "error": err.Error()})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil || rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Rendez-vous non trouvé"})
		return
	}

	actionMsg := "validé"
	if req.Action == "reject" {
		actionMsg = "refusé"
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Rendez-vous " + actionMsg + " avec succès",
		"status":  newStatus,
	})
}

// DeleteAppointment supprime un rendez-vous
func DeleteAppointment(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Non autorisé"})
		return
	}

	appointmentID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "ID de rendez-vous invalide"})
		return
	}

	result, err := database.DB.Exec("DELETE FROM appointments WHERE id = $1 AND user_id = $2", appointmentID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Erreur suppression rendez-vous"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Rendez-vous non trouvé"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Rendez-vous supprimé avec succès",
	})
}