package gha2db

// GHA - full GHA event structure
type GHA struct {
	Repo Repo `json:"repo"`
}

type Repo struct {
  Name string `json:"name"`
}
