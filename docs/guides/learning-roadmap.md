WorldKinect Tech Stack Learning Roadmap
Goal: Build skills matching WorldKinect's developer productivity and platform engineering stack

Date Created: November 4, 2025

Current State Assessment
✅ Strengths
Starting with Lambda + TypeScript + ApolloQL
AWS infrastructure knowledge
Multi-tech background (good foundation)
Experience with service layer and data engineering
🔄 Areas to Develop
New to npm/TypeScript ecosystem
Apollo Federation patterns
CI/CD pipeline implementation
Infrastructure as Code practices
Job Description Key Requirements
Core Technical Skills (Priority 1)
TypeScript + GraphQL - Building high-performance APIs
API Design - RESTful + GraphQL patterns
Apollo Server - Federation, resolvers, schema design
AWS Lambda - Serverless architecture
CI/CD Pipelines - Jenkins, GitHub Actions, GitLab CI
Infrastructure as Code (IaC) - Terraform, CloudFormation
Developer Productivity Tools (Priority 2)
Containerization - Docker, ECS/EKS
Developer Tooling - Local dev environments, debugging
Monitoring/Observability - CloudWatch, DataDog, New Relic
Security Practices - IAM, secrets management, vulnerability scanning
Soft Skills (Priority 3)
Documentation - Technical writing, best practices guides
Code Reviews - Mentoring, quality standards
Cross-Team Collaboration - Architecture discussions, stakeholder communication
Phase 1: Foundation (2-3 months)
Week 1-2: TypeScript Basics
Learning Objectives:

Build simple Lambda functions
Master TypeScript types, interfaces, generics
Practice async/await patterns
Error handling and type safety
Exercises:

Create Lambda function with proper TypeScript types
Build utility functions with generics
Handle promises and async operations
Success Criteria:

Can write type-safe Lambda functions
Understand TypeScript compilation
Comfortable with async patterns
Week 3-4: GraphQL Fundamentals
Learning Objectives:

Schema design (types, queries, mutations)
Resolver implementation
Apollo Server setup
Data source integration
Exercises:

Design GraphQL schema for a domain (e.g., customers)
Implement queries and mutations
Connect to data sources (RDS, DynamoDB)
Handle errors in resolvers
Success Criteria:

Can design effective GraphQL schemas
Understand resolver patterns
Can integrate multiple data sources
Week 5-6: Apollo Federation
Learning Objectives:

Subgraph architecture
Schema composition
Gateway setup
Federation directives (@key, @extends)
Exercises:

Split monolithic schema into subgraphs
Set up Apollo Gateway
Implement entity resolution
Handle cross-subgraph queries
Success Criteria:

Understand federated architecture
Can build and compose subgraphs
Gateway successfully routes queries
Week 7-8: React + GraphQL Client
Learning Objectives:

Apollo Client setup
Queries/mutations from React
Cache management
Optimistic UI updates
Exercises:

Build React app consuming GraphQL API
Implement queries with useQuery hook
Handle mutations with useMutation
Manage local and remote state
Success Criteria:

Full-stack TypeScript + GraphQL + React application
Efficient data fetching and caching
Good user experience patterns
Phase 1 Project: Customer Management System
Description: Build a simple "Customer Management" API similar to what WorldKinect does with clients

Components:

Lambda functions with TypeScript
GraphQL API with Apollo Federation
React frontend consuming the API
Basic authentication
CRUD operations
Technology Stack:

AWS Lambda
Apollo Server + Federation
React + Apollo Client
TypeScript
DynamoDB or RDS
Deliverables:

Working API with multiple subgraphs
React frontend with data display
Basic documentation
GitHub repository
Phase 2: DevOps Practices (3-4 months)
CI/CD Pipeline Implementation
Learning Objectives:

GitHub Actions or GitLab CI
Automated testing
Deployment automation
Environment management (dev/staging/prod)
Key Concepts:

Pipeline stages (build, test, deploy)
Artifact management
Environment promotion
Rollback strategies
Exercises:

Create GitHub Actions workflow
Implement automated tests in pipeline
Deploy to multiple AWS environments
Set up approval gates for production
Success Criteria:

Fully automated deployment pipeline
Tests run automatically on PR
Zero-downtime deployments
Infrastructure as Code
Learning Objectives:

