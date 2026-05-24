# Spring PetClinic Application Inventory

## Summary
- Application: Spring PetClinic
- Language: Java
- Framework: Spring Boot 4 / Spring MVC / Thymeleaf / Spring Data JPA
- Build tool: Maven Wrapper (`./mvnw`)
- Java version: 17
- Package artifact: executable JAR built under `target/`

## Runtime Baseline
- Default runtime port: `8080`
- Health endpoint: `/actuator/health`
- Default database mode: in-memory H2
- Alternate database profiles: `mysql`, `postgres`
- H2 console: `/h2-console`

## Build And Test Commands
- Unit and integration validation: `./mvnw test`
- Local application run: `./mvnw spring-boot:run`
- Container image build via Spring plugin: `./mvnw spring-boot:build-image`

## Runtime Configuration
- `SPRING_PROFILES_ACTIVE`: selects `mysql` or `postgres` profile when needed
- `SERVER_PORT`: overrides the default application port
- `JAVA_OPTS`: JVM memory and runtime tuning
- `MYSQL_URL`, `MYSQL_USER`, `MYSQL_PASS`: MySQL profile settings
- `POSTGRES_URL`, `POSTGRES_USER`, `POSTGRES_PASS`: PostgreSQL profile settings

## Dependencies
- Embedded servlet container from Spring Boot
- Actuator endpoints enabled for development visibility
- H2 runtime dependency by default
- MySQL and PostgreSQL runtime support available
- WebJars for front-end assets

## Deployment Assumptions
- Default assessment deployment path uses containerized Spring PetClinic on Azure App Service for Containers.
- Secrets and connection data should come from Azure Key Vault via Azure DevOps variable groups.
- Production deployment should avoid exposing all actuator endpoints and should tighten ingress and egress rules.

## Evidence To Capture
- Successful local startup log
- Health endpoint response
- Docker image build output
- Azure DevOps build, scan, push, deploy, and smoke test output