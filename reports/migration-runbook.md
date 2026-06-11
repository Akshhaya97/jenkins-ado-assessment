# Migration Runbook

## Objective
Execute a repeatable migration pattern from legacy CI/CD tooling to Azure DevOps for a containerized Spring PetClinic workload.

## Sequence
1. Baseline the source application and capture inventory.
2. Containerize the application and validate local ingress and egress.
3. Inventory legacy pipelines and produce the migration mapping matrix.
4. Provision Azure target resources through IaC.
5. Register and validate the self-hosted Azure DevOps agent.
6. Configure Key Vault-backed variable groups and service connections.
7. Run Azure DevOps pipeline through build, test, scan, push, deploy, and smoke test.
8. Capture deployment evidence, monitoring evidence, and rollback evidence.
9. Finalize Jira readiness analysis, governance controls, and presentation artifacts.

## Roles
- DevOps engineer: implementation owner
- Platform owner: service connection and RBAC approver
- Release manager: production approval owner
- Application owner: smoke test and validation owner

## Evidence Checklist
- Local run output
- Docker build output
- Inventory report
- Azure pipeline logs
- ACR image tag evidence
- Deployment endpoint and health response