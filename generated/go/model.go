package main

import "database/sql"
import "github.com/google/uuid"

type SelectPostsWithUserEmailResult struct {
    text *string
	userEmail string
}
type InsertAndGetPostResult struct {
    userEmail string
	text *string
}
type UpdateUserEmailResult struct {
    id uuid.UUID
	email string
	token *string
	lastPostID *uuid.UUID
}
