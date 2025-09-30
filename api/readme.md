# Gertrude API

## Docker Setup (Production Replica)

Run a production-like environment:

```bash
# Start containers (postgres + gertrude-api)
docker compose up -d

# Enter bash shell in gertrude-api container
docker compose exec gertrude-api bash

# Run migrations (first time only)
docker compose exec -T gertrude-api bash -c "cd /app/api && ./.build/debug/Run migrate --yes"

# Start the server
docker compose exec -T gertrude-api bash -c "cd /app/api && ./.build/debug/Run serve"

# Stop the server (Ctrl+C or in another terminal)
docker compose stop gertrude-api

# Stop everything
docker compose down

# Remove volumes (clean slate)
docker compose down -v

# Clean rebuild
docker compose down -v && docker rmi gertrude-api && docker compose build --no-cache
```

The setup replicates production with:

- Ubuntu 20.04 base (swift:6.1.2-focal)
- PostgreSQL 17 on port 5432
- 2 CPU cores, 4GB RAM limits
- All local monorepo packages mounted for live debugging
