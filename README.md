# Capstone project

The project runs as a Docker Compose stack with the Angular frontend and two Spring Boot services.

## Run locally

From the repository root, build and start all containers:

```sh
docker compose up --build -d
```

Open `http://localhost`. Nginx serves the Angular app and proxies `/api/products` to product-service and `/api/catalog/products` to catalog-service. The backend containers are reachable through the Compose network and are not published directly to the host. Stop the stack with `docker compose down`.

## Deploy to EC2 with GitHub Actions

The `CI/CD` workflow tests and builds all three projects on pull requests and pushes to `main`. A successful push to `main` deploys the complete Compose stack to EC2 over SSH. The EC2 instance must have Docker Engine and the Docker Compose plugin installed, and the SSH deployment user must be able to run `docker compose`.

Configure these GitHub Actions secrets:

- `EC2_HOST`: EC2 public DNS name or IP address.
- `EC2_USER`: SSH user on the instance.
- `EC2_SSH_KEY`: private SSH key authorized for that user.
- `EC2_KNOWN_HOSTS`: verified host-key entry for the EC2 server.

To generate the known-hosts entry, run `ssh-keyscan -H -p 22 <EC2_HOST>` from a trusted environment and verify the host fingerprint against AWS or another trusted source before saving the output. If SSH uses a non-default port, set the Actions variable `EC2_SSH_PORT` and generate the entry with that port.

Allow inbound SSH only from trusted sources in the EC2 security group, and allow inbound TCP port 80 for the web app. The backend ports remain private to the Compose network.
