package models

import (
	"time"
)

type Appointment struct {
	ID          int       `json:"id"`
	UserID      int       `json:"user_id"`
	VehicleID   *int      `json:"vehicle_id,omitempty"`
	GarageName  string    `json:"garage_name"`
	GarageID    *string   `json:"garage_id,omitempty"`
	Date        time.Time `json:"date"`
	Time        string    `json:"time"`
	Service     string    `json:"service"`
	Description string    `json:"description"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type CreateAppointmentRequest struct {
	VehicleID   *int   `json:"vehicle_id"`
	GarageName  string `json:"garage_name" binding:"required"`
	GarageID    string `json:"garage_id"`
	Date        string `json:"date" binding:"required"`
	Time        string `json:"time" binding:"required"`
	Service     string `json:"service" binding:"required"`
	Description string `json:"description"`
}

type UpdateAppointmentRequest struct {
	Date        string `json:"date"`
	Time        string `json:"time"`
	Service     string `json:"service"`
	Description string `json:"description"`
	Status      string `json:"status"`
}

type AppointmentResponse struct {
	ID          int                `json:"id"`
	VehicleID   *int               `json:"vehicle_id,omitempty"`
	Vehicle     *VehicleResponse   `json:"vehicle,omitempty"`
	GarageName  string             `json:"garage_name"`
	GarageID    *string            `json:"garage_id,omitempty"`
	Date        time.Time          `json:"date"`
	Time        string             `json:"time"`
	Service     string             `json:"service"`
	Description string             `json:"description"`
	Status      string             `json:"status"`
	CreatedAt   time.Time          `json:"created_at"`
}

// Status possibles pour les rendez-vous
const (
	AppointmentStatusPending   = "pending"   // En attente de validation
	AppointmentStatusValidated = "validated" // Validé par le garage
	AppointmentStatusConfirmed = "confirmed" // Confirmé (rdv fixé)
	AppointmentStatusCompleted = "completed" // Terminé
	AppointmentStatusCancelled = "cancelled" // Annulé
	AppointmentStatusRejected  = "rejected"  // Refusé par le garage
)

// GetStatusDisplayName retourne le nom d'affichage d'un statut
func GetStatusDisplayName(status string) string {
	switch status {
	case AppointmentStatusPending:
		return "En attente"
	case AppointmentStatusValidated:
		return "Validé"
	case AppointmentStatusConfirmed:
		return "Confirmé"
	case AppointmentStatusCompleted:
		return "Terminé"
	case AppointmentStatusCancelled:
		return "Annulé"
	case AppointmentStatusRejected:
		return "Refusé"
	default:
		return "Inconnu"
	}
}

// IsValidStatus vérifie si un statut est valide
func IsValidStatus(status string) bool {
	switch status {
	case AppointmentStatusPending, AppointmentStatusValidated, AppointmentStatusConfirmed,
		 AppointmentStatusCompleted, AppointmentStatusCancelled, AppointmentStatusRejected:
		return true
	default:
		return false
	}
}