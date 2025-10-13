# Docker Implementation Explanation

## Project Overview

This project containerizes a MERN stack e-commerce application using Docker.

**Final Results:**
- Frontend: 14MB
- Backend: 87.8MB
- Total: 101.8MB (74.55% under 400MB requirement)

---

## 1. Choice of Base Images

### Frontend
**Base Image**: Alpine 3.18 + nginx

**Why Alpine?**
- Minimal size (7MB base)
- Security focused
- Production ready

**Build Process:**
- Build stage: node:14-alpine (for compiling React)
- Production stage: alpine:3.18 + nginx (for serving files)
- Result: 14MB final image

### Backend
**Base Image**: Alpine 3.18 + Node.js runtime

**Why Alpine?**
- Much smaller than full Node.js image (900MB → 87.8MB)
- Only includes runtime, no build tools
- Production optimized

**Process:**
- Build stage: node:14-alpine (for npm install)
- Production stage: alpine:3.18 + nodejs only
- Used `npm install --production` to exclude dev dependencies

### Database
**Image**: mongo:5 (official, pulled from Docker Hub)

**Why MongoDB?**
- Production tested and maintained
- Pulled image (doesn't count toward 400MB limit)
- Reliable and stable

**Note**: MongoDB is a base image like node:14-alpine. Only custom-built images (frontend + backend) count toward the 400MB requirement.

---

## 2. Dockerfile Directives

### Frontend Dockerfile

FROM node:14-alpine AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install && npm cache clean --force
COPY . .
RUN npm run build

FROM alpine:3.18
WORKDIR /app
RUN apk add --no-cache nginx
COPY --from=build /usr/src/app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /run/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html /var/log/nginx /run/nginx
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]

**Key Directives:**
- FROM ... AS build: Multi-stage build - separate build from runtime
- WORKDIR: Sets working directory
- COPY package*.json ./: Copy dependencies first for caching
- RUN npm install && npm cache clean: Install and clean in one layer
- COPY . .: Copy source code after dependencies
- RUN npm run build: Build React production bundle
- FROM alpine:3.18: New clean stage for production
- COPY --from=build: Copy only built files, discard source and node_modules
- CMD: Run nginx in foreground

**Result**: 14MB (only nginx + built React files)

### Backend Dockerfile

FROM node:14-alpine AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --production
COPY . .

FROM alpine:3.18
WORKDIR /app
RUN apk add --no-cache nodejs
COPY --from=build /usr/src/app /app
EXPOSE 5000
CMD ["node", "server.js"]

**Key Directives:**
- npm install --production: Excludes devDependencies (saves 15-20MB)
- FROM alpine:3.18: Clean production stage
- RUN apk add --no-cache nodejs: Only Node.js runtime, no npm
- COPY --from=build: Copy app + production node_modules only

**Result**: 87.8MB (Node.js runtime + production dependencies)

### .dockerignore Files

Both frontend and backend have .dockerignore:

node_modules
npm-debug.log
.git
.env*
*.log

**Purpose**: Prevents copying unnecessary files, reduces build context size

---

## 3. Docker-Compose Networking

### Network Configuration

networks:
  app-net:
    driver: bridge

**Bridge Network:**
- Default Docker network type for single-host containers
- Provides container isolation
- Enables DNS-based service discovery (containers reach each other by name)
- Custom network separate from default bridge

**Why Bridge?**
- Isolates containers on dedicated network
- Containers communicate using names (app-mongo, app-yolo-backend)
- Perfect for single-host deployments
- Host mode: No isolation, security risk
- Overlay mode: For multi-host clusters (overkill)

### Port Mapping

kennedy-yolo-client:
  ports:
    - "3000:3000"    # Browser access

kennedy-yolo-backend:
  ports:
    - "5000:5000"    # API access

app-mongo:
  # No external ports - internal only

**How It Works:**
- Browser → localhost:3000 → nginx container
- Frontend → localhost:5000 → backend container
- Backend → app-mongo:27017 → MongoDB (internal DNS)

### Service Discovery

environment:
  - MONGODB_URI=mongodb://app-mongo:27017/yolomy

Docker automatically resolves app-mongo to the MongoDB container's IP address.

---

## 4. Docker-Compose Volumes

### Volume Definition

volumes:
  app-mongo-data:
    driver: local

**Local Driver:**
- Stores data on Docker host's filesystem
- Location: /var/lib/docker/volumes/yolo_app-mongo-data/_data/
- Managed by Docker

### Volume Usage

app-mongo:
  volumes:
    - app-mongo-data:/data/db

**What This Does:**
- MongoDB writes to /data/db inside container
- Data actually stored in Docker volume on host
- Data survives container deletion/restart

### Why Named Volume?

**Named Volume (Our Choice):**
- app-mongo-data:/data/db
- Platform independent
- Docker manages permissions
- Easy to backup

**Bind Mount (Not Used):**
- ./data:/data/db
- Platform dependent
- Permission issues
- Manual management