Terraform fundamentals
AWS resource provisioning
State management
Module creation
Workspace management
Key Resources:

Lambda functions
API Gateway
RDS/DynamoDB
S3 buckets
IAM roles and policies
CloudWatch logs
Exercises:

Write Terraform modules for common patterns
Provision complete environments
Implement remote state with S3
Create reusable modules
Success Criteria:

Can provision entire stack via Terraform
Understand state management
Can create and manage multiple environments
Containerization
Learning Objectives:

Docker fundamentals
Multi-stage builds
Docker Compose for local development
ECS/EKS deployment
Exercises:

Dockerize TypeScript applications
Create Docker Compose for local stack
Deploy containers to ECS
Set up container orchestration
Success Criteria:

Applications run in containers
Local development mirrors production
Container deployment automated
Phase 2 Project: Fully Automated Deployment Pipeline
Description: Build complete CI/CD pipeline with IaC

Components:

GitHub Actions workflow
Terraform for all infrastructure
Automated testing (unit, integration)
Multi-environment deployment
Monitoring and alerts
Deliverables:

Working CI/CD pipeline
Terraform modules for all resources
Documentation for deployment process
Runbook for common operations
Phase 3: Developer Productivity (2-3 months)
Developer Experience
Learning Objectives:

Local development setup best practices
Hot reload / watch modes
Mock services for testing
Developer documentation
Key Tools:

Docker Compose for local stack
LocalStack for AWS services
Nodemon for hot reload
Swagger/GraphQL Playground
Exercises:

Create seamless local dev environment
Build mock data generators
Document setup process
Create troubleshooting guides
Success Criteria:

New developer can set up in < 30 minutes
Local development mirrors production
Clear documentation available
Observability
Learning Objectives:

CloudWatch logs and metrics
Application performance monitoring
Distributed tracing
Error tracking and alerting
Key Concepts:

Structured logging
Custom metrics
Trace correlation
SLA/SLO monitoring
Exercises:

Implement structured logging
Create CloudWatch dashboards
Set up distributed tracing
Configure alerts for critical metrics
Success Criteria:

Full visibility into application behavior
Quick issue identification
Proactive monitoring in place
Security
Learning Objectives:

AWS IAM best practices
Secrets Manager integration
OWASP security practices
Dependency scanning
Security testing
Key Practices:

Principle of least privilege
Secret rotation
Vulnerability scanning
Security headers
Input validation
Exercises:

Implement proper IAM roles
Migrate hardcoded secrets to Secrets Manager
Set up dependency scanning in CI/CD
Conduct security review
Success Criteria:

No secrets in code
Proper IAM policies
Automated security scanning
Security best practices documented
Phase 3 Project: Developer Portal/Platform
Description: Create internal developer productivity platform

Features:

Self-service infrastructure provisioning
Documentation hub
Monitoring dashboards
Onboarding guides
Code templates and generators
Technology:

React frontend
GraphQL API for operations
Terraform for provisioning
CloudWatch for monitoring
GitHub for documentation
Deliverables:

Working developer portal
Infrastructure templates
Complete documentation
Onboarding materials
Immediate Next Steps (This Week)
1. Finish Current Apollo + Lambda Setup
 Get federated GraphQL working
 Deploy to AWS successfully
 Test all endpoints
 Document API
2. Add React Frontend
 Create simple React app
 Set up Apollo Client
 Query GraphQL endpoint
 Display data from API
3. Set Up Local Development
 Docker Compose for local Lambda
 Hot reload for TypeScript
 Mock data for testing
 Environment configuration
4. Create Documentation
 README with setup instructions
 Architecture diagram
 API documentation
 Troubleshooting guide
WorldKinect Architecture Pattern
Build a mini version of their enterprise stack:

┌─────────────────────────────────────┐
│         React Application           │
│      (Users interact here)          │
└──────────────┬──────────────────────┘
               │ Apollo Client
               ▼
┌─────────────────────────────────────┐
│   API Gateway + Apollo Gateway      │
│    (GraphQL Federation Layer)       │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│Accounts │ │Products │ │ Orders  │
│Subgraph │ │Subgraph │ │Subgraph │
│(Lambda) │ │(Lambda) │ │(Lambda) │
└────┬────┘ └────┬────┘ └────┬────┘
     │           │           │
     ▼           ▼           ▼
  [RDS]      [DynamoDB]  [S3/API]
