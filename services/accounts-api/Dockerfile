FROM node:20-alpine AS builder

# Build stage - compiles TypeScript
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies for building)
# Use npm install instead of npm ci (no package-lock.json)
RUN npm install

# Copy source code
COPY src ./src
COPY tsconfig.json ./

# Build TypeScript to JavaScript
RUN npm run build

# Production stage - runs the app
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm install --omit=dev

# Copy compiled JavaScript from builder stage
COPY --from=builder /app/dist ./dist

# Expose port
EXPOSE 4000

# Set environment
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/.well-known/apollo/server-health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run the app
CMD ["node", "dist/index.js"]