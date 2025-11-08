# Deno-based Dockerfile for clear_manual_overrides function
# Builds a small image that runs the TypeScript function using Deno

FROM denoland/deno:1.40.0

WORKDIR /app

# Copy function source
COPY . /app

# Cache dependencies to speed up container start
RUN deno cache index.ts

# Expose default port used by many runtimes
EXPOSE 8000

# Run with required permissions (env + network)
CMD ["run", "--allow-env", "--allow-net", "--allow-read", "index.ts"]
