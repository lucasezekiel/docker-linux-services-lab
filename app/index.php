<?php

header('Content-Type: text/plain; charset=utf-8');

$host = getenv('DB_HOST');
$db   = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->query(
        "SELECT message, created_at
         FROM demo_messages
         ORDER BY id DESC
         LIMIT 1"
    );

    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "Docker Linux Services Lab\n";
    echo "=========================\n";
    echo "Web service: OK\n";
    echo "Database connection: OK\n\n";

    if ($row) {
        echo "Database message: " . $row['message'] . "\n";
        echo "Created at: " . $row['created_at'] . "\n";
    }

} catch (Throwable $e) {
    http_response_code(500);

    error_log($e->getMessage());

    echo "Docker Linux Services Lab\n";
    echo "Database connection: FAILED\n";
}
