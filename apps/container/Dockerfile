# Starting a build environment
FROM maven:3.9.11-eclipse-temurin-17 AS build
WORKDIR /workspace

# Layer Caching
COPY apps/spring-petclinic/pom.xml ./pom.xml
COPY apps/spring-petclinic/.mvn ./.mvn
COPY apps/spring-petclinic/mvnw ./mvnw
RUN chmod +x mvnw && ./mvnw -q -DskipTests dependency:go-offline

# Test and package
COPY apps/spring-petclinic/src ./src
RUN ./mvnw -q test package

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN useradd --create-home --uid 10001 springuser

COPY --from=build /workspace/target/*.jar /app/app.jar

ENV SERVER_PORT=8080
ENV SPRING_PROFILES_ACTIVE=mysql
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:InitialRAMPercentage=50"

EXPOSE 8080
USER springuser

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dserver.port=$SERVER_PORT -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE -jar /app/app.jar"]