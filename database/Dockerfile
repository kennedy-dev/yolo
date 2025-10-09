FROM alpine:3.18

# Install MongoDB
RUN apk add --no-cache mongodb mongodb-tools

# Create MongoDB user and directories
RUN mkdir -p /data/db && \
    chown -R mongodb:mongodb /data/db

# Switch to mongodb user
USER mongodb

# Set working directory
WORKDIR /data/db

# Expose port
EXPOSE 27017

# Start MongoDB with all settings as flags
CMD ["mongod", "--dbpath=/data/db", "--bind_ip=0.0.0.0", "--port=27017"]