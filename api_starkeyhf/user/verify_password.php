<?php
include '../connection.php';
header('Content-Type: application/json');

// Check DB connection
if ($connectNow->connect_error) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Database connection failed"
    ]);
    exit();
}

// Check required inputs
if (!isset($_POST['username']) || !isset($_POST['password'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Missing required fields"
    ]);
    exit();
}

$username = trim($_POST['username']);
$password = trim($_POST['password']);

// Fetch hashed password from DB
$stmt = $connectNow->prepare("SELECT Password FROM users WHERE Username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows === 1) {
    $stmt->bind_result($storedHash);
    $stmt->fetch();

    if (password_verify($password, $storedHash)) {
        echo json_encode(["success" => true]);
    } else {
        echo json_encode(["success" => false, "message" => "Incorrect password"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "User not found"]);
}

$stmt->close();
$connectNow->close();
