package models

import (
	"time"
)

type Vehicle struct {
	ID                   int        `json:"id"`
	UserID               int        `json:"user_id"`
	Plate                string     `json:"plate"`
	Model                string     `json:"model"`
	Brand                string     `json:"brand"`
	Year                 *int       `json:"year"`
	Mileage              *int       `json:"mileage"`
	TechnicalControlDate *time.Time `json:"technicalControlDate"`
	ImageURL             *string    `json:"imageUrl"`
	BrandImageURL        *string    `json:"brandImageUrl"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}

type VehicleRequest struct {
	Plate                string     `json:"plate" binding:"required"`
	Model                string     `json:"model" binding:"required"`
	Brand                string     `json:"brand" binding:"required"`
	Year                 *int       `json:"year"`
	Mileage              *int       `json:"mileage"`
	TechnicalControlDate *time.Time `json:"technical_control_date"`
	ImageURL             *string    `json:"image_url"`
	BrandImageURL        *string    `json:"brand_image_url"`
}

type RegisterWithVehicleRequest struct {
	Email                string  `json:"email" binding:"required,email"`
	Password             string  `json:"password" binding:"required,min=6"`
	FullName             string  `json:"fullName"`
	Plate                string  `json:"plate" binding:"required"`
	Model                string  `json:"model" binding:"required"`
	Brand                string  `json:"brand" binding:"required"`
	Year                 *int    `json:"year"`
	Mileage              *int    `json:"mileage"`
	TechnicalControlDate *string `json:"technicalControlDate"`
	ImageURL             *string `json:"imageUrl"`
	BrandImageURL        *string `json:"brandImageUrl"`
}

type VehicleResponse struct {
	ID                   int        `json:"id"`
	Plate                string     `json:"plate"`
	Model                string     `json:"model"`
	Brand                string     `json:"brand"`
	Year                 *int       `json:"year"`
	Mileage              *int       `json:"mileage"`
	TechnicalControlDate *time.Time `json:"technicalControlDate"`
	ImageURL             *string    `json:"imageUrl"`
	BrandImageURL        *string    `json:"brandImageUrl"`
}

type TransferVehicleRequest struct {
	NewOwnerEmail string `json:"newOwnerEmail" binding:"required,email"`
}