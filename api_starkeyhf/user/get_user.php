<?php
header('Content-Type: application/json');
include '../connection.php';

$username = $_POST['username'] ?? '';

if (empty($username)) {
    echo json_encode(['success' => false, 'message' => 'Username is required']);
    exit();
}

$stmt = $connectNow->prepare("SELECT UserID FROM users WHERE Username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'User not found']);
} else {
    $user = $result->fetch_assoc();
    echo json_encode(['success' => true, 'user' => $user]);
}

$stmt->close();
$connectNow->close();
?>
