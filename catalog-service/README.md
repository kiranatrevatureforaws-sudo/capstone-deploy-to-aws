# Catalog service

Java 21 Spring Boot REST API that calls product-service through WebClient.
Start product-service on port 8081, then run `mvn spring-boot:run` in this directory.
Catalog-service defaults to port 8080.

| Method | Endpoint | Result |
| --- | --- | --- |
| GET | /api/catalog/products | List products |
| GET | /api/catalog/products/{id} | Get a product |
| POST | /api/catalog/products | Create a product (201 with catalog Location header) |
| PUT | /api/catalog/products/{id} | Update a product |
| DELETE | /api/catalog/products/{id} | Delete a product (204) |

POST and PUT accept:

```json
{"name":"Laptop","price":999.99,"category":"Electronics"}
```

Product-service validates requests; its error status and body are forwarded.
Connection failures return 502 and request timeouts return 504.
Configure `PRODUCT_SERVICE_BASE_URL` (default `http://localhost:8081`),
`PRODUCT_SERVICE_TIMEOUT` (default `5s`), and `SERVER_PORT` (default `8080`).

Build without compiling or running tests: `mvn -Dmaven.test.skip=true package`.

## GitHub Actions deployment

`../.github/workflows/deploy-catalog.yml` follows the product-service workflow: pull requests
to `main` build and run existing tests; pushes and manual runs on `main` also
build a Docker image and deploy it on EC2. No new test classes are required.

Register a Linux x64 self-hosted runner with label `catalog-service-deploy` on
the target EC2 instance and configure the GitHub `production` environment.
The runner needs Docker, curl, and passwordless `sudo` for Docker commands.
The workflow lives at the CapstoneProject repository root and runs Maven and
Docker commands from `catalog-service`. Automatic runs are filtered to changes
in this service or its workflow; manual runs are also available.

Catalog is published on port 8080. Set the GitHub environment or repository
variable `PRODUCT_SERVICE_BASE_URL` to the product-service URL. It defaults to
`http://host.docker.internal:8081`, which reaches product-service published on
port 8081 of the same EC2 host (Docker Engine 20.10+ required for host-gateway).
For a separate host, use its reachable address and allow the required network
traffic. The deployment health check calls `/api/catalog/products`, so
product-service must be running and reachable for deployment to succeed.

Deployment replaces the existing catalog container and briefly interrupts
service. A failed health check reports container logs and fails the job;
there is no automatic rollback.
