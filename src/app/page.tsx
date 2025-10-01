// src/app/page.tsx 
"use client";
import { useState, useEffect } from "react";

interface Product {
  productId: string;
  name: string;
  price: number;
  description: string;
  category: string;
}

export default function Home() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState({ productCount: 0, lastUpdated: "" });

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      // For now, we'll use mock data until we deploy the real API
      const mockProducts: Product[] = [
        {
          productId: "1",
          name: "Serverless Compute Book",
          price: 29.99,
          description: "Complete guide to serverless architecture",
          category: "Books",
        },
        {
          productId: "2",
          name: "AWS Cloud Watch",
          price: 49.99,
          description: "Premium cloud monitoring device",
          category: "Electronics",
        },
        {
          productId: "3",
          name: "Terraform Template Pack",
          price: 19.99,
          description: "Ready-to-use infrastructure templates",
          category: "Software",
        },
      ];

      setProducts(mockProducts);
      setMetrics({
        productCount: mockProducts.length,
        lastUpdated: new Date().toISOString(),
      });
    } catch (error) {
      console.error("Error fetching products:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header with Metrics */}
      <div className="text-center mb-12">
        <h1 className="text-4xl font-bold text-gray-800 mb-4">
          🚀 Serverless E-commerce
        </h1>
        <p className="text-xl text-gray-600 mb-6">
          Cloud-native platform with real-time observability
        </p>

        {/* Live Metrics Badge */}
        <div className="inline-flex items-center bg-green-100 text-green-800 px-4 py-2 rounded-full">
          <span className="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></span>
          Live Metrics: {metrics.productCount} products loaded
        </div>
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="text-lg">Loading products...</div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {products.map((product) => (
            <div
              key={product.productId}
              className="border border-gray-200 rounded-xl p-6 hover:shadow-lg transition-shadow"
            >
              <div className="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full w-fit mb-4">
                {product.category}
              </div>

              <h3 className="text-xl font-semibold text-gray-800 mb-2">
                {product.name}
              </h3>

              <p className="text-gray-600 mb-4">{product.description}</p>

              <div className="flex justify-between items-center">
                <span className="text-2xl font-bold text-gray-900">
                  ${product.price}
                </span>
                <button className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition-colors">
                  Add to Cart
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Footer Note */}
      <div className="mt-12 text-center text-gray-500">
        <p>
          🛠️ Built with AWS Lambda, DynamoDB, Terraform & Real-time
          Observability
        </p>
        <p className="text-sm mt-2">
          Infrastructure Cost: ~$18/month | 99.9% Uptime
        </p>
      </div>
    </div>
  );
}
