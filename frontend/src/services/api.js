const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'

// Helper function for API calls
async function apiCall(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`
  
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  }

  // Add auth token if available
  const token = localStorage.getItem('accessToken')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  const response = await fetch(url, config)

  // Handle token refresh
  if (response.status === 401) {
    const refreshed = await refreshToken()
    if (refreshed) {
      config.headers.Authorization = `Bearer ${localStorage.getItem('accessToken')}`
      const retryResponse = await fetch(url, config)
      if (!retryResponse.ok) {
        throw new Error('Request failed after token refresh')
      }
      return retryResponse.json()
    }
  }

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'An error occurred' }))
    throw new Error(error.message || `HTTP error! status: ${response.status}`)
  }

  return response.json()
}

// Token refresh
async function refreshToken() {
  const refreshTokenValue = localStorage.getItem('refreshToken')
  if (!refreshTokenValue) {
    return false
  }

  try {
    const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ refreshToken: refreshTokenValue })
    })

    if (response.ok) {
      const data = await response.json()
      localStorage.setItem('accessToken', data.accessToken)
      localStorage.setItem('refreshToken', data.refreshToken)
      return true
    }
  } catch (error) {
    console.error('Token refresh failed:', error)
  }

  // Clear tokens on refresh failure
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('user')
  return false
}

// Auth API
export async function login(email, password) {
  return apiCall('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password })
  })
}

export async function register(username, email, password) {
  return apiCall('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username, email, password })
  })
}

export async function verifyToken() {
  return apiCall('/auth/verify')
}

// Products API
export async function getProducts() {
  return apiCall('/products')
}

export async function getProduct(id) {
  return apiCall(`/products/${id}`)
}

export async function searchProducts(query) {
  return apiCall(`/products/search?q=${encodeURIComponent(query)}`)
}

// Orders API
export async function createOrder(orderData) {
  return apiCall('/orders', {
    method: 'POST',
    body: JSON.stringify(orderData)
  })
}

export async function getOrders(userId) {
  return apiCall(`/orders/user/${userId}`)
}

export async function getOrder(orderId) {
  return apiCall(`/orders/${orderId}`)
}

export async function updateOrderStatus(orderId, status) {
  return apiCall(`/orders/${orderId}/status`, {
    method: 'PUT',
    body: JSON.stringify({ status })
  })
}
