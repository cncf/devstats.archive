package gha2db

import (
	"time"
)

// Event - full GHA (GitHub Archive) event structure
type Event struct {
	ID        string    `json:"id"`
	Type      string    `json:"type"`
	Public    bool      `json:"public"`
	CreatedAt time.Time `json:"created_at"`
	Actor     Actor     `json:"actor"`
	Repo      Repo      `json:"repo"`
	Org       *Org      `json:"org"`
}

// Repo - GHA Repo structure
type Repo struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

// Actor - GHA Actor structure
type Actor struct {
	ID    int    `json:"id"`
	Login string `json:"login"`
}

// Org - GHA Org structure
type Org struct {
	ID    int    `json:"id"`
	Login string `json:"login"`
}
