-- Extra databases and grants for local Docker (runs after MARIADB_* user/database setup).
-- Rails `bin/rails db:prepare` prepares both development and test by default.
CREATE DATABASE IF NOT EXISTS app_test;
GRANT ALL PRIVILEGES ON app_test.* TO 'app'@'%';
FLUSH PRIVILEGES;
