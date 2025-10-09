# Build stage
FROM node:14-alpine AS build

# Set the working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (use npm install instead of npm ci)
RUN npm install && npm cache clean --force

# Copy application code
COPY . .

# Build the React app
RUN npm run build

# Production stage - Use nginx to serve static files
FROM nginx:1.27-alpine-slim

# Copy built assets from build stage
COPY --from=build /usr/src/app/build /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]