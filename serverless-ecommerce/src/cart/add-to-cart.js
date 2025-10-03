const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    const { userId, productId, quantity } = JSON.parse(event.body);

    // Validate input
    if (!userId || !productId || !quantity) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Missing required fields: userId, productId, quantity",
        }),
      };
    }

    // Get product to validate existence and price
    const productResult = await dynamodb
      .get({
        TableName: process.env.PRODUCTS_TABLE,
        Key: { productId },
      })
      .promise();

    if (!productResult.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "Product not found" }),
      };
    }

    const product = productResult.Item;

    // Check stock availability
    if (product.stock < quantity) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Insufficient stock" }),
      };
    }

    // Calculate item total
    const itemTotal = product.price * quantity;

    // Update cart (add or update item)
    const timestamp = new Date().toISOString();
    const ttl = Math.floor(Date.now() / 1000) + 24 * 60 * 60; // 24 hours from now

    await dynamodb
      .update({
        TableName: process.env.CARTS_TABLE,
        Key: { userId },
        UpdateExpression: `SET 
        #items.#productId = :item,
        updatedAt = :updatedAt,
        #ttl = :ttl
        ADD total :itemTotal`,
        ExpressionAttributeNames: {
          "#items": "items",
          "#productId": productId,
          "#ttl": "ttl",
        },
        ExpressionAttributeValues: {
          ":item": {
            productId,
            name: product.name,
            price: product.price,
            quantity,
            itemTotal,
          },
          ":updatedAt": timestamp,
          ":ttl": ttl,
          ":itemTotal": itemTotal,
        },
        ReturnValues: "ALL_NEW",
      })
      .promise();

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "Item added to cart",
        product: {
          productId,
          name: product.name,
          price: product.price,
          quantity,
        },
      }),
    };
  } catch (error) {
    console.error("Add to cart error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
