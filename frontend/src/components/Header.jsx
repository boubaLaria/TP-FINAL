import React from 'react'

function Header({ user, cartCount, onViewChange, onLogout, onSearch, searchQuery }) {
  return (
    <header className="header">
      <div className="container">
        <div className="logo" onClick={() => onViewChange('products')}>
          Cloud<span>Shop</span>
        </div>
        
        <div className="search-bar">
          <input
            type="text"
            placeholder="Rechercher des produits..."
            value={searchQuery}
            onChange={(e) => onSearch(e.target.value)}
          />
        </div>
        
        <div className="nav-actions">
          <button className="cart-btn" onClick={() => onViewChange('cart')}>
            🛒 Panier
            {cartCount > 0 && <span className="count">{cartCount}</span>}
          </button>
          
          {user ? (
            <div className="user-menu">
              <span>👤 {user.username}</span>
              <button className="btn-primary" onClick={() => onViewChange('orders')}>
                Mes commandes
              </button>
              <button className="btn-danger" onClick={onLogout}>
                Déconnexion
              </button>
            </div>
          ) : (
            <button className="btn-primary" onClick={() => onViewChange('login')}>
              Connexion
            </button>
          )}
        </div>
      </div>
    </header>
  )
}

export default Header
