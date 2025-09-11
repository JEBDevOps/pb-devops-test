import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  const tableName = process.env.TABLE_NAME;
  const itemId = event.pathParameters?.id;

  if (!itemId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Missing path parameter: id" }),
    };
  }

  const command = new GetCommand({
    TableName: tableName,
    Key: {
      id: itemId,
    },
  });

  try {
    const response = await docClient.send(command);
    const item = response.Item;

    if (item) {
      return {
        statusCode: 200,
        body: JSON.stringify(item),
      };
    } else {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: "Item not found" }),
      };
    }
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};
