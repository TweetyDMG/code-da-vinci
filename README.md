<div align="center">
  <h1>🎨 Code Da Vinci</h1>
  <p><strong>Социальная платформа с RPG-геймификацией</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Java-17-%23ED8B00?logo=openjdk" alt="Java 17">
    <img src="https://img.shields.io/badge/Jakarta_EE-10-%23E25A1C?logo=eclipse" alt="Jakarta EE 10">
    <img src="https://img.shields.io/badge/PostgreSQL-16-%234169E1?logo=postgresql" alt="PostgreSQL 16">
    <img src="https://img.shields.io/badge/Maven-3.9-%23C71A36?logo=apachemaven" alt="Maven 3.9">
  </p>
</div>

---

## О проекте

**Code Da Vinci** — бэкенд веб-приложения, объединяющего социальную сеть с игровыми механиками. Пользователи создают профили, заводят друзей, зарабатывают опыт (XP), получают достижения, соревнуются в рейтинге популярности и приглашают друзей по реферальным ссылкам.

Проект реализован на Jakarta EE (сервлеты + JSP) без сторонних фреймворков — вся бизнес-логика написана на чистом JDBC с собственным сервисным слоем.

---

## 🛠 Технологический стек

| Категория | Технология | Версия |
|-----------|-----------|--------|
| **Язык** | Java | 17 |
| **Web** | Jakarta Servlet / JSP / JSTL | 6.1 / 4.0 / 3.0 |
| **База данных** | PostgreSQL | 16+ |
| **Доступ к данным** | HikariCP (connection pool) + JDBC | 5.1 |
| **Аутентификация** | jBCrypt (BCrypt, cost 12) | 0.4 |
| **Сериализация** | Gson | 2.13.2 |
| **Сборка** | Apache Maven | 3.9 |
| **Контейнеризация** | Docker + Docker Compose | — |

---

## 🚀 Ключевой функционал

### 👤 Профили и регистрация
- Регистрация с валидацией email и пароля
- Аутентификация по сессии (BCrypt-хеширование)
- Редактирование профиля: ФИО, био, аватар (multipart-загрузка)
- Выбор интересов из справочника

### ⭐ Система опыта и уровней
```
level = floor(sqrt(XP / 100))
Ранги: Новичок → Bronze → Silver → Gold → Platinum
```
- Начисление XP за регистрацию (+50), принятие в друзья (+20), рефералов (+50), достижения
- Полный аудит начислений в таблице `xp_log`
- API прогресса с процентами до следующего уровня

### 🏆 Достижения (18 штук)

| Группа | Достижения |
|--------|-----------|
| **XP** | 1000 / 5000 / 10000 |
| **Уровень** | 5 / 10 / 25 / 50 |
| **Друзья** | 1 / 10 / 50 |
| **Просмотры** | 100 / 500 / 1000 |
| **Рефералы** | 1 / 5 / 10 |
| **Профиль** | Первые шаги / Заполненный профиль |

### 🤝 Социальные связи
- Отправка, принятие и отклонение заявок в друзья
- Автоматическое принятие встречной заявки (mutual)
- Поиск пользователей по имени и по общим интересам
- 4 статуса отношений: `friends`, `pending_sent`, `pending_received`, `none`

### 🔗 Реферальная система
- UUID-код каждому пользователю при регистрации
- Реферальная ссылка: `/register?ref=<code>`
- Пригласивший получает +50 XP, приглашённый — +50 XP на старте
- Статус реферала: `COMPLETED` (одноразовая связь)

### 📊 Рейтинг популярности
```
Score = views × 0.4 + friends × 0.3 + level × 10 × 0.2 + referrals × 0.1
```
- Топ-100 кэшируется в памяти на 60 секунд
- Дедупликация просмотров профиля: не чаще 1 раза в час с одного IP
- Отдельный API для позиции в рейтинге и детализированного скоринга

---

## 📁 Архитектура проекта

### Слои

