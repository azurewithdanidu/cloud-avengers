# Validation Checklist

Before marking Phase 1 complete, every item below must pass.

## Completeness
- [ ] All AWS regions in template scanned
- [ ] All service categories checked (Compute, Storage, DB, Networking, Messaging, Security, Integration, Monitoring, IaC)
- [ ] No resources left in "Unknown" category
- [ ] All tags documented
- [ ] All configurations captured

## Accuracy
- [ ] All resource names match what is in the template (no invented names)
- [ ] All regions correct
- [ ] No duplicate resources in inventory
- [ ] All relationships are bidirectional

## Dependencies
- [ ] All forward dependencies documented
- [ ] All reverse dependencies documented
- [ ] Circular dependencies identified and flagged
- [ ] Critical path identified
- [ ] `implicit_dependencies` array populated from boto3 scan

## Output Quality
- [ ] `aws-inventory.json` is valid JSON (no syntax errors)
- [ ] `architecture-diagram.mmd` renders correctly in Mermaid (no syntax errors)
- [ ] `dependency-matrix.csv` has all 11 columns and at least one data row
- [ ] `migration-assessment.md` has `## Service Complexity Matrix` section
