# Existing Application Inventory And Target Architecture

## Application Inventory

### Summary

- Application: Spring PetClinic
- Maven coordinates: `org.springframework.samples:spring-petclinic:4.0.0-SNAPSHOT`
- Language: Java
- Framework stack: Spring Boot `4.0.3` / Spring MVC / Thymeleaf / Spring Data JPA / Actuator
- Runtime version: Java `17`
- Build tool: Maven Wrapper (`./mvnw`)
- Package artifact: executable JAR generated under `target/`
- Detailed application inventory is maintained in `apps/spring-petclinic/app-inventory.md`

### Technology And Version Inventory

- Spring Boot parent: `4.0.3`
- Java version: `17`
- Build container image: `maven:3.9.11-eclipse-temurin-17`
- Runtime container image: `eclipse-temurin:17-jre-jammy`
- Local ingress image: `nginx:1.27-alpine`
- Local database image: `mysql:9.1`
- Front-end assets: WebJars Bootstrap `5.3.8`, Font Awesome `4.7.0`

### Runtime Baseline

- Runtime port: `8080`
- Health endpoint: `/actuator/health`
- Default database mode: in-memory H2
- Database initialization property: `database=h2`
- Alternate database profiles: `mysql`, `postgres`
- H2 console: `/h2-console`
- Actuator exposure in the current local configuration: `management.endpoints.web.exposure.include=*`

### Build And Test Steps

- Dependency warm-up: `./mvnw -q -DskipTests dependency:go-offline`
- Test command: `./mvnw test`
- Package command: `./mvnw test package`
- Local run command: `./mvnw spring-boot:run`
- Container build source: multi-stage Docker build from `apps/container/Dockerfile`

### Runtime Configuration

- `SERVER_PORT`: application port override
- `SPRING_PROFILES_ACTIVE`: selects runtime profile such as `mysql` or `postgres`
- `JAVA_OPTS`: JVM runtime and memory tuning
- `MYSQL_URL`, `MYSQL_USER`, `MYSQL_PASS`: MySQL runtime settings
- `POSTGRES_URL`, `POSTGRES_USER`, `POSTGRES_PASS`: PostgreSQL runtime settings

### External Dependencies

- Embedded servlet container provided by Spring Boot
- H2 database for default local runtime mode
- MySQL for container-based local validation
- PostgreSQL as an alternate supported profile
- Actuator for health and runtime visibility
- WebJars for front-end static assets


### Deployment Assumptions

- The current application is a Java Spring Boot service packaged as an executable JAR.
- The codebase supports local execution with embedded H2 and profile-based execution with MySQL or PostgreSQL.
- Container artifacts and docker-compose assets in this repository are assessment enablement assets, not evidence of the legacy production hosting model.


## Current State Architecture

- Developer changes flow into source control hosted in GitHub and GitLab.
- Legacy CI/CD execution is split across Jenkins, Bamboo, and GitLab CI.
- Legacy pipelines publish container artifacts to a legacy container registry.
- Application workloads are hosted on virtual machines.
- The primary stateful dependency is an on-prem MySQL database.
- Credentials and release automation are distributed across legacy CI/CD tooling and scripts.

## Target State Architecture

- Source in GitHub or Azure Repos with branch protection and PR validation
- Azure DevOps Pipelines as the target CI/CD platform
- Self-hosted agent pool for enterprise tooling and controlled network access
- Azure Container Registry for immutable image storage
- Azure App Service for Containers as the default runtime target
- Azure Key Vault-backed variable groups for secrets
- Azure Monitor, Log Analytics, and Application Insights for observability

## Ingress Path

User -> Azure ingress endpoint -> App Service for Containers -> Spring PetClinic -> `/actuator/health`

## Egress Path

Spring PetClinic -> database service
Spring PetClinic -> external dependency endpoints
Spring PetClinic -> package and container registry services during build and deployment stages

## Security Controls

- TLS termination at ingress
- Key Vault for secrets
- Least-privilege Azure service connection
- Environment approvals for production
- Egress allow-listing for runtime and build dependencies

## Local Demo Mapping

- Local NGINX simulates ingress
- Local MySQL simulates the stateful dependency
- Local mock-external service simulates the outbound dependency
