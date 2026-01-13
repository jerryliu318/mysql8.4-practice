CREATE DATABASE IF NOT EXISTS demo_db;
USE demo_db;

CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(255) NOT NULL
);

INSERT INTO messages (content) VALUES ('Hello from MySQL 8.0!');

-- Create user with SHA1-based mysql_native_password (simulating legacy client)
CREATE USER 'user_sha1'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password_sha1';
GRANT SELECT ON demo_db.* TO 'user_sha1'@'%';

-- Create user with SHA2-based caching_sha2_password (modern client)
CREATE USER 'user_sha2'@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'password_sha2';
GRANT SELECT ON demo_db.* TO 'user_sha2'@'%';

FLUSH PRIVILEGES;
