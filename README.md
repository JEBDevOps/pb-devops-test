# Event API Project

This project implements a simple serverless API for creating and retrieving events. It is built on AWS using API Gateway, Lambda, and DynamoDB, with infrastructure managed by Terraform.

## Getting Started

These instructions will get you a copy of the project up and running for development and testing purposes, and guide you on how to deploy it to AWS.

### Prerequisites

*   AWS Account and configured credentials
*   Terraform
*   Python 3.9 (to test locally)

## Github Secrets

Make sure to create a `AWS_ACCOUNT_ID` secret inside the Github Secrets. This will be used by the CD Workflow to deploy the infrastructure.

## Deployment Setup (OIDC)

Before deploying the application, you need to set up the AWS IAM OIDC provider and roles for GitHub Actions to securely authenticate with your AWS account. This is a one-time setup.

1.  Navigate to the OIDC directory:
    ```bash
    cd oidc
    ```

2. Initialize Terraform:
    ```bash
    terraform init
    ```

3. Apply the Terraform configuration to create the OIDC roles:
    ```bash
    terraform apply -auto-approve
    ```

## CI

When we push to the `main` branch, Github Actions will run the CI (`.github/workflows/ci.yml`)

The CI will run lint using `pylint` and tests using `pytest`.


## Deployment

The project is set up for continuous deployment using GitHub Actions. The deployment workflow is automatically triggered upon a push to the `main` branch, provided that the linting and testing jobs in the CI workflow pass.

The GitHub Actions workflow will then run the Terraform configuration in the `infra` directory to deploy the API Gateway, Lambda functions, and DynamoDB table.

## API Usage

The base URL will be provided in the output of the Terraform deployment, which we can get from the logs of the Github Actions Workflow, but it might be easier to find it inside the AWS Console.

**Base URL:** `https://<api_gateway_id>.execute-api.ap-southeast-1.amazonaws.com/prod`

*(Replace `<api_gateway_id>` with the actual ID of your API Gateway deployment.)*

### Endpoints

#### Create Event

*   **POST** `/events`

Creates a new event.

**Example `curl` command:**

```bash
curl -X POST 'https://<api_gateway_id>.execute-api.ap-southeast-1.amazonaws.com/prod/events' \
--header 'Content-Type: application/json' \
--data-raw '{
    "id": "123",
    "type": "test_event",
    "payload": {"key": "value"}
}'
```

#### Get Event

*   **GET** `/events/{id}`

Retrieves an event by its ID.

**Example `curl` command:**

```bash
curl 'https://<api_gateway_id>.execute-api.ap-southeast-1.amazonaws.com/prod/events/123'
```

## Trade-offs

*   **Database Throughput:** The DynamoDB table is configured with default (on-demand) throughput settings to optimize for cost in a low-traffic environment. For a production system with predictable traffic, provisioned throughput would be a more cost-effective choice.
*   **Validation:** Input validation is currently basic and handled within the Lambda function. A more robust approach would be to use API Gateway's request validation feature to offload this task and catch errors earlier.
*   **WAF:** If this was on production, I would want to use WAF to make it more secure. I haven't tried using WAF on API Gateway, but I'm sure it is gonna be easier compared to when I set it up for Kubernetes.

## Future Improvements

*   **Input Validation:** Implement more comprehensive input validation, potentially using a library like `pydantic` to define the expected request body schema.
*   **Error Handling:** Enhance error handling to provide more specific error messages and status codes for different failure scenarios.
*   **Monitoring and Alarms:** Add CloudWatch alarms for key metrics like Lambda errors, high invocation duration, and API Gateway 5XX errors to proactively detect issues.

## Production Readiness

For this API to be considered production-ready, the following aspects should be addressed:

*   **Authentication and Authorization:** Implement a mechanism to secure the API endpoints, such as API keys, or Lambda authorizers.
*   **Logging and Tracing:** Implement structured logging (e.g., JSON format) for all Lambda functions and enable AWS X-Ray for distributed tracing to improve observability and debugging.
*   **CI/CD:** The current CI/CD pipeline is basic. A production-grade pipeline would include multiple stages (dev, staging, prod), integration tests, and potentially canary or blue/green deployments.

## AI Assistance

This project was developed with the assistance of an AI tool. I used AI mostly on the Python codes and the IAM Policies.

I'm not actually that good at python so even though the code was simple, I still used AI for it to make sure I was making it right.

I could have used Node.js because that's what I've used the most before but I know that Python is a lot better and more efficient when it comes to resources.

As for the IAM policies and permissions, AWS Permissions are hard to memorize so I usually just check the official documentations but in this case, I used AI to make it a little faster.

I also asked the AI to check my codes for issues.
