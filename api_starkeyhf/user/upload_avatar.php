<?php
header("Content-Type: application/json");
ini_set('display_errors', 1);
error_reporting(E_ALL);

include '../connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $userId = $_POST['user_id'] ?? '';

    if (empty($userId) || !isset($_FILES['avatar'])) {
        echo json_encode(['status' => 'error', 'message' => 'Missing user ID or file']);
        exit;
    }

    $avatar = $_FILES['avatar'];
    $uploadDir = realpath(__DIR__ . '/../uploads/avatars') . '/';
    $fileExt = strtolower(pathinfo($avatar['name'], PATHINFO_EXTENSION));
    $timestamp = time();
    $newFilename = 'avatar_' . $userId . '_' . $timestamp . '.' . $fileExt;
    $uploadPath = $uploadDir . $newFilename;
    $relativePath = 'uploads/avatars/' . $newFilename;

    $allowedTypes = ['jpg', 'jpeg', 'png', 'gif'];
    if (!in_array($fileExt, $allowedTypes)) {
        echo json_encode(['status' => 'error', 'message' => 'Only JPG, JPEG, PNG, and GIF are allowed']);
        exit;
    }

    // Ensure upload directory exists
    if (!is_dir($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            echo json_encode(['status' => 'error', 'message' => 'Failed to create upload directory']);
            exit;
        }
    }

    // Move uploaded file
    if (move_uploaded_file($avatar['tmp_name'], $uploadPath)) {
        $stmt = $conn->prepare("UPDATE users SET avatar = ? WHERE id = ?");
        $stmt->bind_param("si", $relativePath, $userId);

        if ($stmt->execute()) {
            echo json_encode([
                'status' => 'success',
                'message' => 'Avatar uploaded successfully',
                'avatar_path' => $relativePath
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'Database update failed',
                'db_error' => $stmt->error
            ]);
        }

        $stmt->close();
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to move uploaded file',
            'tmp_name' => $avatar['tmp_name'],
            'upload_path' => $uploadPath
        ]);
    }

    $conn->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}
