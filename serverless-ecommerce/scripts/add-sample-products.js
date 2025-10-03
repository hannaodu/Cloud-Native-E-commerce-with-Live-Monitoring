const AWS = require("aws-sdk");

// Configure AWS SDK
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: "eu-west-2",
});

const sampleProducts = [
  {
    productId: "prod-001",
    name: "MacBook Pro",
    category: "electronics",
    price: 1999.99,
    brand: "Apple",
    stock: 15,
    description: "16-inch MacBook Pro with M2 Pro chip",
  },
  {
    productId: "prod-002",
    name: "iPhone 15",
    category: "electronics",
    price: 899.99,
    brand: "Apple",
    stock: 30,
    description: "Latest iPhone with A16 Bionic chip",
  },
  {
    productId: "prod-003",
    name: "Wireless Headphones",
    category: "electronics",
    price: 249.99,
    brand: "Sony",
    stock: 50,
    description: "Noise cancelling wireless headphones",
  },
  {
    productId: "prod-004",
    name: "Cotton T-Shirt",
    category: "clothing",
    price: 24.99,
    brand: "Nike",
    stock: 100,
    description: "Comfortable cotton t-shirt",
  },
  {
    productId: "prod-005",
    name: "Running Shoes",
    category: "clothing",
    price: 129.99,
    brand: "Adidas",
    stock: 25,
    description: "Lightweight running shoes",
  },
];

async function addSampleProducts() {
  console.log("Adding sample products to DynamoDB...");

  for (const product of sampleProducts) {
    try {
      await dynamodb
        .put({
          TableName: "Products",
          Item: product,
        })
        .promise();
      console.log(`✅ Added product: ${product.name} (${product.productId})`);
    } catch (error) {
      console.error(`❌ Failed to add product ${product.name}:`, error);
    }
  }

  console.log("Sample products added successfully!");
}

addSampleProducts();
