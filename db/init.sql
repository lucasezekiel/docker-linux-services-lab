CREATE TABLE IF NOT EXISTS demo_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO demo_messages (message)
VALUES ('Persistent storage is working');
