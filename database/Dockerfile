FROM postgres:16-alpine

# Set default environment variables (can be overridden in docker-compose)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=ferretdb

# Expose PostgreSQL port
EXPOSE 5432

# Use official PostgreSQL entrypoint
CMD ["postgres"]