# Service Catalog — Filter Reference

Quick-reference starting queries for common Azure services. All examples use `australiaeast`; substitute your deployment region.

## Compute

| Service | Starting filter |
|---|---|
| Functions — Premium (EP1/EP2/EP3) | `productName eq 'Premium Functions' and armRegionName eq '<region>'` |
| Functions — Flex Consumption | `contains(productName,'Flex Consumption') and armRegionName eq '<region>'` |
| Functions — Consumption (pay-per-call) | `productName eq 'Functions' and armRegionName eq '<region>'` |
| App Service (Basic/Standard/Premium) | `serviceName eq 'Azure App Service' and armRegionName eq '<region>'` |
| Container Apps | `contains(productName,'Container Apps') and armRegionName eq '<region>'` |
| Azure Kubernetes Service (AKS) | `serviceName eq 'Azure Kubernetes Service' and armRegionName eq '<region>'` |
| Azure Container Instances | `serviceName eq 'Container Instances' and armRegionName eq '<region>'` |
| Virtual Machines (e.g. D2s_v3) | `serviceName eq 'Virtual Machines' and armRegionName eq '<region>' and contains(skuName,'D2s')` |
| Azure Batch | `serviceName eq 'Azure Batch' and armRegionName eq '<region>'` |

## Storage

| Service | Starting filter |
|---|---|
| Blob Storage — Hot LRS | `contains(productName,'Blob Storage') and skuName eq 'Hot LRS' and armRegionName eq '<region>'` |
| Blob Storage — Cool LRS | `contains(productName,'Blob Storage') and skuName eq 'Cool LRS' and armRegionName eq '<region>'` |
| Blob Storage — Archive LRS | `contains(productName,'Blob Storage') and skuName eq 'Archive LRS' and armRegionName eq '<region>'` |
| Azure Files — LRS | `contains(productName,'Azure Files') and contains(skuName,'LRS') and armRegionName eq '<region>'` |
| Azure Data Lake Storage Gen2 | `contains(productName,'Azure Data Lake Storage') and armRegionName eq '<region>'` |
| Azure Disk (Managed — P10/P20/P30) | `serviceName eq 'Storage' and contains(skuName,'P10') and armRegionName eq '<region>'` |
| Azure NetApp Files | `serviceName eq 'Azure NetApp Files' and armRegionName eq '<region>'` |

## Databases

| Service | Starting filter |
|---|---|
| Azure SQL Database (General Purpose) | `contains(productName,'SQL Database') and contains(skuName,'General Purpose') and armRegionName eq '<region>'` |
| Azure SQL Database (Business Critical) | `contains(productName,'SQL Database') and contains(skuName,'Business Critical') and armRegionName eq '<region>'` |
| Azure SQL Managed Instance | `contains(productName,'SQL Managed Instance') and armRegionName eq '<region>'` |
| Azure Database for PostgreSQL Flexible | `contains(productName,'Azure Database for PostgreSQL') and contains(skuName,'Flexible') and armRegionName eq '<region>'` |
| Azure Database for MySQL Flexible | `contains(productName,'Azure Database for MySQL') and armRegionName eq '<region>'` |
| Azure Cosmos DB (NoSQL) | `contains(productName,'Cosmos DB') and armRegionName eq '<region>'` |
| Azure Cache for Redis | `contains(productName,'Cache for Redis') and armRegionName eq '<region>'` |
| Azure SQL Elastic Pool | `contains(productName,'SQL Database Elastic Pool') and armRegionName eq '<region>'` |

## Networking

