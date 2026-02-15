from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List, Optional
import os

from app.models.product import Product, ProductCreate, ProductUpdate
from app.database.elasticsearch_client import ElasticsearchClient

# Initialize Elasticsearch client
es_client = ElasticsearchClient()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await es_client.initialize()
    yield
    # Shutdown
    await es_client.close()

app = FastAPI(
    title="CloudShop Products API",
    description="Product management service with Elasticsearch",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "products-api",
        "elasticsearch": await es_client.health_check()
    }

@app.get("/products", response_model=List[Product])
async def get_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    category: Optional[str] = None
):
    """Get all products with optional filtering"""
    try:
        products = await es_client.get_products(skip=skip, limit=limit, category=category)
        return products
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/products/search", response_model=List[Product])
async def search_products(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=50)
):
    """Search products using Elasticsearch full-text search"""
    try:
        products = await es_client.search_products(query=q, limit=limit)
        return products
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: str):
    """Get a specific product by ID"""
    product = await es_client.get_product(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.post("/products", response_model=Product, status_code=201)
async def create_product(product: ProductCreate):
    """Create a new product"""
    try:
        created_product = await es_client.create_product(product)
        return created_product
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/products/{product_id}", response_model=Product)
async def update_product(product_id: str, product: ProductUpdate):
    """Update an existing product"""
    existing = await es_client.get_product(product_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Product not found")
    
    try:
        updated_product = await es_client.update_product(product_id, product)
        return updated_product
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/products/{product_id}", status_code=204)
async def delete_product(product_id: str):
    """Delete a product"""
    existing = await es_client.get_product(product_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Product not found")
    
    try:
        await es_client.delete_product(product_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8082)))
