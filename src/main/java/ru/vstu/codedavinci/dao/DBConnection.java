package ru.vstu.codedavinci.dao;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * Управляет пулом соединений с PostgreSQL через HikariCP.
 *
 * <p>Параметры подключения читаются из переменных окружения (или .env).</p>
 *
 * <pre>
 *   DB_URL      — JDBC URL (по умолчанию jdbc:postgresql://localhost:5432/course_project)
 *   DB_USER    — имя пользователя БД (по умолчанию app_user)
 *   DB_PASSWORD — пароль (по умолчанию 1234)
 *   DB_POOL_SIZE — размер пула (по умолчанию 10)
 * </pre>
 */
public class DBConnection {

    private static final HikariDataSource dataSource;

    static {
        HikariConfig config = new HikariConfig();

        config.setJdbcUrl(
                System.getenv().getOrDefault("DB_URL",
                        "jdbc:postgresql://localhost:5432/course_project"));
        config.setUsername(
                System.getenv().getOrDefault("DB_USER", "app_user"));
        config.setPassword(
                System.getenv().getOrDefault("DB_PASSWORD", "1234"));

        int poolSize = parseIntOrDefault(System.getenv("DB_POOL_SIZE"), 10);
        config.setMaximumPoolSize(poolSize);
        config.setMinimumIdle(2);
        config.setConnectionTimeout(5_000);
        config.setIdleTimeout(300_000);
        config.setMaxLifetime(600_000);

        config.setDriverClassName("org.postgresql.Driver");

        // Валидация соединений
        config.setConnectionTestQuery("SELECT 1");

        dataSource = new HikariDataSource(config);
    }

    /**
     * Возвращает соединение из пула HikariCP.
     *
     * @return соединение с PostgreSQL
     * @throws SQLException если все соединения в пуле исчерпаны или БД недоступна
     */
    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    /**
     * Закрывает пул соединений. Вызывать только при завершении приложения.
     */
    public static void closePool() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
        }
    }

    private static int parseIntOrDefault(String value, int defaultValue) {
        if (value == null) return defaultValue;
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}