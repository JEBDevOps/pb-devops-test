import { handler } from '../main';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
import { mockClient } from 'aws-sdk-client-mock';

describe('Get Event Lambda', () => {
  const ddbMock = mockClient(DynamoDBDocumentClient);

  beforeEach(() => {
    ddbMock.reset();
  });

  it('should return an event successfully', async () => {
    const item = { id: '123', type: 'test', payload: { data: 'test' } };
    const event = {
      pathParameters: { id: '123' },
    } as any;

    ddbMock.on(GetCommand).resolves({ Item: item });

    const result = await handler(event);

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body)).toEqual(item);
  });

  it('should return 404 if item is not found', async () => {
    const event = {
      pathParameters: { id: '123' },
    } as any;

    ddbMock.on(GetCommand).resolves({});

    const result = await handler(event);

    expect(result.statusCode).toBe(404);
    expect(JSON.parse(result.body)).toEqual({ message: 'Item not found' });
  });

  it('should return 400 if id is missing from path parameters', async () => {
    const event = {
      pathParameters: {},
    } as any;

    const result = await handler(event);

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({ message: 'Missing path parameter: id' });
  });
});
