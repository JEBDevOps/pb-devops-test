import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  const tableName = process.env.TABLE_NAME;

  if (!event.body) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Invalid JSON body" }),
    };
  }

  try {
    const data = JSON.parse(event.body);

    const requiredFields = ["id", "type", "payload"];
    if (!requiredFields.every((field) => field in data)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Missing required fields: id, type, payload",
        }),
      };
    }

    const command = new PutCommand({
      TableName: tableName,
      Item: data,
    });

    await docClient.send(command);

    return {
      statusCode: 201,
      body: JSON.stringify({ id: data.id }),
    };
  } catch (error) {
    if (error instanceof SyntaxError) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid JSON body" }),
      };
    }
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};