| Service | Starting filter |
|---|---|
| Private Endpoint (Virtual Network Private Link) | `contains(productName,'Private Link') and currencyCode eq 'USD'` |
| Azure DNS Private Zones | `contains(productName,'DNS') and armRegionName eq '<region>'` |
| Azure Front Door (Standard/Premium) | `contains(productName,'Azure Front Door') and currencyCode eq 'USD'` |
| Azure Application Gateway (v2) | `contains(productName,'Application Gateway') and armRegionName eq '<region>'` |
| Azure Load Balancer (Standard) | `contains(productName,'Load Balancer') and armRegionName eq '<region>'` |
| Azure VPN Gateway | `contains(productName,'VPN Gateway') and armRegionName eq '<region>'` |
| Azure ExpressRoute | `contains(productName,'ExpressRoute') and armRegionName eq '<region>'` |
| Azure Firewall | `contains(productName,'Azure Firewall') and armRegionName eq '<region>'` |
| Azure DDoS Protection Standard | `contains(productName,'DDoS') and armRegionName eq '<region>'` |
| Azure NAT Gateway | `contains(productName,'NAT Gateway') and armRegionName eq '<region>'` |
| Azure CDN | `contains(productName,'CDN') and currencyCode eq 'USD'` |
| Azure Bastion | `contains(productName,'Bastion') and armRegionName eq '<region>'` |
| Outbound Data Transfer | `contains(productName,'Bandwidth') and armRegionName eq '<region>'` |

## AI / Machine Learning

| Service | Starting filter |
|---|---|
| Azure OpenAI (GPT-4o, GPT-4, etc.) | `serviceName eq 'Azure OpenAI' and currencyCode eq 'USD'` |
| Azure AI Services (Cognitive Services) | `serviceName eq 'Cognitive Services' and armRegionName eq '<region>'` |
| Azure Machine Learning compute | `contains(productName,'Azure Machine Learning') and armRegionName eq '<region>'` |
| Azure AI Search | `contains(productName,'Search') and armRegionName eq '<region>'` |
| Azure AI Document Intelligence | `contains(productName,'Form Recognizer') and armRegionName eq '<region>'` |

## Integration & Messaging

| Service | Starting filter |
|---|---|
| Azure Service Bus (Standard/Premium) | `contains(productName,'Service Bus') and armRegionName eq '<region>'` |
| Azure Event Hubs | `contains(productName,'Event Hubs') and armRegionName eq '<region>'` |
| Azure Event Grid | `contains(productName,'Event Grid') and armRegionName eq '<region>'` |
| Azure API Management | `contains(productName,'API Management') and armRegionName eq '<region>'` |
| Azure Logic Apps | `contains(productName,'Logic Apps') and armRegionName eq '<region>'` |
| Azure Data Factory | `contains(productName,'Data Factory') and armRegionName eq '<region>'` |

## Security & Identity

| Service | Starting filter |
|---|---|
| Azure Key Vault (Standard) | `contains(productName,'Key Vault') and armRegionName eq '<region>'` |
| Azure Key Vault (Premium — HSM) | `contains(productName,'Key Vault') and contains(skuName,'Premium') and armRegionName eq '<region>'` |
| Azure Managed HSM | `contains(productName,'Managed HSM') and armRegionName eq '<region>'` |
| Microsoft Entra ID P1/P2 | `contains(productName,'Azure Active Directory') and currencyCode eq 'USD'` |
| Microsoft Defender for Cloud | `contains(productName,'Defender') and armRegionName eq '<region>'` |

## Management & Monitoring

| Service | Starting filter |
|---|---|
| Log Analytics (Pay-per-GB) | `contains(productName,'Log Analytics') and armRegionName eq '<region>'` |
| Application Insights (workspace-based) | Billed via Log Analytics — no separate meter |
| Azure Monitor Metrics | `contains(productName,'Azure Monitor') and armRegionName eq '<region>'` |
| Azure Automation | `contains(productName,'Automation') and armRegionName eq '<region>'` |
| Azure Backup | `contains(productName,'Backup') and armRegionName eq '<region>'` |
| Azure Site Recovery | `contains(productName,'Site Recovery') and armRegionName eq '<region>'` |

## Developer Tools & DevOps

| Service | Starting filter |
|---|---|
| Azure Static Web Apps | `contains(productName,'Static Web') and currencyCode eq 'USD'` |
| Azure Container Registry | `contains(productName,'Container Registry') and armRegionName eq '<region>'` |
| Azure DevOps (Pipelines, Artifacts) | `contains(productName,'Azure DevOps') and currencyCode eq 'USD'` |
| GitHub Actions (if on Azure billing) | Not in Retail Prices API — use GitHub billing |
