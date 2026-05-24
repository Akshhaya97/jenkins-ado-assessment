# Self-Hosted Azure DevOps Agent

## Purpose
Provide a controlled Linux-based Azure DevOps agent pool for enterprise builds, container operations, and private-network deployment paths.

## Tooling Installed
- Java 17
- Maven
- Docker CLI and engine package
- Azure CLI
- kubectl
- Helm
- Trivy
- Python 3

## Runtime Model
- Agent pool: `ado-selfhosted-linux`
- Containerized agent option for repeatable setup
- Suitable for builds that need enterprise tooling or controlled egress

## Required Environment Variables
- `AZP_URL`
- `AZP_TOKEN`
- `AZP_POOL`
- `AZP_AGENT_NAME` optional

## Network Notes
- Outbound access required to Azure DevOps service endpoints
- Outbound access to Azure login, ACR, Key Vault, and target runtime APIs
- If private endpoints are used, place the agent inside the reachable network boundary

## Operational Guidance
- Rotate PATs or replace with supported modern auth model where possible
- Rebuild the image on a patch cadence
- Treat agent images as immutable and recreate rather than patch in place