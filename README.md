# Code Da Vinci — Социальная платформа с RPG-геймификацией

Бэкенд веб-приложения, объединяющего социальную сеть с игровыми механиками. Пользователи создают профили, заводят друзей, зарабатывают опыт (XP), получают достижения, соревнуются в рейтинге популярности и приглашают друзей по реферальным ссылкам. Реализован на Jakarta EE (сервлеты + JSP) без сторонних фреймворков — вся бизнес-логика написана на чистом JDBC.

---

## 🛠 Технологический стек

При проектировании архитектуры приложения упор делался на модульность и надежность хранения данных.

*   **Язык разработки:** Java 17
*   **Фреймворки:** Jakarta Servlet / JSP / JSTL 6.1 / 4.0 / 3.0
*   **Базы данных:** PostgreSQL 16+
*   **Кэширование и очереди:** HikariCP (connection pool)
*   **Контейнеризация и DevOps:** Docker, Docker Compose, Apache Tomcat 11
*   **Инструменты тестирования:** JUnit (планируется)

---

## 🚀 Ключевой функционал

Система оцифровывает и автоматизирует следующие бизнес-процессы:

*   **Управление пользователями:** Регистрация с валидацией email и пароля, аутентификация по сессии (BCrypt-хеширование), редактирование профиля
*   **Автоматизация логики:** Система опыта и уровней (level = floor(sqrt(XP / 100))), 18 достижений, рейтинг популярности
*   **Интеграции:** Реферальная система (UUID-код), API прогресса с процентами до следующего уровня
*   **Валидация и безопасность:** BCrypt (cost 12), защита от XSS, дедупликация просмотров профиля (не чаще 1 раза в час с одного IP)

---

## 📁 Архитектура и структура проекта

В проекте используется слоистая архитектура (Presentation → Service → DAO). Это обеспечивает независимость бизнес-логики от внешних библиотек и баз данных.

```text
code-da-vinci/
├── pom.xml                        # Зависимости, сборка Maven
├── Dockerfile                     # Многостадийная сборка → Tomcat 11
├── docker-compose.yml             # PostgreSQL + приложение
├── .env.example                   # Шаблон переменных окружения
├── .gitignore                     # Игнорируемые файлы
├── sql/
│   └── schema.sql                 # DDL + seed-данные (achievements, interests)
├── src/main/
│   ├── java/ru/vstu/codedavinci/
│   │   ├── dao/                   # Data Access Layer (8 DAO-классов)
│   │   ├── dto/                   # Data Transfer Objects
│   │   ├── filter/                # Фильтры (SecurityHeadersFilter)
│   │   ├── model/                 # Domain Models
│   │   ├── service/              # Business Logic (6 сервисов)
│   │   └── servlet/              # Контроллеры (13 сервлетов)
│   └── webapp/
│       ├── css/                   # Таблицы стилей
│       ├── js/                    # Клиентские скрипты (fetch API)
│       ├── images/                # Аватарки и значки достижений
│       └── WEB-INF/
│           ├── web.xml            # Дескриптор развёртывания
│           └── jsp/               # JSP-шаблоны (7 страниц)
└── README.md                      # Текущая документация
```

### Схема базы данных

```text
users ──1:N──> xp_log
  │               (user_id, amount, reason, timestamp)
  │
  ├──1:N──> friends
  │             (user_id_1 ─ user_id_2, status: pending/accepted/rejected)
  │
  ├──1:N──> profile_views
  │             (viewer_id?, viewed_id, ip_address, view_date)
  │
  ├──1:N──> referrals
  │             (referrer_id ─ referred_id, reward_xp, status)
  │
  ├──1:N──> user_achievements ──N:1──> achievements
  │      (user_id, achievement_id)        (code, name, xp_reward)
  │
  └──1:N──> user_interests ──N:1──> interests
         (user_id, interest_id)         (name)
```

---

## 💻 Локальное развертывание

Для запуска проекта в изолированном окружении вам понадобятся **Docker** и **Docker Compose**, либо Java 17+ и Maven 3.9+.

### 1. Клонирование репозитория

```bash
git clone https://github.com/<ваш-username>/code-da-vinci.git
cd code-da-vinci
```

### 2. Настройка переменных окружения

Создайте файл `.env` в корневой директории проекта по образцу `.env.example`:

```env
DB_PASSWORD=your_secure_password
```

### 3. Быстрый старт (Docker)

```bash
docker compose up --build -d
# Открой в браузере: http://localhost:8080
```

База данных инициализируется автоматически при первом запуске.

### 4. Ручной запуск (без Docker)

```bash
# Создай БД и пользователя
psql -U postgres -c "CREATE DATABASE course_project;"
psql -U postgres -c "CREATE USER app_user WITH PASSWORD '1234';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE course_project TO app_user;"

# Выполни миграции
psql -U app_user -d course_project -f sql/schema.sql

# Сборка и деплой
export DB_URL="jdbc:postgresql://localhost:5432/course_project"
export DB_USER="app_user"
export DB_PASSWORD="1234"
mvn clean package
```

Скопируй `target/ROOT.war` в директорию `webapps/` твоего Tomcat 11.

---

## 🔌 Примеры эндпоинтов API

Полная интерактивная документация (Swagger / OpenAPI) доступна при локальном запуске.

| Метод | Эндпоинт | Описание | Доступ |
| --- | --- | --- | --- |
| `POST` | `/api/auth` | Вход / Регистрация | ✦ Открытый |
| `GET` | `/api/profile` | Данные профиля | 🔐 Авторизованные |
| `GET` | `/api/friends` | Социальные связи | 🔐 Авторизованные |
| `GET` | `/api/leaderboard` | Рейтинг популярности | 🔐 Авторизованные |
| `GET` | `/api/achievements` | Достижения пользователя | 🔐 Авторизованные |
| `GET` | `/api/xp` | XP и прогресс | 🔐 Авторизованные |

### Страницы (SSR, JSP)

| Путь | Страница | Назначение |
|------|----------|-----------|
| `GET /` или `/index` | Главная | Лендинг с формой входа |
| `GET /register` | Регистрация | Форма с реферальным кодом |
| `GET /profile` | Профиль | Просмотр/редактирование |
| `GET /leaderboard` | Лидеры | Таблица рейтинга |

---

## 👥 Разработчики

* [**Артем Рогачев**](https://github.com/TweetyDMG) — Backend Developer

## 📜 Лицензия

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Проект распространяется на условиях лицензии **MIT**. Полный текст лицензии находится в файле [LICENSE](./LICENSE).
