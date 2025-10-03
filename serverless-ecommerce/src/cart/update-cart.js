const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log("Update cart event:", JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body);
    const { userId, productId, quantity } = body;

    if (!userId || !productId) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          error: "Missing required fields: userId, productId",
        }),
      };
    }

    // If quantity is 0 or negative, remove the item
    if (quantity <= 0) {
      // Remove item from cart
      const result = await dynamodb
        .update({
          TableName: process.env.CARTS_TABLE,
          Key: { userId },
          UpdateExpression: "REMOVE #items.#productId",
          ExpressionAttributeNames: {
            "#items": "items",
            "#productId": productId,
          },
          ReturnValues: "ALL_NEW",
        })
        .promise();

      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          message: "Item removed from cart",
          cart: result.Attributes,
        }),
      };
    }

    // Update item quantity
    const result = await dynamodb
      .update({
        TableName: process.env.CARTS_TABLE,
        Key: { userId },
        UpdateExpression:
          "SET #items.#productId.quantity = :quantity, updatedAt = :updatedAt",
        ExpressionAttributeNames: {
          "#items": "items",
          "#productId": productId,
        },
        ExpressionAttributeValues: {
          ":quantity": quantity,
          ":updatedAt": new Date().toISOString(),
        },
        ReturnValues: "ALL_NEW",
      })
      .promise();

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        message: "Cart updated",
        cart: result.Attributes,
      }),
    };
  } catch (error) {
    console.error("Update cart error:", error);
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
