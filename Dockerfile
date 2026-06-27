# ══════════════════════════════════════════════════════════════
# Code Da Vinci — Dockerfile (single-stage, pre-built WAR)
#
# WAR собирается локально командой:
#   mvn clean package -DskipTests
#
# Затем запускать:
#   docker compose up --build -d
# ══════════════════════════════════════════════════════════════

FROM tomcat:11-jdk17

LABEL org.opencontainers.image.title="Code Da Vinci"
LABEL org.opencontainers.image.description="Social platform with gamification backend"
LABEL org.opencontainers.image.version="1.0-SNAPSHOT"

# Удаляем стандартные приложения Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Копируем предварительно собранный WAR как ROOT.war
COPY target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Порт приложения
EXPOSE 8080

# Точка входа — стандартный запуск Tomcat
CMD ["catalina.sh", "run"]