Key Characteristics:

Microservices architecture
Federation for schema composition
Serverless compute (Lambda)
Multiple data sources
Type-safe end-to-end (TypeScript)
Portfolio Project: Client Portal
Description: Enterprise-grade client portal demonstrating all learned skills

Features
Authentication
User login/logout
JWT tokens
Role-based access control
Account Management
View account details
Update profile
Manage preferences
Order Management
Browse products
Submit orders
Track order status
Analytics Dashboard
Usage metrics
Performance charts
Custom reports
Technical Implementation
Frontend:

React + TypeScript
Apollo Client
Material-UI or Tailwind
Authentication flow
Responsive design
Backend:

Apollo Federation (3+ subgraphs)
Lambda functions
Multiple data sources
Authentication service
Authorization middleware
Infrastructure:

Terraform for all resources
CI/CD pipeline
Multi-environment (dev/staging/prod)
Monitoring and logging
Security best practices
DevOps:

GitHub Actions
Automated testing
Blue/green deployments
Rollback capability
Infrastructure versioning
Success Criteria
 Production-ready code quality
 Complete documentation
 Automated deployments
 Monitoring and alerting
 Security hardened
 Performance optimized
Essential Resources
TypeScript + GraphQL
Apollo Documentation: https://www.apollographql.com/docs/apollo-server/
TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/
GraphQL Best Practices: https://graphql.org/learn/best-practices/
Apollo Federation Guide: https://www.apollographql.com/docs/federation/
AWS
AWS Well-Architected Framework
Serverless Patterns Collection
Lambda Best Practices
AWS CDK Documentation (alternative to Terraform)
Infrastructure as Code
Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/
Terraform Best Practices
AWS CloudFormation Documentation
CI/CD
GitHub Actions Documentation
AWS CodePipeline Examples
GitLab CI/CD Guide
Security
OWASP Top 10
AWS Security Best Practices
Secrets Management Patterns
Developer Productivity
12-Factor App Methodology
Developer Experience Best Practices
Platform Engineering Principles
Skills Tracking Matrix
Core Engineering
Skill	Beginner	Intermediate	Advanced	Expert
TypeScript	☐	☐	☐	☐
GraphQL	☐	☐	☐	☐
Apollo Federation	☐	☐	☐	☐
React	☐	☐	☐	☐
AWS Lambda	☐	☐	☐	☐
DevOps
Skill	Beginner	Intermediate	Advanced	Expert
Terraform	☐	☐	☐	☐
CI/CD Pipelines	☐	☐	☐	☐
Docker	☐	☐	☐	☐
Kubernetes	☐	☐	☐	☐
Platform Engineering
Skill	Beginner	Intermediate	Advanced	Expert
Monitoring	☐	☐	☐	☐
Security	☐	☐	☐	☐
Documentation	☐	☐	☐	☐
Developer Tools	☐	☐	☐	☐
Timeline Summary
Total Duration: 7-10 months to proficiency

Phase 1 (Foundation): 2-3 months
Phase 2 (DevOps): 3-4 months
Phase 3 (Productivity): 2-3 months
Realistic Timeline:

Part-time learning: 10-12 months
Full-time focus: 6-8 months
With existing experience: 5-7 months
Success Metrics
Technical Proficiency
 Can build and deploy full-stack TypeScript applications
 Comfortable with GraphQL Federation patterns
 Terraform infrastructure from scratch
 CI/CD pipelines without assistance
 Security best practices implemented
Project Completion
 Phase 1 project deployed to production
 Phase 2 project with full automation
 Phase 3 developer platform running
 Portfolio project complete
Professional Readiness
 GitHub portfolio with quality projects
 Technical blog posts or documentation
 Can discuss architecture decisions
 Ready for technical interviews
 Confident in WorldKinect tech stack
Notes & Reflections
Current Progress:

Challenges Encountered:

Key Learnings:

Next Milestones:

This roadmap is a living document. Update it regularly as you progress and adjust based on your learning pace and interests.

