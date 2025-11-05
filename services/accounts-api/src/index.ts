// src/index.ts
import { ApolloServer } from '@apollo/server';
import { startStandaloneServer } from '@apollo/server/standalone';
import { buildSubgraphSchema } from '@apollo/subgraph';
import { ApolloServerPluginLandingPageDisabled } from '@apollo/server/plugin/disabled';
import gql from 'graphql-tag';

// === TypeDefs ===
const typeDefs = gql`
  extend schema
    @link(url: "https://specs.apollo.dev/federation/v2.0", import: ["@key"])

  type Query {
    me: User
  }

  type User @key(fields: "id") {
    id: ID!
    username: String!
    email: String
  }
`;

// === Resolvers ===
const resolvers = {
  Query: {
    me() {
      return { id: "1", username: "demo-user", email: "demo@example.com" };
    },
  },
  User: {
    __resolveReference(user: { id: string }) {
      return { id: user.id, username: "demo-user", email: "demo@example.com" };
    },
  },
};

// === Apollo Server ===
const server = new ApolloServer({
  schema: buildSubgraphSchema({ typeDefs, resolvers }),
  introspection: true,
  csrfPrevention: false,  // ← This is the key fix for health checks!
  plugins: [
    ApolloServerPluginLandingPageDisabled(),
  ],
});

const PORT = Number(process.env.PORT) || 4000;

// === Start Server ===
startStandaloneServer(server, {
  listen: { port: PORT },
}).then(({ url }) => {
  console.log(`🚀 Accounts subgraph ready at ${url}`);
}).catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

// === Graceful Shutdown ===
process.on('SIGTERM', () => {
  console.log('SIGTERM received: shutting down...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received: shutting down...');
  process.exit(0);
});