```text
┌─────────────────────────────────────────────┐
│     Page Servlets (SSR, JSP)                │
│  /index  /register  /profile  /friends      │
│  /leaderboard  /referrals  /logout          │
├─────────────────────────────────────────────┤
│     REST Servlets (JSON API)                │
│  /api/auth  /api/profile  /api/friends      │
│  /api/leaderboard  /api/achievements        │
│  /api/xp  /api/referrals                    │
├─────────────────────────────────────────────┤
│     Service Layer (бизнес-логика)           │
│  UserService  XPService  FriendService      │
│  AchievementService  ProfileService         │
│  PopularityService                          │
├─────────────────────────────────────────────┤
│     DAO Layer (JDBC → HikariCP → PostgreSQL)│
│  UserDAO  FriendDAO  XPLogDAO              │
│  AchievementDAO  ProfileViewDAO            │
│  ReferralDAO  InterestDAO                   │
└─────────────────────────────────────────────┘
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

### Дерево файлов

```text
code-da-vinci/
├── pom.xml                        # Зависимости, сборка Maven
├── Dockerfile                     # Многостадийная сборка → Tomcat 11
├── docker-compose.yml             # PostgreSQL + приложение
├── .env.example                   # Шаблон переменных окружения
├── .gitignore                     # Игнорируемые файлы (IDE, сборка, env)
├── sql/
│   └── schema.sql                 # DDL + seed-данные (achievements, interests)
├── src/main/
│   ├── java/ru/vstu/codedavinci/
│   │   ├── dao/                   # Data Access Layer (8 DAO-классов)
│   │   ├── dto/                   # Data Transfer Objects (UserDTO)
│   │   ├── filter/                # Фильтры (SecurityHeadersFilter)
│   │   ├── model/                 # Domain Models (User, Achievement, Friend)
│   │   ├── service/              # Business Logic (6 сервисов)
│   │   └── servlet/              # Контроллеры (13 сервлетов)
│   └── webapp/
│       ├── css/                   # Таблицы стилей
│       ├── js/                    # Клиентские скрипты (fetch API)
│       ├── images/                # Аватарки и значки достижений
│       └── WEB-INF/
│           ├── web.xml            # Дескриптор развёртывания
│           └── jsp/               # JSP-шаблоны (7 страниц)
└── out/                          # ❌ артефакты IDE (удалить)
```

---

## 💻 Локальное развертывание

### Быстрый старт (Docker)

```bash
# 1. Клонируй репозиторий
git clone <repo-url>
cd code-da-vinci

# 2. (Опционально) Настрой пароль БД
cp .env.example .env
# отредактируй DB_PASSWORD в .env

# 3. Собери и запусти
docker compose up --build -d

# 4. Открой в браузере
open http://localhost:8080
```

База данных инициализируется автоматически при первом запуске (скрипт `sql/schema.sql` выполняется PostgreSQL). Приложение будет доступно на порту 8080.

### Ручной запуск (без Docker)

**Требования:** Java 17+, Maven 3.9+, PostgreSQL 16+

#### 1. База данных

```bash
# Создай БД и пользователя
psql -U postgres -c "CREATE DATABASE course_project;"
psql -U postgres -c "CREATE USER app_user WITH PASSWORD '1234';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE course_project TO app_user;"

# Выполни миграции
psql -U app_user -d course_project -f sql/schema.sql
```

#### 2. Сборка и деплой

```bash
export DB_URL="jdbc:postgresql://localhost:5432/course_project"
export DB_USER="app_user"
export DB_PASSWORD="1234"

mvn clean package
# WAR-файл будет в target/ROOT.war
```

Скопируй `target/ROOT.war` в директорию `webapps/` твоего Tomcat 11 и запусти сервер.

#### 3. Открой в браузере

```
http://localhost:8080
```

---

## 🔌 Эндпоинты API

### REST (JSON)

| Метод | Путь | Параметры | Описание | Доступ |
|-------|------|-----------|----------|--------|
| `POST` | `/api/auth` | `{"action":"login", "username","password"}` | Вход | ✦ |
| `POST` | `/api/auth` | `{"action":"register", "username","password","email","refCode?"}` | Регистрация | ✦ |
| `GET` | `/api/profile` | `?userId=` | Данные профиля | 🔐 |
| `POST` | `/api/profile` | multipart: `fullName, bio, avatarFile, interests[]` | Обновление | 🔐 |
| `GET` | `/api/friends` | `?action=list\|incoming\|outgoing\|search&q=\|count\|searchByInterests&interests=` | Соц. связи | 🔐 |
| `POST` | `/api/friends` | `{"action":"send\|accept\|reject\|remove", "targetId"}` | Изменение статуса | 🔐 |
| `GET` | `/api/leaderboard` | `?action=list&limit=50\|rank\|score&userId=` | Рейтинг | 🔐 |
| `GET` | `/api/achievements` | `?userId=` | Достижения | 🔐 |
| `GET` | `/api/xp` | `?userId=` | XP и прогресс | 🔐 |
| `GET` | `/api/referrals` | — | Мои рефералы | 🔐 |

✦ — открытый / 🔐 — требуется авторизация (сессия)

### Страницы (SSR, JSP)

| Путь | Страница | Назначение |
|------|----------|-----------|
| `GET /` или `/index` | Главная | Лендинг с формой входа |
| `GET /register` | Регистрация | Форма с реферальным кодом |
| `GET /profile` | Профиль | Просмотр/редактирование профиля |
| `GET /friends` | Друзья | Управление подписками |
| `GET /leaderboard` | Лидеры | Таблица рейтинга |
| `GET /referrals` | Рефералы | Статистика приглашений |
| `GET /logout` | Выход | Завершение сессии |

---

## 🧪 Планы по улучшению (Roadmap)

- [x] Connection pool (HikariCP)
- [x] Docker + Docker Compose
- [x] SQL-миграции
- [x] Заголовки безопасности
- [x] Конфигурация через переменные окружения
- [ ] Unit-тесты (JUnit 5 + Testcontainers)
- [ ] OpenAPI / Swagger-спецификация
- [ ] Миграция на Spring Boot (опционально)
- [ ] CI/CD (GitHub Actions)

---

<div align="center">
  <sub>Разработано в рамках учебного курса · Вятский государственный университет</sub>
</div>
