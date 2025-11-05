// src/schema.ts
import { gql } from "graphql-tag";
import { IResolvers } from "@graphql-tools/utils";

export const typeDefs = gql`
  type Query {
    me: User
    customer(id: ID!): Customer
  }

  type User {
    id: ID!
    email: String!
    name: String
  }

  type Customer {
    id: ID!
    name: String!
    status: String!
    creditLimit: Float
  }
`;

export interface User {
  id: string;
  email: string;
  name?: string;
}

export interface Customer {
  id: string;
  name: string;
  status: string;
  creditLimit?: number;
}

// In a real system this would call RDS/DynamoDB/etc.
const mockCustomers: Customer[] = [
  { id: "CUST-1001", name: "Acme Logistics", status: "ACTIVE", creditLimit: 100000 },
  { id: "CUST-2001", name: "Global Retail Corp", status: "ON_HOLD", creditLimit: 25000 },
];

export const resolvers: IResolvers = {
  Query: {
    me: async (): Promise<User> => {
      // Later: derive from auth claims (Cognito/JWT)
      return {
        id: "USER-1",
        email: "demo.user@example.com",
        name: "Demo User",
      };
    },
    customer: async (_parent, args: { id: string }): Promise<Customer | null> => {
      return mockCustomers.find(c => c.id === args.id) ?? null;
    },
  },
};
