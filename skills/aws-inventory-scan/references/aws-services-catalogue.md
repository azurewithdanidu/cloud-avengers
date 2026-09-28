# AWS Services Catalogue

Scan ALL of the following service categories. This list is a minimum — also discover any unlisted resources present in the account or template.

**Compute:**
- AWS Lambda (functions, layers, event source mappings)
- Amazon ECS (clusters, services, task definitions)
- Amazon EKS (clusters, node groups, add-ons)
- Amazon EC2 (instances, AMIs, security groups, key pairs)
- AWS Elastic Beanstalk (environments, configurations)

**Storage:**
- Amazon S3 (buckets, versioning, lifecycle policies, replication rules)
- Amazon EBS (volumes, snapshots)
- Amazon Glacier / S3 Glacier (archives, vaults)

**Database:**
- Amazon RDS (instances, clusters, read replicas, parameter groups)
- Amazon DynamoDB (tables, GSIs, streams, TTL, backup policies)
- Amazon ElastiCache (clusters, replication groups, parameter groups)

**Networking:**
- Amazon VPC (VPCs, subnets, route tables, internet gateways, NAT gateways)
- AWS Direct Connect (connections, virtual interfaces)
- Amazon Route 53 (hosted zones, record sets)
- Elastic Load Balancing (ALB, NLB, Classic LB — listeners, target groups, rules)
- AWS VPN (customer gateways, virtual private gateways, VPN connections)

**Messaging & Events:**
- Amazon SQS (queues, FIFO queues, DLQs, visibility timeout, message retention)
- Amazon SNS (topics, subscriptions, delivery policies)
- Amazon EventBridge (event buses, rules, targets, schedules)
- AWS Kinesis (data streams, Firehose delivery streams, analytics applications)

**Security & Access:**
- AWS IAM (roles, policies, users, groups, permission boundaries)
- AWS Secrets Manager (secrets, rotation policies)
- AWS Systems Manager Parameter Store (parameters, SecureString entries)
- AWS KMS (keys, key policies, grants, aliases)
- AWS Certificate Manager (certificates, renewal status)

**Integration & API:**
- Amazon API Gateway (REST APIs, HTTP APIs, WebSocket APIs, stages, authorizers)
- AWS AppSync (GraphQL APIs, data sources, resolvers)
- AWS Step Functions (state machines, execution history)

**Monitoring & Logging:**
- Amazon CloudWatch (log groups, log retention, dashboards, alarms, metric filters)
- AWS CloudTrail (trails, S3 destination, event selectors)
- AWS X-Ray (sampling rules, groups, service maps)

**Infrastructure as Code:**
- AWS CloudFormation (stacks, stack sets, change sets, template bodies)
- AWS CDK (identify CDK-managed stacks via `aws:cdk:path` tag)
