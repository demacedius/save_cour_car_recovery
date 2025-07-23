package models

import (
	"time"
)

type User struct {
	ID             int       `json:"id"`
	Email          string    `json:"email"`
	Password       string    `json:"-"`
	FullName       string    `json:"full_name"`
	FirstName      *string   `json:"first_name"`
	LastName       *string   `json:"last_name"`
	Phone          *string   `json:"phone"`
	ProfilePicture *string   `json:"profile_picture"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type UserRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	FullName string `json:"full_name"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type UserResponse struct {
	ID             int     `json:"id"`
	Email          string  `json:"email"`
	FullName       string  `json:"full_name"`
	FirstName      *string `json:"first_name"`
	LastName       *string `json:"last_name"`
	Phone          *string `json:"phone"`
	ProfilePicture *string `json:"profile_picture"`
}

type UpdateProfileRequest struct {
	FirstName *string `json:"first_name"`
	LastName  *string `json:"last_name"`
	Email     string  `json:"email" binding:"required,email"`
	Phone     *string `json:"phone"`
}

type UpdatePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=6"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"newPassword" binding:"required,min=6"`
}