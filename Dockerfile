# ══════════════════════════════════════════════════════════════
# Code Da Vinci — Dockerfile (Multi-stage build)
# ══════════════════════════════════════════════════════════════

# === Stage 1: Build ===
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# 1. Копируем только POM — кэшируем зависимости
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 2. Копируем исходники и собираем WAR
COPY src ./src
RUN mvn clean package -DskipTests -B

# === Stage 2: Runtime ===
FROM tomcat:11-jdk17
LABEL org.opencontainers.image.title="Code Da Vinci"
LABEL org.opencontainers.image.description="Social platform with gamification backend"
LABEL org.opencontainers.image.version="1.0-SNAPSHOT"

# Удаляем стандартные приложения Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Копируем WAR как ROOT.war (приложение на корневом контексте)
COPY --from=build /build/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Порт приложения
EXPOSE 8080

# Точка входа — стандартный запуск Tomcat
CMD ["catalina.sh", "run"]
