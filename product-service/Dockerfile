FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

COPY pom.xml .
RUN mvn -B -ntp dependency:go-offline

COPY src ./src
RUN mvn -B -ntp clean verify && cp target/product-service-*.jar /build/app.jar

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN groupadd --system app && useradd --system --gid app app
COPY --from=build --chown=app:app /build/app.jar ./app.jar

USER app
ENV SERVER_PORT=8081
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
