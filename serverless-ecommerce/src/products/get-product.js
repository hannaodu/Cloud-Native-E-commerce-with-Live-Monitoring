console.log("Loading get product function");

const AWS = require("aws-sdk");
AWS.config.update({ region: "eu-west-2" });

const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  try {
    console.log("PRODUCTS_TABLE:", process.env.PRODUCTS_TABLE);

    if (!process.env.PRODUCTS_TABLE) {
      throw new Error("PRODUCTS_TABLE environment variable is not set");
    }

    const { productId } = event.pathParameters || {};
    console.log("Product ID:", productId);

    if (!productId) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          success: false,
          error: "Product ID is required in the URL path",
        }),
      };
    }

    const params = {
      TableName: process.env.PRODUCTS_TABLE,
      Key: { productId },
    };

    console.log("Get item params:", JSON.stringify(params));

    const result = await dynamodb.get(params).promise();
    console.log("Get item result:", JSON.stringify(result));

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          success: false,
          error: `Product with ID ${productId} not found`,
        }),
      };
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        success: true,
        product: result.Item,
      }),
    };
  } catch (error) {
    console.error("FUNCTION ERROR:", error);
    console.error("Error name:", error.name);
    console.error("Error message:", error.message);
    console.error("Error code:", error.code);

    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({
        success: false,
        error: "Internal server error",
        message: error.message,
        code: error.code,
      }),
    };
  }
};
