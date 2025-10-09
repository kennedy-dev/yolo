# Build stage with full Node.js
FROM node:14-alpine AS build

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm install --production

# Copy application code
COPY . .

# Production stage with minimal Alpine
FROM alpine:3.18

WORKDIR /app

# Install only Node.js runtime (no npm)
RUN apk add --no-cache nodejs

# Copy everything from build stage
COPY --from=build /usr/src/app /app

# Expose port
EXPOSE 5000

# Run the app
CMD ["node", "server.js"]