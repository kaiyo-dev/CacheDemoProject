# ---- Build stage ----
FROM gradle:8.9-jdk17 AS build

WORKDIR /workspace

# Copy everything and build
COPY . .
RUN gradle bootJar --no-daemon

# ---- Runtime stage ----
FROM eclipse-temurin:17-jre

WORKDIR /app
COPY --from=build /workspace/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-XX:+ExitOnOutOfMemoryError", "-jar", "/app/app.jar"]
