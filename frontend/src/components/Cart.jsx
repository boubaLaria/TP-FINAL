import React from 'react'

function Cart({ items, onUpdateQuantity, onRemove, onCheckout }) {
  if (items.length === 0) {
    return (
      <div className="empty-state">
        <div className="icon">🛒</div>
        <h3>Votre panier est vide</h3>
        <p>Ajoutez des produits pour commencer</p>
      </div>
    )
  }

  const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0)

  return (
    <div className="cart-container">
      <h2>Votre Panier</h2>
      
      <div className="cart-items">
        {items.map(item => (
          <div key={item.id} className="cart-item">
            <div className="cart-item-image">📦</div>
            <div className="cart-item-details">
              <h4>{item.name}</h4>
              <p className="price">{item.price.toFixed(2)} €</p>
            </div>
            <div className="quantity-controls">
              <button onClick={() => onUpdateQuantity(item.id, item.quantity - 1)}>
                -
              </button>
              <span>{item.quantity}</span>
              <button onClick={() => onUpdateQuantity(item.id, item.quantity + 1)}>
                +
              </button>
            </div>
            <div className="item-total">
              <strong>{(item.price * item.quantity).toFixed(2)} €</strong>
            </div>
            <button className="btn-danger" onClick={() => onRemove(item.id)}>
              🗑️
            </button>
          </div>
        ))}
      </div>
      
      <div className="cart-summary">
        <h3>Résumé</h3>
        <div className="cart-total">
          <span>Total</span>
          <span className="amount">{total.toFixed(2)} €</span>
        </div>
        <button className="btn-success" onClick={onCheckout} style={{ width: '100%' }}>
          Passer la commande
        </button>
      </div>
    </div>
  )
}

export default Cart