### Testing Persistence

# Add products
docker compose up -d
# (Add products via UI)

# Stop and remove containers
docker compose down

# Restart
docker compose up -d
# Products still there!

---

## 5. Git Workflow

### Commit History

Our development followed these key stages:

* ca4a1c3 - Updated productRoute.js to make image upload optional
* 04b3a76 - Reverted to MongoDB official image
* 7c3937d - Successful FerretDB+PostgreSQL connection fixes
* 31e8f33 - Optimize images from 987MB to 372MB
* dc8c113 - Added build stage to client Dockerfile
* cdf4f67 - Added nginx to serve app
* 877b280 - Added dockerignore for backend

### Commit Convention

<type>: <description>

Types used:
- feat: New features
- fix: Bug fixes
- docs: Documentation

### Development Process

1. Initial setup (forked repo)
2. Created Dockerfiles
3. Optimized images (987MB → 101.8MB)
4. Fixed bugs (callbacks, deprecated options)
5. Added documentation
6. Deployed to DockerHub

### Version Tags

git tag -a v1.0.3 -m "Production release"
git push origin v1.0.3

---

## 6. Application Running & Debugging

### Current Status: Working

docker compose ps

NAME              STATUS
app-yolo-client   Up
app-yolo-backend  Up
app-mongo         Up

**Access:**
- Frontend: http://localhost:3000
- API: http://localhost:5000/api/products

### Debugging Journey

**Issue 1: Large Images (987MB)**
- Problem: Using full node:14 and nginx images
- Solution: Switched to Alpine + multi-stage builds
- Result: 987MB → 101.8MB (90% reduction)

**Issue 2: npm Deprecated Warnings**
- Problem: useNewUrlParser and useUnifiedTopology deprecated
- Solution: Removed these options from mongoose.connect()
- Result: Clean startup, no warnings

**Issue 3: Module Not Found**
- Problem: require('../../models/Product') but file is Products.js
- Solution: Changed to require('../../models/Products')
- Result: Backend starts successfully

**Issue 4: Mongoose Callbacks Deprecated**
- Problem: Model.find() no longer accepts callbacks
- Solution: Refactored all routes to async/await
- Result: All CRUD operations working

**Issue 5: Image Upload Error**
- Problem: req.files.image crashes when no file uploaded
- Solution: Made image optional: req.files && req.files.image ? req.files.image : null
- Result: Products can be added without images

### Testing Process

# Build
docker compose build

# Start
docker compose up -d

# Test API
curl http://localhost:5000/api/products

# Test frontend
curl http://localhost:3000

# Check logs
docker compose logs -f

---

## 7. Docker Image Naming Standards

### Semantic Versioning

**Format:** username/repository:version

**Our Images:**
kipanch/yolo-client:v1.0.3
kipanch/yolo-backend:v1.0.3

### Version Format: MAJOR.MINOR.PATCH

v1.0.3
│ │ │
│ │ └─ PATCH: Bug fixes
│ └─── MINOR: New features
└───── MAJOR: Breaking changes

**Examples:**
- v1.0.1 - Fixed a bug
- v1.1.0 - Added new feature
- v2.0.0 - Changed API (breaking)

### Best Practices

**Good:**
image: kipanch/yolo-client:v1.0.3  (Specific version)

**Avoid in Production:**
image: kipanch/yolo-client:latest  (Unclear what version)

### Tagging Commands

# Tag image
docker tag kipanch/yolo-client:latest kipanch/yolo-client:v1.0.3

# Push to DockerHub
docker push kipanch/yolo-client:v1.0.3

---

## 8. DockerHub Deployment

### Published Images

**Repository:** https://hub.docker.com/u/kipanch

**Images:**
1. kipanch/yolo-client:v1.0.3 (14MB)
2. kipanch/yolo-backend:v1.0.3 (87.8MB)

### Screenshot

See dockerhub-deployment.png for verification showing:
- Image names
- Version tags
- Sizes
- Public visibility

### Pull Commands

# Pull latest version
docker pull kipanch/yolo-client:v1.0.3
docker pull kipanch/yolo-backend:v1.0.3

### Deployment Verification

Anyone can clone and run:

git clone <repo-url>
cd yolo
docker compose up -d
# Images automatically pulled from DockerHub

---

## Summary

### Achievements

- Image Optimization: 987MB → 101.8MB (90% reduction)
- Production Ready: Multi-stage builds, Alpine bases
- Fully Functional: All features working, data persists
- Well Documented: Clear explanations of all decisions
- Properly Versioned: Semantic versioning (v1.0.3)
- Publicly Available: Images on DockerHub

### Final Metrics

**Images:**
- Frontend: 14MB
- Backend: 87.8MB
- Total: 101.8MB (74.55% under 400MB)

**Performance:**
- Build time: ~2 minutes
- Startup time: ~10 seconds
- Memory: ~120MB total

---

Built with Docker, React, Express, and MongoDB