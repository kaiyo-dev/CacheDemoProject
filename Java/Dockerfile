# Multi-stage Dockerfile for Spring Boot application
# Build stage
FROM openjdk:17 AS build

WORKDIR /workspace

# Copy Gradle wrapper and build scripts first (better layer caching)
COPY build.gradle settings.gradle gradlew ./
COPY gradle/ ./gradle/

# Ensure wrapper is executable (Linux containers)
RUN chmod +x gradlew

# Download dependencies (will cache unless build files change)
# RUN ./gradlew --no-daemon dependencies || true

# Copy application source
COPY src ./src

# Build fat jar (Spring Boot)
RUN ./gradlew clean bootJar

# Runtime stage
FROM eclipse-temurin:17-jre AS runtime

# (Optional) locale / tzdata can be installed if needed
# RUN microdnf install -y tzdata && microdnf clean all

WORKDIR /app

# Copy built jar from build stage
COPY --from=build /workspace/build/libs/*-SNAPSHOT.jar app.jar

# Non-root user for security
RUN useradd -u 10001 spring
USER spring

EXPOSE 8080

# JVM tuning basics (adjust as needed)
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
