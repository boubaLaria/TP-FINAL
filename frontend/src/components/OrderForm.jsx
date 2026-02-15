import React, { useState } from 'react'
import { createOrder } from '../services/api'

function OrderForm({ cart, user, onOrderComplete, onCancel }) {
  const [formData, setFormData] = useState({
    shippingAddress: '',
    city: '',
    postalCode: '',
    country: 'France'
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const orderData = {
        user_id: user.id,
        items: cart.map(item => ({
          product_id: item.id,
          quantity: item.quantity,
          price: item.price
        })),
        shipping_address: `${formData.shippingAddress}, ${formData.postalCode} ${formData.city}, ${formData.country}`,
        total_amount: total
      }

      await createOrder(orderData)
      onOrderComplete()
    } catch (err) {
      setError(err.message || 'Erreur lors de la création de la commande')
    }
    setLoading(false)
  }

  return (
    <div className="checkout-container">
      <div className="checkout-form">
        <h2>Finaliser la commande</h2>

        <div className="order-summary">
          <h4>Récapitulatif</h4>
          <div className="order-items">
            {cart.map(item => (
              <div key={item.id} className="order-item">
                <span>{item.name} x{item.quantity}</span>
                <span>{(item.price * item.quantity).toFixed(2)} €</span>
              </div>
            ))}
          </div>
          <div className="order-item" style={{ fontWeight: 'bold', borderTop: '2px solid #333', marginTop: '10px', paddingTop: '10px' }}>
            <span>Total</span>
            <span>{total.toFixed(2)} €</span>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Adresse de livraison</label>
            <input
              type="text"
              name="shippingAddress"
              value={formData.shippingAddress}
              onChange={handleChange}
              placeholder="123 Rue Example"
              required
            />
          </div>

          <div className="form-group">
            <label>Ville</label>
            <input
              type="text"
              name="city"
              value={formData.city}
              onChange={handleChange}
              placeholder="Paris"
              required
            />
          </div>

          <div className="form-group">
            <label>Code Postal</label>
            <input
              type="text"
              name="postalCode"
              value={formData.postalCode}
              onChange={handleChange}
              placeholder="75001"
              required
            />
          </div>

          <div className="form-group">
            <label>Pays</label>
            <select name="country" value={formData.country} onChange={handleChange}>
              <option value="France">France</option>
              <option value="Belgium">Belgique</option>
              <option value="Switzerland">Suisse</option>
              <option value="Canada">Canada</option>
            </select>
          </div>

          {error && <div className="error">{error}</div>}

          <div className="form-actions">
            <button type="button" className="btn-danger" onClick={onCancel}>
              Annuler
            </button>
            <button type="submit" className="btn-success" disabled={loading}>
              {loading ? 'Traitement...' : 'Confirmer la commande'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default OrderForm
