# Capstone project

The project runs one Docker Compose application environment: Angular/Nginx, `product-service`, and `catalog-service`. Catalog calls Product over the Compose network. Product stores its data in MySQL; configure the database using environment variables from `.env` and keep MySQL on private AWS RDS.

## Run locally

Copy `.env.example` to `.env`, set the Docker Hub username, image tags, and MySQL connection values, then run:

```sh
docker compose up --build -d
```

For local development, provide a reachable MySQL database. Open `http://localhost`; Nginx proxies `/api/products` and `/api/catalog/products` to the backend services. Backend ports are not published to the host. Stop the stack with `docker compose down`.

The product service initializes the `products` table if needed and seeds the original sample products only when that table is empty. Schema validation is enabled; schema changes must be managed explicitly. The test suite uses an isolated H2 database.

## CI/CD and deployment

`.github/workflows/ci-cd.yml` runs applicable tests on feature branches and pull requests to `development` or `main`. Pushes to either deployment branch publish SHA-tagged Docker Hub images only for changed applications, then update the same EC2 Compose environment over SSH. Workflow dispatch on `development` or `main` builds all applications and is intended for initial deployment. The remote deploy script updates only specified services and rejects stale workflow runs.

Configure these GitHub Actions secrets (repository-level or on the shared `production` environment):

- `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
- `EC2_HOST`, `EC2_USER`, and `EC2_SSH_KEY` (the existing `.pem` key contents)
- `EC2_HOST_KEY` (a verified known-hosts entry for the EC2 host)

Optionally set the Actions variable `EC2_SSH_PORT` (default `22`). Obtain the SSH host key in a trusted environment and independently verify its fingerprint; do not rely on an unverified `ssh-keyscan` result. The `EC2_HOST_KEY` value must match the host (or `[host]:port` for a non-default port). The workflow uses `StrictHostKeyChecking=yes`.

Install Docker Engine, the Docker Compose v2 plugin, Bash, and `flock` on EC2; the SSH deployment user must be allowed to run Docker Compose. Before the first deploy, create `~/capstone-project/.env` from `.env.example`, set actual registry and private RDS values, and restrict it to the deployment user (`chmod 600`). Do not commit or send database credentials through workflow logs. RDS must not be publicly accessible, and its security group should allow TCP 3306 only from the EC2 security group. Allow application ingress only on the required web port (80 by default).

GitHub-hosted runners need inbound SSH access to the EC2 host. Avoid permanently allowing SSH from `0.0.0.0/0`: runner egress addresses vary, so prefer a self-hosted runner with a controlled static egress address or maintain a narrowly scoped allowlist from GitHub's published runner IP ranges.

For a single-service rollback on EC2, run `bash rollback.sh product-service`, `bash rollback.sh catalog-service`, or `bash rollback.sh angular-app`. Rollback history is stored in the deployment directory.

Sonar analysis is currently deferred as requested; image publishing and deployment therefore do not wait for a Sonar Quality Gate. Configure Sonar platform/project secrets and restore the Sonar gate before relying on Sonar enforcement.
