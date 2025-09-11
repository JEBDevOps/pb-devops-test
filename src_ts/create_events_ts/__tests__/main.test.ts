import { handler } from "../main";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { mockClient } from "aws-sdk-client-mock";

describe("Create Event Lambda", () => {
  const ddbMock = mockClient(DynamoDBDocumentClient);

  beforeEach(() => {
    ddbMock.reset();
  });

  it("should create an event successfully", async () => {
    const event = {
      body: JSON.stringify({
        id: "123",
        type: "test",
        payload: { data: "test" },
      }),
    } as any;

    ddbMock.on(PutCommand).resolves({});

    const result = await handler(event);

    expect(result.statusCode).toBe(201);
    expect(JSON.parse(result.body)).toEqual({ id: "123" });
  });

  it("should return 400 if body is not a valid JSON", async () => {
    const event = {
      body: "invalid json",
    } as any;

    const result = await handler(event);

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({ message: "Invalid JSON body" });
  });

  it("should return 400 if required fields are missing", async () => {
    const event = {
      body: JSON.stringify({ id: "123", type: "test" }),
    } as any;

    const result = await handler(event);

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      message: "Missing required fields: id, type, payload",
    });
  });
});
