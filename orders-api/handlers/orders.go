package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"cloudshop/orders-api/database"
	"cloudshop/orders-api/models"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

func GetOrders(w http.ResponseWriter, r *http.Request) {
	rows, err := database.DB.Query(`
		SELECT id, user_id, status, total_amount, shipping_address, created_at, updated_at
		FROM orders
		ORDER BY created_at DESC
		LIMIT 100
	`)
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to fetch orders")
		return
	}
	defer rows.Close()

	orders := []models.Order{}
	for rows.Next() {
		var order models.Order
		err := rows.Scan(
			&order.ID, &order.UserID, &order.Status, &order.TotalAmount,
			&order.ShippingAddress, &order.CreatedAt, &order.UpdatedAt,
		)
		if err != nil {
			continue
		}
		order.Items = getOrderItems(order.ID)
		orders = append(orders, order)
	}

	sendJSON(w, http.StatusOK, orders)
}

func GetOrder(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	orderID := vars["id"]

	var order models.Order
	err := database.DB.QueryRow(`
		SELECT id, user_id, status, total_amount, shipping_address, created_at, updated_at
		FROM orders WHERE id = $1
	`, orderID).Scan(
		&order.ID, &order.UserID, &order.Status, &order.TotalAmount,
		&order.ShippingAddress, &order.CreatedAt, &order.UpdatedAt,
	)

	if err != nil {
		sendError(w, http.StatusNotFound, "Order not found")
		return
	}

	order.Items = getOrderItems(order.ID)
	sendJSON(w, http.StatusOK, order)
}

func GetUserOrders(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["userId"]

	rows, err := database.DB.Query(`
		SELECT id, user_id, status, total_amount, shipping_address, created_at, updated_at
		FROM orders
		WHERE user_id = $1
		ORDER BY created_at DESC
	`, userID)
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to fetch orders")
		return
	}
	defer rows.Close()

	orders := []models.Order{}
	for rows.Next() {
		var order models.Order
		err := rows.Scan(
			&order.ID, &order.UserID, &order.Status, &order.TotalAmount,
			&order.ShippingAddress, &order.CreatedAt, &order.UpdatedAt,
		)
		if err != nil {
			continue
		}
		order.Items = getOrderItems(order.ID)
		orders = append(orders, order)
	}

	sendJSON(w, http.StatusOK, orders)
}

func CreateOrder(w http.ResponseWriter, r *http.Request) {
	var req models.CreateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate request
	if req.UserID == "" || len(req.Items) == 0 || req.ShippingAddress == "" {
		sendError(w, http.StatusBadRequest, "Missing required fields")
		return
	}

	// Generate order ID
	orderID := uuid.New().String()
	now := time.Now()

	// Start transaction
	tx, err := database.DB.Begin()
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to start transaction")
		return
	}
	defer tx.Rollback()

	// Insert order
	_, err = tx.Exec(`
		INSERT INTO orders (id, user_id, status, total_amount, shipping_address, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`, orderID, req.UserID, models.StatusPending, req.TotalAmount, req.ShippingAddress, now, now)

	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to create order")
		return
	}

	// Insert order items
	for _, item := range req.Items {
		itemID := uuid.New().String()
		_, err = tx.Exec(`
			INSERT INTO order_items (id, order_id, product_id, quantity, price, created_at)
			VALUES ($1, $2, $3, $4, $5, $6)
		`, itemID, orderID, item.ProductID, item.Quantity, item.Price, now)

		if err != nil {
			sendError(w, http.StatusInternalServerError, "Failed to create order items")
			return
		}
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to commit transaction")
		return
	}

	// Fetch created order
	order := models.Order{
		ID:              orderID,
		UserID:          req.UserID,
		Status:          models.StatusPending,
		TotalAmount:     req.TotalAmount,
		ShippingAddress: req.ShippingAddress,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	order.Items = getOrderItems(orderID)

	sendJSON(w, http.StatusCreated, order)
}

func UpdateOrderStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	orderID := vars["id"]

	var req models.UpdateStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate status
	validStatuses := map[string]bool{
		"pending":    true,
		"processing": true,
		"shipped":    true,
		"delivered":  true,
		"cancelled":  true,
	}
	if !validStatuses[req.Status] {
		sendError(w, http.StatusBadRequest, "Invalid status")
		return
	}

	// Update order
	result, err := database.DB.Exec(`
		UPDATE orders SET status = $1, updated_at = $2 WHERE id = $3
	`, req.Status, time.Now(), orderID)

	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to update order")
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		sendError(w, http.StatusNotFound, "Order not found")
		return
	}

	// Fetch updated order
	var order models.Order
	database.DB.QueryRow(`
		SELECT id, user_id, status, total_amount, shipping_address, created_at, updated_at
		FROM orders WHERE id = $1
	`, orderID).Scan(
		&order.ID, &order.UserID, &order.Status, &order.TotalAmount,
		&order.ShippingAddress, &order.CreatedAt, &order.UpdatedAt,
	)

	order.Items = getOrderItems(orderID)
	sendJSON(w, http.StatusOK, order)
}

func getOrderItems(orderID string) []models.OrderItem {
	rows, err := database.DB.Query(`
		SELECT id, order_id, product_id, quantity, price, created_at
		FROM order_items WHERE order_id = $1
	`, orderID)
	if err != nil {
		return []models.OrderItem{}
	}
	defer rows.Close()

	items := []models.OrderItem{}
	for rows.Next() {
		var item models.OrderItem
		err := rows.Scan(&item.ID, &item.OrderID, &item.ProductID, &item.Quantity, &item.Price, &item.CreatedAt)
		if err != nil {
			continue
		}
		items = append(items, item)
	}
	return items
}

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func sendError(w http.ResponseWriter, status int, message string) {
	sendJSON(w, status, models.ErrorResponse{Error: message})
}
