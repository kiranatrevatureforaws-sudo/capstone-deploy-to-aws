# Product service

Spring Boot REST API using Java 21. Products are persisted in MySQL through
Spring Data JPA. Configure `SPRING_DATASOURCE_URL`,
`SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD`; the root Compose
configuration supplies these values from its untracked `.env` file. In
deployment, use private AWS RDS and keep the database credentials outside Git.

The service creates the `products` table if needed, validates the schema, and
seeds the original sample products only when the table is empty. Schema changes
must be managed explicitly. Maven tests use an isolated H2 database:

```sh
mvn test
```

Running `mvn spring-boot:run` requires the MySQL environment variables. The
default port is 8081; override it with `SERVER_PORT`.

| Method | Endpoint | Result |
| --- | --- | --- |
| POST | /api/products | Create a product (201 and Location header) |
| GET | /api/products | List products (200) |
| GET | /api/products/{id} | Get a product (200) |
| PUT | /api/products/{id} | Replace a product's fields (200) |
| DELETE | /api/products/{id} | Delete a product (204) |

POST and PUT accept:

```json
{
  "name": "Laptop",
  "price": 999.99,
  "category": "Electronics"
}
```

Name and category must be nonblank; price is required and must be nonnegative.
Invalid requests return 400, and missing products return 404.

Use the root `compose.yml` for local containers and EC2 deployment. The
workflow publishes immutable commit-SHA images and updates only changed
services. CI, SSH setup, initial deployment, RDS configuration, and rollback
instructions are in the root [README](../README.md).
