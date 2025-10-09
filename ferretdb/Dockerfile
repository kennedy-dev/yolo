FROM ghcr.io/ferretdb/ferretdb:latest

EXPOSE 27017

# Use PostgreSQL handler, not DocumentDB
CMD ["--listen-addr=:27017", "--handler=pg", "--postgresql-url=postgres://postgres:password@app-postgres:5432/ferretdb"]