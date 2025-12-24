# Example: Mixed Service Types

This example demonstrates a `graft-compose.yml` with both build-based and image-based services.

## Sample graft-compose.yml

```yaml
version: '3.8'

services:
  # Build-based service - builds from source on server
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    labels:
      - "graft.mode=serverbuild"
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`api.example.com`)"
    networks:
      - graft-public
    restart: unless-stopped

  # Image-based service - pulls from registry
  frontend:
    image: nginx:alpine
    labels:
      - "graft.mode=localbuild"
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`example.com`)"
    networks:
      - graft-public
    restart: unless-stopped
  
  # Another image-based service
  redis:
    image: redis:7-alpine
    labels:
      - "graft.mode=localbuild"
    networks:
      - graft-public
    restart: unless-stopped

networks:
  graft-public:
    external: true
```

## How Graft Handles This

### Full Sync: `graft sync`

1. **Backend (build-based)**:
   - Uploads `./backend` directory to server
   - Builds Docker image from source
   - Starts container

2. **Frontend (image-based)**:
   - Pulls latest `nginx:alpine` from Docker Hub
   - Starts container with new image

3. **Redis (image-based)**:
   - Pulls latest `redis:7-alpine` from Docker Hub
   - Starts container with new image

The command `docker compose up -d --pull always` ensures:
- Build-based services are built from uploaded source
- Image-based services pull the latest version

### Single Service Sync: `graft sync backend`

For build-based service:
```bash
graft sync backend
```
- Uploads `./backend` source code
- Stops old container
- Builds from source
- Starts new container

### Single Service Sync: `graft sync frontend`

For image-based service:
```bash
graft sync frontend
```
- Uploads docker-compose.yml
- Stops old container
- **Pulls latest nginx:alpine image**
- Starts new container

## Benefits

✅ **Flexibility**: Mix and match service types based on your needs
✅ **Efficiency**: Build-based services for custom code, image-based for standard tools
✅ **Always Updated**: Image-based services automatically get latest versions
✅ **No Confusion**: Graft automatically detects and handles each type correctly

## Common Patterns

### Pattern 1: Custom Backend + Standard Tools
```yaml
services:
  api:
    build: ./api              # Your custom code
    labels:
      - "graft.mode=serverbuild"
  
  postgres:
    image: postgres:16-alpine # Standard database
    labels:
      - "graft.mode=localbuild"
  
  redis:
    image: redis:7-alpine     # Standard cache
    labels:
      - "graft.mode=localbuild"
```

### Pattern 2: Microservices from Registry
```yaml
services:
  auth-service:
    image: myregistry.io/auth:latest
    labels:
      - "graft.mode=localbuild"
  
  user-service:
    image: myregistry.io/users:latest
    labels:
      - "graft.mode=localbuild"
  
  gateway:
    build: ./gateway          # Custom gateway logic
    labels:
      - "graft.mode=serverbuild"
```

### Pattern 3: All Pre-built Images
```yaml
services:
  app:
    image: ghcr.io/myorg/app:latest
    labels:
      - "graft.mode=localbuild"
  
  worker:
    image: ghcr.io/myorg/worker:latest
    labels:
      - "graft.mode=localbuild"
```

## Verification

After syncing, verify services are running:

```bash
# Check all services
graft ps

# Check logs
graft logs backend
graft logs frontend

# Verify image versions
graft exec frontend nginx -v
graft exec redis redis-server --version
```
