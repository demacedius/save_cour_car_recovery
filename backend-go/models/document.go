package models

import (
	"time"
)

type Document struct {
	ID          int       `json:"id"`
	VehicleID   int       `json:"vehicle_id"`
	UserID      int       `json:"user_id"`
	Name        string    `json:"name"`
	Type        string    `json:"type"` // "carte_grise", "assurance", "controle_technique", "facture", "autre"
	Description *string   `json:"description"`
	FilePath    string    `json:"file_path"`
	FileName    string    `json:"file_name"`
	FileSize    int64     `json:"file_size"`
	MimeType    string    `json:"mime_type"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type DocumentRequest struct {
	VehicleID   int     `form:"vehicle_id" binding:"required"`
	Name        string  `form:"name" binding:"required"`
	Type        string  `form:"type" binding:"required"`
	Description *string `form:"description"`
}

type DocumentResponse struct {
	ID          int       `json:"id"`
	VehicleID   int       `json:"vehicle_id"`
	Name        string    `json:"name"`
	Type        string    `json:"type"`
	Description *string   `json:"description"`
	FileName    string    `json:"file_name"`
	FileSize    int64     `json:"file_size"`
	DownloadURL string    `json:"download_url"`
	CreatedAt   time.Time `json:"created_at"`
}