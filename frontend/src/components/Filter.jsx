import React from 'react'
import '../styles/Filter.css'

function Filter({ products, onFilterChange }) {
  const [selectedCategory, setSelectedCategory] = React.useState('all')
  const [priceRange, setPriceRange] = React.useState([0, 10000])

  // Extract unique categories from products
  const categories = ['all', ...new Set(products.map(p => p.category).filter(Boolean))]

  const handleCategoryChange = (category) => {
    setSelectedCategory(category)
    onFilterChange({ category, priceRange })
  }

  const handlePriceChange = (e, type) => {
    const value = parseFloat(e.target.value)
    const newRange = type === 'min' ? [value, priceRange[1]] : [priceRange[0], value]
    setPriceRange(newRange)
    onFilterChange({ category: selectedCategory, priceRange: newRange })
  }

  const handleReset = () => {
    setSelectedCategory('all')
    setPriceRange([0, 10000])
    onFilterChange({ category: 'all', priceRange: [0, 10000] })
  }

  return (
    <div className="filter-container">
      <h3>Filtres</h3>
      
      <div className="filter-section">
        <h4>Catégorie</h4>
        <div className="category-list">
          {categories.map(category => (
            <label key={category} className="checkbox-label">
              <input
                type="radio"
                name="category"
                value={category}
                checked={selectedCategory === category}
                onChange={(e) => handleCategoryChange(e.target.value)}
              />
              <span className="capitalize">
                {category === 'all' ? 'Toutes les catégories' : category}
              </span>
            </label>
          ))}
        </div>
      </div>

      <div className="filter-section">
        <h4>Prix</h4>
        <div className="price-range">
          <div className="price-input">
            <label>Min: €</label>
            <input
              type="number"
              min="0"
              value={priceRange[0]}
              onChange={(e) => handlePriceChange(e, 'min')}
            />
          </div>
          <div className="price-input">
            <label>Max: €</label>
            <input
              type="number"
              min="0"
              value={priceRange[1]}
              onChange={(e) => handlePriceChange(e, 'max')}
            />
          </div>
        </div>
      </div>

      <button className="btn-reset" onClick={handleReset}>
        Réinitialiser les filtres
      </button>
    </div>
  )
}

export default Filter
