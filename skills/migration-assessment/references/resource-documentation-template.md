# Resource Documentation Template

Use this block for each resource in `migration-assessment.md`:

```markdown
## [Service Type] — [Resource Name]

**Type:** [AWS service]
**ARN:** [full ARN]
**Region:** [region]
**Criticality:** CRITICAL | HIGH | MEDIUM | LOW

### Configuration
- Key setting 1: value
- Key setting 2: value

### Dependencies
**Uses:**
- [resource name] — [relationship verb]

**Used By:**
- [resource name] — [relationship verb]

### Security
- IAM Role: [role name]
- VPC: [VPC ID] / None
- Security Groups: [sg-ids]
- Encryption: Yes (KMS key: [alias]) | No

### Costs
- Monthly Estimate: $XX.XX
- Usage metric: [invocations / GB-months / requests]

### Migration Notes
- Complexity: LOW | MEDIUM | HIGH
- Risk Flags: [list]
- Azure Equivalent: [service name]
- [Special considerations]
```
