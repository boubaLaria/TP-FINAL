from elasticsearch import AsyncElasticsearch
from typing import List, Optional
import os
from datetime import datetime
from uuid import uuid4

from app.models.product import Product, ProductCreate, ProductUpdate

class ElasticsearchClient:
    def __init__(self):
        self.es_host = os.getenv("ELASTICSEARCH_HOST", "elasticsearch")
        self.es_port = os.getenv("ELASTICSEARCH_PORT", "9200")
        self.index_name = "products"
        self.client: Optional[AsyncElasticsearch] = None

    async def initialize(self):
        """Initialize Elasticsearch connection and create index with mappings"""
        self.client = AsyncElasticsearch(
            hosts=[f"http://{self.es_host}:{self.es_port}"],
            retry_on_timeout=True,
            max_retries=3
        )

        # Wait for Elasticsearch to be ready
        for _ in range(30):
            try:
                if await self.client.ping():
                    break
            except Exception:
                import asyncio
                await asyncio.sleep(2)

        # Create index with mappings if it doesn't exist
        if not await self.client.indices.exists(index=self.index_name):
            await self.client.indices.create(
                index=self.index_name,
                body={
                    "settings": {
                        "number_of_shards": 1,
                        "number_of_replicas": 0,
                        "analysis": {
                            "analyzer": {
                                "product_analyzer": {
                                    "type": "custom",
                                    "tokenizer": "standard",
                                    "filter": ["lowercase", "asciifolding"]
                                }
                            }
                        }
                    },
                    "mappings": {
                        "properties": {
                            "name": {"type": "text", "analyzer": "product_analyzer"},
                            "description": {"type": "text", "analyzer": "product_analyzer"},
                            "price": {"type": "float"},
                            "category": {"type": "keyword"},
                            "stock": {"type": "integer"},
                            "image_url": {"type": "keyword"},
                            "created_at": {"type": "date"},
                            "updated_at": {"type": "date"}
                        }
                    }
                }
            )
            # Seed with sample products
            await self._seed_products()

    async def _seed_products(self):
        """Seed database with sample products"""
        sample_products = [
            {
                "name": "MacBook Pro 14",
                "description": "Apple MacBook Pro 14 pouces avec puce M3 Pro, 18 Go RAM, 512 Go SSD",
                "price": 2499.99,
                "category": "electronics",
                "stock": 25
            },
            {
                "name": "iPhone 15 Pro",
                "description": "Apple iPhone 15 Pro 256 Go, titane naturel",
                "price": 1229.00,
                "category": "electronics",
                "stock": 50
            },
            {
                "name": "Sony WH-1000XM5",
                "description": "Casque Bluetooth à réduction de bruit active, 30h d'autonomie",
                "price": 349.99,
                "category": "electronics",
                "stock": 100
            },
            {
                "name": "Samsung Galaxy Tab S9",
                "description": "Tablette Android 11 pouces AMOLED, 128 Go, Wi-Fi",
                "price": 899.00,
                "category": "electronics",
                "stock": 35
            },
            {
                "name": "Nike Air Max 90",
                "description": "Chaussures de sport classiques, blanc/noir",
                "price": 139.99,
                "category": "clothing",
                "stock": 200
            },
            {
                "name": "Levi's 501 Original",
                "description": "Jean homme coupe droite, bleu délavé",
                "price": 99.00,
                "category": "clothing",
                "stock": 150
            },
            {
                "name": "The North Face Nuptse",
                "description": "Doudoune homme noir, isolation 700",
                "price": 320.00,
                "category": "clothing",
                "stock": 45
            },
            {
                "name": "Clean Code",
                "description": "Robert C. Martin - Guide pratique du développement logiciel",
                "price": 35.99,
                "category": "books",
                "stock": 500
            },
            {
                "name": "Design Patterns",
                "description": "Gang of Four - Catalogue des patrons de conception",
                "price": 49.99,
                "category": "books",
                "stock": 300
            },
            {
                "name": "Dyson V15 Detect",
                "description": "Aspirateur balai sans fil avec laser, autonomie 60 min",
                "price": 699.00,
                "category": "home",
                "stock": 60
            },
            {
                "name": "Nespresso Vertuo Plus",
                "description": "Machine à café automatique, 5 tailles de tasses",
                "price": 149.99,
                "category": "home",
                "stock": 80
            },
            {
                "name": "Philips Hue Starter Kit",
                "description": "Kit de démarrage 3 ampoules connectées + pont",
                "price": 139.99,
                "category": "home",
                "stock": 120
            },
            {
                "name": "Adidas Ballon UEFA Champions League",
                "description": "Ballon officiel de match, taille 5",
                "price": 149.00,
                "category": "sports",
                "stock": 75
            },
            {
                "name": "Garmin Forerunner 265",
                "description": "Montre GPS running avec écran AMOLED",
                "price": 449.99,
                "category": "sports",
                "stock": 40
            },
            {
                "name": "Theragun Prime",
                "description": "Pistolet de massage percussion, 5 vitesses",
                "price": 299.00,
                "category": "sports",
                "stock": 55
            }
        ]

        for product_data in sample_products:
            product_id = str(uuid4())
            now = datetime.utcnow().isoformat()
            await self.client.index(
                index=self.index_name,
                id=product_id,
                body={
                    **product_data,
                    "created_at": now,
                    "updated_at": now
                }
            )
        
        await self.client.indices.refresh(index=self.index_name)
        print(f"✅ Seeded {len(sample_products)} sample products")

    async def close(self):
        """Close Elasticsearch connection"""
        if self.client:
            await self.client.close()

    async def health_check(self) -> str:
        """Check Elasticsearch health"""
        try:
            if self.client and await self.client.ping():
                return "connected"
            return "disconnected"
        except Exception:
            return "error"

    async def get_products(
        self,
        skip: int = 0,
        limit: int = 50,
        category: Optional[str] = None
    ) -> List[Product]:
        """Get all products with pagination and optional category filter"""
        query = {"match_all": {}}
        if category:
            query = {"term": {"category": category}}

        response = await self.client.search(
            index=self.index_name,
            body={
                "query": query,
                "from": skip,
                "size": limit,
                "sort": [{"created_at": "desc"}]
            }
        )

        products = []
        for hit in response["hits"]["hits"]:
            product_data = hit["_source"]
            product_data["id"] = hit["_id"]
            products.append(Product(**product_data))
        
        return products

    async def search_products(self, query: str, limit: int = 20) -> List[Product]:
        """Full-text search for products"""
        response = await self.client.search(
            index=self.index_name,
            body={
                "query": {
                    "multi_match": {
                        "query": query,
                        "fields": ["name^3", "description", "category^2"],
                        "fuzziness": "AUTO",
                        "operator": "or"
                    }
                },
                "size": limit
            }
        )

        products = []
        for hit in response["hits"]["hits"]:
            product_data = hit["_source"]
            product_data["id"] = hit["_id"]
            products.append(Product(**product_data))
        
        return products

    async def get_product(self, product_id: str) -> Optional[Product]:
        """Get a single product by ID"""
        try:
            response = await self.client.get(index=self.index_name, id=product_id)
            product_data = response["_source"]
            product_data["id"] = response["_id"]
            return Product(**product_data)
        except Exception:
            return None

    async def create_product(self, product: ProductCreate) -> Product:
        """Create a new product"""
        product_id = str(uuid4())
        now = datetime.utcnow()
        
        product_data = product.model_dump()
        product_data["created_at"] = now.isoformat()
        product_data["updated_at"] = now.isoformat()

        await self.client.index(
            index=self.index_name,
            id=product_id,
            body=product_data
        )
        await self.client.indices.refresh(index=self.index_name)

        return Product(id=product_id, **product.model_dump(), created_at=now, updated_at=now)

    async def update_product(self, product_id: str, product: ProductUpdate) -> Product:
        """Update an existing product"""
        update_data = {k: v for k, v in product.model_dump().items() if v is not None}
        update_data["updated_at"] = datetime.utcnow().isoformat()

        await self.client.update(
            index=self.index_name,
            id=product_id,
            body={"doc": update_data}
        )
        await self.client.indices.refresh(index=self.index_name)

        return await self.get_product(product_id)

    async def delete_product(self, product_id: str):
        """Delete a product"""
        await self.client.delete(index=self.index_name, id=product_id)
        await self.client.indices.refresh(index=self.index_name)
