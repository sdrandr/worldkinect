const { ApolloServer, gql } = require('apollo-server');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const typeDefs = gql`
  type FuelInventory {
    id: ID!
    type: String
    quantity: Float
    price: Float
  }
  type Query {
    getInventory: [FuelInventory]
  }
`;

const resolvers = {
  Query: {
    getInventory: async () => {
      const client = await pool.connect();
      const res = await client.query('SELECT * FROM inventory');
      client.release();
      return res.rows;
    }
  }
};

const server = new ApolloServer({ typeDefs, resolvers });
server.listen({ port: 4000 }).then(({ url }) => console.log(`Energy API at ${url}`));