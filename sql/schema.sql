-- ══════════════════════════════════════════════════════════════
-- Code Da Vinci — DDL Schema + Seed Data
-- ══════════════════════════════════════════════════════════════
-- Этот файл выполняется PostgreSQL при инициализации контейнера
-- (docker-entrypoint-initdb.d) или вручную через psql:
--   psql -U app_user -d course_project -f sql/schema.sql
-- ══════════════════════════════════════════════════════════════

-- ─── Пользователи ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id              BIGSERIAL       PRIMARY KEY,
    username        VARCHAR(50)     UNIQUE NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    email           VARCHAR(100)    NOT NULL,
    full_name       VARCHAR(100),
    bio             TEXT,
    avatar_path     VARCHAR(255),
    xp              INTEGER         NOT NULL DEFAULT 50,
    level           INTEGER         NOT NULL DEFAULT 1,
    referrer_id     BIGINT          REFERENCES users(id),
    referral_code   VARCHAR(36)     UNIQUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── Лог начисления опыта ───────────────────────────────────
CREATE TABLE IF NOT EXISTS xp_log (
    id          BIGSERIAL       PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount      INTEGER         NOT NULL,
    reason      VARCHAR(100),
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_xp_log_user_id ON xp_log(user_id);

-- ─── Социальные связи (друзья) ──────────────────────────────
CREATE TABLE IF NOT EXISTS friends (
    id          BIGSERIAL       PRIMARY KEY,
    user_id_1   BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id_2   BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      VARCHAR(20)     NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id_1, user_id_2)
);

CREATE INDEX IF NOT EXISTS idx_friends_user_id_1 ON friends(user_id_1);
CREATE INDEX IF NOT EXISTS idx_friends_user_id_2 ON friends(user_id_2);

-- ─── Просмотры профиля ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS profile_views (
    id          BIGSERIAL       PRIMARY KEY,
    viewer_id   BIGINT          REFERENCES users(id) ON DELETE SET NULL,
    viewed_id   BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ip_address  VARCHAR(45),
    view_date   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_profile_views_viewed_id ON profile_views(viewed_id);

-- ─── Достижения (справочник) ────────────────────────────────
CREATE TABLE IF NOT EXISTS achievements (
    id          BIGSERIAL       PRIMARY KEY,
    code        VARCHAR(50)     UNIQUE NOT NULL,
    name        VARCHAR(100)    NOT NULL,
    description TEXT,
    xp_reward   INTEGER         NOT NULL DEFAULT 0,
    icon_url    VARCHAR(255)
);

-- ─── Связь пользователь → достижение ────────────────────────
CREATE TABLE IF NOT EXISTS user_achievements (
    user_id         BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id  BIGINT      NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, achievement_id)
);

-- ─── Интересы (справочник) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS interests (
    id      SERIAL      PRIMARY KEY,
    name    VARCHAR(50) UNIQUE NOT NULL
);

-- ─── Связь пользователь → интересы ──────────────────────────
CREATE TABLE IF NOT EXISTS user_interests (
    user_id     BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    interest_id INTEGER NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, interest_id)
);

-- ─── Реферальные связи ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS referrals (
    id          BIGSERIAL       PRIMARY KEY,
    referrer_id BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_id BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_xp   INTEGER         NOT NULL DEFAULT 50,
    status      VARCHAR(20)     NOT NULL DEFAULT 'COMPLETED'
                                CHECK (status IN ('COMPLETED')),
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(referrer_id, referred_id)
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON referrals(referrer_id);


-- ══════════════════════════════════════════════════════════════
-- SEED DATA
-- ══════════════════════════════════════════════════════════════

-- ─── Достижения ─────────────────────────────────────────────
INSERT INTO achievements (code, name, description, xp_reward, icon_url) VALUES
    ('FIRST_STEPS',     'Первые шаги',        'Зарегистрироваться в системе',               10,  '/images/ach/f1.png'),
    ('XP_1000',         '1000 XP',            'Накопить 1000 очков опыта',                  20,  '/images/ach/xp1.png'),
    ('XP_5000',         '5000 XP',            'Накопить 5000 очков опыта',                  50,  '/images/ach/xp5.png'),
    ('XP_10000',        '10000 XP',           'Накопить 10000 очков опыта',                 100, '/images/ach/xp10.png'),
    ('LVL_5',           'Уровень 5',          'Достичь 5-го уровня',                        30,  '/images/ach/lvl5.png'),
    ('LVL_10',          'Уровень 10',         'Достичь 10-го уровня',                       50,  '/images/ach/lvl10.png'),
    ('LVL_25',          'Уровень 25',         'Достичь 25-го уровня',                       100, '/images/ach/lvl25.png'),
    ('LVL_50',          'Уровень 50',         'Достичь 50-го уровня',                       200, '/images/ach/lvl50.png'),
    ('FRIENDS_1',       'Первый друг',        'Добавить первого друга',                     15,  '/images/ach/f1.png'),
    ('FRIENDS_10',      '10 друзей',          'Добавить 10 друзей',                         30,  '/images/ach/f10.png'),
    ('FRIENDS_50',      '50 друзей',          'Добавить 50 друзей',                         100, '/images/ach/f50.png'),
    ('VIEWS_100',       '100 просмотров',     'Получить 100 просмотров профиля',           20,  '/images/ach/v100.png'),
    ('VIEWS_500',       '500 просмотров',     'Получить 500 просмотров профиля',           50,  '/images/ach/v500.png'),
    ('VIEWS_1000',      '1000 просмотров',    'Получить 1000 просмотров профиля',          100, '/images/ach/v1000.png'),
    ('REF_1',           'Первый реферал',     'Пригласить первого пользователя',            20,  '/images/ach/r1.png'),
    ('REF_5',           '5 рефералов',        'Пригласить 5 пользователей',                 50,  '/images/ach/r5.png'),
    ('REF_10',          '10 рефералов',       'Пригласить 10 пользователей',                100, '/images/ach/r10.png'),
    ('PROFILE_COMPLETE','Заполненный профиль','Заполнить ФИО, био и сменить аватар',        25,  '/images/ach/profile.png')
ON CONFLICT (code) DO NOTHING;

-- ─── Интересы ───────────────────────────────────────────────
INSERT INTO interests (name) VALUES
    ('Программирование'), ('Дизайн'),     ('Музыка'),     ('Спорт'),
    ('Фотография'),       ('Путешествия'),('Книги'),      ('Кино'),
    ('Настольные игры'),  ('Кулинария'),  ('Рисование'),  ('IT'),
    ('Технологии'),       ('Наука'),      ('Искусство'),  ('Аниме'),
    ('Автомобили'),       ('Животные'),   ('Мода'),       ('Волонтёрство')
ON CONFLICT (name) DO NOTHING;
