const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log("Get cart event:", JSON.stringify(event, null, 2));

  try {
    const { userId } = event.pathParameters;

    if (!userId) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ error: "User ID is required" }),
      };
    }

    const result = await dynamodb
      .get({
        TableName: process.env.CARTS_TABLE,
        Key: { userId },
      })
      .promise();

    // Return empty cart if not found
    const cart = result.Item || {
      userId,
      items: {},
      total: 0,
      createdAt: new Date().toISOString(),
    };

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(cart),
    };
  } catch (error) {
    console.error("Get cart error:", error);
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
