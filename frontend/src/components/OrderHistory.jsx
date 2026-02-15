import React, { useState, useEffect } from 'react'
import { getOrders } from '../services/api'

function OrderHistory({ user }) {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadOrders()
  }, [])

  const loadOrders = async () => {
    try {
      const data = await getOrders(user.id)
      setOrders(data)
    } catch (err) {
      setError('Erreur lors du chargement des commandes')
    }
    setLoading(false)
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getStatusClass = (status) => {
    const statusMap = {
      'pending': 'pending',
      'processing': 'processing',
      'shipped': 'shipped',
      'delivered': 'delivered'
    }
    return statusMap[status] || 'pending'
  }

  const getStatusText = (status) => {
    const statusMap = {
      'pending': 'En attente',
      'processing': 'En préparation',
      'shipped': 'Expédiée',
      'delivered': 'Livrée'
    }
    return statusMap[status] || status
  }

  if (loading) {
    return <div className="loading">Chargement des commandes...</div>
  }

  if (error) {
    return <div className="error">{error}</div>
  }

  if (orders.length === 0) {
    return (
      <div className="empty-state">
        <div className="icon">📋</div>
        <h3>Aucune commande</h3>
        <p>Vous n'avez pas encore passé de commande</p>
      </div>
    )
  }

  return (
    <div className="orders-container">
      <h2>Mes Commandes</h2>
      
      {orders.map(order => (
        <div key={order.id} className="order-card card">
          <div className="order-header">
            <div>
              <strong>Commande #{order.id}</strong>
              <p style={{ fontSize: '14px', color: '#666' }}>
                {formatDate(order.created_at)}
              </p>
            </div>
            <span className={`order-status ${getStatusClass(order.status)}`}>
              {getStatusText(order.status)}
            </span>
          </div>
          
          <div className="order-items">
            {order.items?.map((item, index) => (
              <div key={index} className="order-item">
                <span>Produit #{item.product_id} x{item.quantity}</span>
                <span>{(item.price * item.quantity).toFixed(2)} €</span>
              </div>
            ))}
          </div>
          
          <div style={{ marginTop: '15px', paddingTop: '15px', borderTop: '1px solid #eee' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Adresse de livraison:</span>
              <span style={{ color: '#666' }}>{order.shipping_address}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '10px' }}>
              <strong>Total:</strong>
              <strong style={{ color: '#667eea' }}>{order.total_amount?.toFixed(2)} €</strong>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}

export default OrderHistory
