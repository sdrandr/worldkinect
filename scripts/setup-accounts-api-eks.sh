#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Setup Script - Accounts API EKS Migration
# Converts Lambda-based accounts-api to EKS deployment
# ============================================================

echo "============================================================"
echo " Accounts API - EKS Migration Setup"
echo "============================================================"

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICE_DIR="${PROJECT_ROOT}/services/accounts-api"

echo ""
echo "Resolved paths:"
echo "  PROJECT_ROOT = ${PROJECT_ROOT}"
echo "  SERVICE_DIR  = ${SERVICE_DIR}"
echo ""

# Check if service directory exists
if [ ! -d "${SERVICE_DIR}" ]; then
  echo "ERROR: Service directory not found: ${SERVICE_DIR}"
  exit 1
fi

cd "${SERVICE_DIR}"

# Step 1: Backup existing files
echo ">>> [1/8] Backing up existing files..."
BACKUP_DIR="${SERVICE_DIR}/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_DIR}"

if [ -f "src/handler.ts" ]; then
  cp src/handler.ts "${BACKUP_DIR}/"
  echo "✓ Backed up handler.ts"
fi

if [ -f "webpack.config.js" ]; then
  cp webpack.config.js "${BACKUP_DIR}/"
  echo "✓ Backed up webpack.config.js"
fi

if [ -f "package.json" ]; then
  cp package.json "${BACKUP_DIR}/"
  echo "✓ Backed up package.json"
fi

echo "Backup saved to: ${BACKUP_DIR}"
echo ""

# Step 2: Remove Lambda dependencies
echo ">>> [2/8] Removing Lambda dependencies..."

if grep -q "@as-integrations/aws-lambda" package.json 2>/dev/null; then
  npm uninstall @as-integrations/aws-lambda || true
  echo "✓ Removed @as-integrations/aws-lambda"
fi

if grep -q "@types/aws-lambda" package.json 2>/dev/null; then
  npm uninstall @types/aws-lambda || true
  echo "✓ Removed @types/aws-lambda"
fi

echo ""

# Step 3: Remove Lambda-specific files
echo ">>> [3/8] Removing Lambda-specific files..."

if [ -f "src/handler.ts" ]; then
  rm -f src/handler.ts
  echo "✓ Removed src/handler.ts"
fi

if [ -f "webpack.config.js" ]; then
  rm -f webpack.config.js
  echo "✓ Removed webpack.config.js"
fi

echo ""

# Step 4: Create directory structure
echo ">>> [4/8] Creating directory structure..."

mkdir -p src
mkdir -p kubernetes
mkdir -p .github/workflows

echo "✓ Created directories"
echo ""

# Step 5: Install EKS dependencies
echo ">>> [5/8] Installing EKS dependencies..."

# Clean install
rm -rf node_modules package-lock.json

# Install core dependencies
npm install @apollo/server@^5.1.0 \
            @apollo/subgraph@^2.11.2 \
            graphql@^16.11.0 \
            graphql-tag@^2.12.6

# Install dev dependencies
npm install --save-dev \
            @types/node@^22.10.2 \
            @types/jest@^29.5.14 \
            @typescript-eslint/eslint-plugin@^8.18.1 \
            @typescript-eslint/parser@^8.18.1 \
            eslint@^8.57.1 \
            jest@^29.7.0 \
            nodemon@^3.1.7 \
            prettier@^3.4.2 \
            ts-jest@^29.2.5 \
            typescript@^5.9.3

echo "✓ Dependencies installed"
echo ""

# Step 6: Create source files
echo ">>> [6/8] Creating source files..."

# Note: Source files should be created manually or from templates
# This script creates placeholder files - you'll need to populate them

if [ ! -f "src/index.ts" ]; then
  cat > src/index.ts << 'EOF'
// TODO: Copy content from artifact "accounts-api - index.ts (EKS Entry Point)"
import { ApolloServer } from '@apollo/server';
import { startStandaloneServer } from '@apollo/server/standalone';
import { buildSubgraphSchema } from '@apollo/subgraph';
import { typeDefs } from './schema';
import { resolvers } from './resolvers';

