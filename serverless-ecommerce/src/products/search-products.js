console.log("Loading search products function");

const AWS = require("aws-sdk");
AWS.config.update({ region: "eu-west-2" });

const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  try {
    // Log environment variables
    console.log("PRODUCTS_TABLE:", process.env.PRODUCTS_TABLE);

    if (!process.env.PRODUCTS_TABLE) {
      throw new Error("PRODUCTS_TABLE environment variable is not set");
    }

    // Simple scan to test the connection
    const params = {
      TableName: process.env.PRODUCTS_TABLE,
    };

    console.log("Scanning table with params:", JSON.stringify(params));

    const result = await dynamodb.scan(params).promise();
    console.log(
      "Scan successful, items:",
      result.Items ? result.Items.length : 0
    );

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        success: true,
        message: "Products retrieved successfully",
        products: result.Items || [],
        count: result.Items ? result.Items.length : 0,
      }),
    };
  } catch (error) {
    console.error("FUNCTION ERROR:", error);
    console.error("Error name:", error.name);
    console.error("Error message:", error.message);
    console.error("Error code:", error.code);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        success: false,
        error: "Internal server error",
        message: error.message,
        code: error.code,
      }),
    };
  }
};
