# Catalog service

Java 21 Spring Boot REST API that calls `product-service` through WebClient.
In Compose, `SERVER_PORT` is set to 8080 and the service reaches
`http://product-service:8081` through the internal Docker network. Outside
Compose, the default port is 8082; set `SERVER_PORT=8080` to match the
container configuration.

Start `product-service` on port 8081 before running this service locally:

```sh
mvn spring-boot:run
```

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

Configure `PRODUCT_SERVICE_BASE_URL` (default `http://localhost:8081`),
`PRODUCT_SERVICE_TIMEOUT` (default `5s`), and `SERVER_PORT` (default `8082`).
Product-service validates requests; its error status and body are forwarded.
Connection failures return 502 and request timeouts return 504.

Use the root `compose.yml` for container and EC2 deployment. CI/CD and SSH
deployment instructions are in the root [README](../README.md).
