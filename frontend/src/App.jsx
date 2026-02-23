import React, { useState, useEffect } from 'react'
import Header from './components/Header'
import Footer from './components/Footer'
import ProductList from './components/ProductList'
import Cart from './components/Cart'
import OrderForm from './components/OrderForm'
import Login from './components/Login'
import Register from './components/Register'
import OrderHistory from './components/OrderHistory'
import { getProducts, searchProducts } from './services/api'
import './App.css'

function App() {
  const [user, setUser] = useState(null)
  const [products, setProducts] = useState([])
  const [cart, setCart] = useState([])
  const [view, setView] = useState('products') // products, cart, checkout, login, register, orders
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    // Check for stored token
    const token = localStorage.getItem('accessToken')
    const storedUser = localStorage.getItem('user')
    if (token && storedUser) {
      setUser(JSON.parse(storedUser))
    }
    
    // Load products
    loadProducts()
  }, [])

  const loadProducts = async () => {
    setLoading(true)
    try {
      const data = await getProducts()
      setProducts(data)
    } catch (error) {
      console.error('Failed to load products:', error)
    }
    setLoading(false)
  }

  const handleSearch = async (query) => {
    setSearchQuery(query)
    setLoading(true)
    try {
      if (query.trim()) {
        const data = await searchProducts(query)
        setProducts(data)
      } else {
        await loadProducts()
      }
    } catch (error) {
      console.error('Search failed:', error)
    }
    setLoading(false)
  }

  const addToCart = (product) => {
    setCart(prevCart => {
      const existing = prevCart.find(item => item.id === product.id)
      if (existing) {
        return prevCart.map(item =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        )
      }
      return [...prevCart, { ...product, quantity: 1 }]
    })
  }

  const removeFromCart = (productId) => {
    setCart(prevCart => prevCart.filter(item => item.id !== productId))
  }

  const updateQuantity = (productId, quantity) => {
    if (quantity <= 0) {
      removeFromCart(productId)
      return
    }
    setCart(prevCart =>
      prevCart.map(item =>
        item.id === productId ? { ...item, quantity } : item
      )
    )
  }

  const clearCart = () => {
    setCart([])
  }

  const handleLogin = (userData, tokens) => {
    setUser(userData)
    localStorage.setItem('accessToken', tokens.accessToken)
    localStorage.setItem('refreshToken', tokens.refreshToken)
    localStorage.setItem('user', JSON.stringify(userData))
    setView('products')
  }

  const handleLogout = () => {
    setUser(null)
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('user')
    setView('products')
  }

  const handleOrderComplete = () => {
    clearCart()
    setView('orders')
  }

  return (
    <div className="app">
      <Header
        user={user}
        cartCount={cart.reduce((sum, item) => sum + item.quantity, 0)}
        onViewChange={setView}
        onLogout={handleLogout}
        onSearch={handleSearch}
        searchQuery={searchQuery}
      />
      
      <main className="container">
        {view === 'login' && (
          <Login
            onLogin={handleLogin}
            onSwitchToRegister={() => setView('register')}
          />
        )}
        
        {view === 'register' && (
          <Register
            onRegister={handleLogin}
            onSwitchToLogin={() => setView('login')}
          />
        )}
        
        {view === 'products' && (
          <ProductList
            products={products}
            loading={loading}
            onAddToCart={addToCart}
          />
        )}
        
        {view === 'cart' && (
          <Cart
            items={cart}
            onUpdateQuantity={updateQuantity}
            onRemove={removeFromCart}
            onCheckout={() => user ? setView('checkout') : setView('login')}
          />
        )}
        
        {view === 'checkout' && (
          <OrderForm
            cart={cart}
            user={user}
            onOrderComplete={handleOrderComplete}
            onCancel={() => setView('cart')}
          />
        )}

        {view === 'orders' && (
          <OrderHistory user={user} />
        )}
      </main>
      
      <Footer />
    </div>
  )
}

export default App
