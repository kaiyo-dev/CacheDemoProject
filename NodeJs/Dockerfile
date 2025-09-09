# Multi-stage Dockerfile for Node.js app (using Debian slim variant)
FROM node:20.16.0-bookworm-slim AS base
WORKDIR /usr/src/app

# Install prod dependencies first for layer caching
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

# Dev dependencies (optional; enables running tests/build if added later)
FROM node:20.16.0-bookworm-slim AS dev-deps
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install && npm cache clean --force

# If you had a build step (e.g., TypeScript) it would run here
# COPY . .
# RUN npm run build

# Runtime image
FROM node:20.16.0-bookworm-slim AS runtime
WORKDIR /usr/src/app

# Create non-root user (node user already exists but ensure directory ownership)
RUN usermod -d /usr/src/app node && chown -R node:node /usr/src/app

# Copy only production dependencies
COPY --from=base /usr/src/app/node_modules ./node_modules

# Copy application source
COPY . .
RUN chown -R node:node /usr/src/app

USER node
ENV NODE_ENV=production
EXPOSE 3000

# Default entrypoint (adjust if different main file)
CMD ["node", "index.js"]
