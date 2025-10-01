// lib/products-api.ts
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event: any) => {
  console.log("Products API called", JSON.stringify(event));

  try {
    const command = new ScanCommand({
      TableName: process.env.PRODUCTS_TABLE!,
    });

    const result = await docClient.send(command);

    // Structured logging for observability
    console.log(
      JSON.stringify({
        level: "INFO",
        message: "Products fetched successfully",
        productCount: result.Count,
        timestamp: new Date().toISOString(),
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        products: result.Items,
        metadata: {
          totalItems: result.Count,
          timestamp: new Date().toISOString(),
        },
      }),
    };
  } catch (error: any) {
    console.error(
      JSON.stringify({
        level: "ERROR",
        message: "Failed to fetch products",
        error: error.message,
        timestamp: new Date().toISOString(),
      })
    );

    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to fetch products" }),
    };
  }
};
