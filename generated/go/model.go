package main

import "database/sql"
import "github.com/google/uuid"

type SelectPostsWithUserEmailResult struct {
	Text      *string `json:"text"`
	UserEmail string  `json:"userEmail"`
}

func selectPostsWithUserEmail(database *sql.DB, email string) ([]SelectPostsWithUserEmailResult, error) {
	var results []SelectPostsWithUserEmailResult
	rows, err := database.Query("SELECT posts.text AS text, user.email AS userEmail FROM posts AS posts INNER JOIN users AS user ON user.id = posts.userID WHERE user.email = $1 LIMIT 10", email)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result SelectPostsWithUserEmailResult
		err = rows.Scan(&result.Text, &result.UserEmail)
		if err != nil {
			return results, err
		}
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type InsertAndGetPostResult struct {
	UserEmail string  `json:"userEmail"`
	Text      *string `json:"text"`
}

func insertAndGetPost(database *sql.DB, text string) ([]InsertAndGetPostResult, error) {
	var results []InsertAndGetPostResult
	rows, err := database.Query("WITH result AS (INSERT INTO posts AS posts (text) VALUES ($1) RETURNING posts.id AS id, posts.text AS text, posts.userID AS userID) SELECT user.email AS userEmail, result.text AS text FROM result AS result INNER JOIN users AS user ON user.id = result.userID", text)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result InsertAndGetPostResult
		err = rows.Scan(&result.UserEmail, &result.Text)
		if err != nil {
			return results, err
		}
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type UpdateUserEmailResult struct {
	Id         uuid.UUID  `json:"id"`
	Email      string     `json:"email"`
	Token      *string    `json:"token"`
	LastPostID *uuid.UUID `json:"lastPostID"`
}

func updateUserEmail(database *sql.DB, email string) ([]UpdateUserEmailResult, error) {
	var results []UpdateUserEmailResult
	rows, err := database.Query("UPDATE users AS users SET email = $1 RETURNING users.id AS id, users.email AS email, users.token AS token, users.lastPostID AS lastPostID", email)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result UpdateUserEmailResult
		err = rows.Scan(&result.Id, &result.Email, &result.Token, &result.LastPostID)
		if err != nil {
			return results, err
		}
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}