const PORT = parseInt(process.env.PORT || '4000', 10);

const server = new ApolloServer({
  schema: buildSubgraphSchema({ typeDefs, resolvers }),
});

startStandaloneServer(server, {
  listen: { port: PORT },
}).then(({ url }) => {
  console.log(`🚀 Accounts subgraph ready at ${url}`);
});
EOF
  echo "✓ Created src/index.ts (placeholder - needs full implementation)"
fi

if [ ! -f "src/schema.ts" ]; then
  cat > src/schema.ts << 'EOF'
// TODO: Copy content from artifact "accounts-api - schema.ts"
import gql from 'graphql-tag';

export const typeDefs = gql`
  extend schema
    @link(url: "https://specs.apollo.dev/federation/v2.0", import: ["@key"])

  type Query {
    hello: String
  }
`;
EOF
  echo "✓ Created src/schema.ts (placeholder - needs full implementation)"
fi

if [ ! -f "src/resolvers.ts" ]; then
  cat > src/resolvers.ts << 'EOF'
// TODO: Copy content from artifact "accounts-api - resolvers.ts"
export const resolvers = {
  Query: {
    hello: () => 'Hello from Accounts API!',
  },
};
EOF
  echo "✓ Created src/resolvers.ts (placeholder - needs full implementation)"
fi

if [ ! -f "src/types.ts" ]; then
  touch src/types.ts
  echo "✓ Created src/types.ts (empty - needs implementation)"
fi

echo ""

# Step 7: Create Docker files
echo ">>> [7/8] Creating Docker files..."

if [ ! -f "Dockerfile" ]; then
  cat > Dockerfile << 'EOF'
# Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:20-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
USER nodejs
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/.well-known/apollo/server-health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
CMD ["node", "dist/index.js"]
EOF
  echo "✓ Created Dockerfile"
fi

if [ ! -f ".dockerignore" ]; then
  cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
dist
.git
.gitignore
.env
.env.local
.env.*.local
README.md
.vscode
.idea
*.log
coverage
.DS_Store
kubernetes
backup-*
EOF
  echo "✓ Created .dockerignore"
fi

echo ""

# Step 8: Create Kubernetes manifests
echo ">>> [8/8] Creating Kubernetes manifests..."

if [ ! -f "kubernetes/deployment.yaml" ]; then
  cat > kubernetes/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: accounts-api
  namespace: default
  labels:
    app: accounts-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: accounts-api
  template:
    metadata:
      labels:
        app: accounts-api
    spec:
      containers:
      - name: accounts-api
        image: PLACEHOLDER_ECR_IMAGE
        imagePullPolicy: Always
        ports:
        - containerPort: 4000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "4000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /.well-known/apollo/server-health
            port: 4000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /.well-known/apollo/server-health
            port: 4000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: accounts-api
  namespace: default
spec:
  type: ClusterIP
  ports:
  - port: 4000
    targetPort: 4000
  selector:
    app: accounts-api
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: accounts-api-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: accounts-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
  echo "✓ Created kubernetes/deployment.yaml"
fi

echo ""

# Summary
echo "============================================================"
echo "✓ Setup Complete!"
echo "============================================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Review and complete the source files:"
echo "   - src/index.ts"
echo "   - src/schema.ts"
echo "   - src/resolvers.ts"
echo "   - src/types.ts"
echo ""
echo "2. Test locally:"
echo "   npm run build"
echo "   npm run dev"
echo ""
echo "3. Build and test Docker image:"
echo "   npm run docker:build"
echo "   npm run docker:run"
echo ""
echo "4. Deploy to EKS:"
echo "   ./scripts/build-and-push.sh"
echo "   ./scripts/deploy-to-eks.sh"
echo ""
echo "Backup location: ${BACKUP_DIR}"
echo "============================================================"