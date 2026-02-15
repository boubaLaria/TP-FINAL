import React from 'react'

function ProductList({ products, loading, onAddToCart }) {
  if (loading) {
    return <div className="loading">Chargement des produits...</div>
  }

  if (products.length === 0) {
    return (
      <div className="empty-state">
        <div className="icon">📦</div>
        <h3>Aucun produit trouvé</h3>
        <p>Essayez une autre recherche</p>
      </div>
    )
  }

  const getStockStatus = (stock) => {
    if (stock === 0) return { text: 'Rupture de stock', class: 'out' }
    if (stock < 10) return { text: `Plus que ${stock} en stock`, class: 'low' }
    return { text: 'En stock', class: '' }
  }

  const getCategoryEmoji = (category) => {
    const emojis = {
      'electronics': '💻',
      'clothing': '👕',
      'books': '📚',
      'home': '🏠',
      'sports': '⚽',
      'food': '🍎',
      'default': '📦'
    }
    return emojis[category?.toLowerCase()] || emojis.default
  }

  return (
    <div className="product-grid">
      {products.map(product => {
        const stockStatus = getStockStatus(product.stock)
        return (
          <div key={product.id} className="product-card">
            <div className="product-image">
              {getCategoryEmoji(product.category)}
            </div>
            <div className="product-info">
              <h3>{product.name}</h3>
              <p>{product.description}</p>
              <div className={`product-stock ${stockStatus.class}`}>
                {stockStatus.text}
              </div>
              <div className="product-price">{product.price.toFixed(2)} €</div>
              <button
                className="btn-primary"
                onClick={() => onAddToCart(product)}
                disabled={product.stock === 0}
              >
                {product.stock === 0 ? 'Indisponible' : 'Ajouter au panier'}
              </button>
            </div>
          </div>
        )
      })}
    </div>
  )
}

export default ProductList
