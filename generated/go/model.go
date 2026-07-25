package main

import "database/sql"
import "github.com/google/uuid"
import "time"

type SelectPostsQueryResult struct {
	Text      *string `json:"text"`
	UserEmail string  `json:"userEmail"`
}

func SelectPostsQuery(database *sql.DB, email string) ([]SelectPostsQueryResult, error) {
	var results []SelectPostsQueryResult
	rows, err := database.Query("SELECT posts.text AS text, user.email AS userEmail FROM posts AS posts INNER JOIN users AS user ON user.id = posts.userID WHERE user.email = $1 ORDER BY posts.createdDate DESC LIMIT 10", email)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result SelectPostsQueryResult
		err = rows.Scan(&result.Text, &result.UserEmail)
		if err != nil {
			return results, err
		}
		results = append(results, result)
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type InsertGetPostWithEmailResult struct {
	UserEmail string  `json:"userEmail"`
	Text      *string `json:"text"`
}

func InsertGetPostWithEmail(database *sql.DB, text string) ([]InsertGetPostWithEmailResult, error) {
	var results []InsertGetPostWithEmailResult
	rows, err := database.Query("WITH result AS (INSERT INTO posts AS posts (text) VALUES ($1) RETURNING posts.id AS id, posts.text AS text, posts.userID AS userID, posts.createdDate AS createdDate) SELECT user.email AS userEmail, result.text AS text FROM result AS result INNER JOIN users AS user ON user.id = result.userID", text)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result InsertGetPostWithEmailResult
		err = rows.Scan(&result.UserEmail, &result.Text)
		if err != nil {
			return results, err
		}
		results = append(results, result)
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type UpdateEmailResult struct {
	Id         uuid.UUID  `json:"id"`
	Email      string     `json:"email"`
	Token      *string    `json:"token"`
	LastPostID *uuid.UUID `json:"lastPostID"`
}

func UpdateEmail(database *sql.DB, email string) ([]UpdateEmailResult, error) {
	var results []UpdateEmailResult
	rows, err := database.Query("UPDATE users AS users SET email = $1 RETURNING users.id AS id, users.email AS email, users.token AS token, users.lastPostID AS lastPostID", email)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result UpdateEmailResult
		err = rows.Scan(&result.Id, &result.Email, &result.Token, &result.LastPostID)
		if err != nil {
			return results, err
		}
		results = append(results, result)
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type DeletePostResult struct {
	Id          uuid.UUID `json:"id"`
	Text        *string   `json:"text"`
	UserID      uuid.UUID `json:"userID"`
	CreatedDate time.Time `json:"createdDate"`
}

func DeletePost(database *sql.DB, postID uuid.UUID) ([]DeletePostResult, error) {
	var results []DeletePostResult
	rows, err := database.Query("DELETE FROM posts AS posts WHERE posts.id = $1 RETURNING posts.id AS id, posts.text AS text, posts.userID AS userID, posts.createdDate AS createdDate", postID)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result DeletePostResult
		err = rows.Scan(&result.Id, &result.Text, &result.UserID, &result.CreatedDate)
		if err != nil {
			return results, err
		}
		results = append(results, result)
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}

type InsertedPayment struct {
	Id            uuid.UUID `json:"id"`
	Amount        float64   `json:"amount"`
	FromUserEmail string    `json:"fromUserEmail"`
	ToUserEmail   string    `json:"toUserEmail"`
}

func InsertPayment(database *sql.DB, fromUserID uuid.UUID, toUserID uuid.UUID, amount float64) ([]InsertedPayment, error) {
	var results []InsertedPayment
	rows, err := database.Query("WITH _Insert AS (INSERT INTO payments AS payments (fromUserID, toUserID, amount) VALUES ($1, $2, $3) RETURNING payments.id AS id, payments.fromUserID AS fromUserID, payments.toUserID AS toUserID, payments.amount AS amount) SELECT _Insert.id AS id, _Insert.amount AS amount, fromUser.email AS fromUserEmail, toUser.email AS toUserEmail FROM _Insert AS _Insert INNER JOIN users AS fromUser ON fromUser.id = _Insert.fromUserID INNER JOIN users AS toUser ON toUser.id = _Insert.toUserID", fromUserID, toUserID, amount)
	if err != nil {
		return results, err
	}

	defer rows.Close()

	for rows.Next() {
		var result InsertedPayment
		err = rows.Scan(&result.Id, &result.Amount, &result.FromUserEmail, &result.ToUserEmail)
		if err != nil {
			return results, err
		}
		results = append(results, result)
	}

	if err := rows.Err(); err != nil {
		return results, err
	}

	return results, nil
}
