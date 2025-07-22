<?php
// ✅ Enable error reporting during development (disable in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// ✅ Set content-type to return proper JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// ✅ Include database connection
require_once '../connection.php';

// ✅ Validate method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method. Use POST.'
    ]);
    exit;
}

// ✅ Sanitize input
$userID = isset($_POST['UserID']) && is_numeric($_POST['UserID']) && $_POST['UserID'] > 0
    ? intval($_POST['UserID'])
    : null;

$actionType = isset($_POST['ActionType']) ? trim($_POST['ActionType']) : '';
$description = isset($_POST['Description']) ? trim($_POST['Description']) : '';
$status = isset($_POST['Status']) ? trim($_POST['Status']) : 'Success';

// ✅ Check required fields
if (empty($actionType) || empty($description)) {
    http_response_code(400); // Bad Request
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields: ActionType and Description.'
    ]);
    exit;
}

// ✅ Insert into activity_logs table
$query = "INSERT INTO activity_logs (UserID, ActionType, Description, Status) VALUES (?, ?, ?, ?)";
$stmt = $connectNow->prepare($query);

if ($stmt) {
    // Use null for userID if it's not set/invalid
    $stmt->bind_param("isss", $userID, $actionType, $description, $status);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Activity log inserted successfully.'
        ]);
    } else {
        http_response_code(500); // Internal Server Error
        echo json_encode([
            'success' => false,
            'message' => 'Failed to execute statement: ' . $stmt->error
        ]);
    }

    $stmt->close();
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare statement: ' . $connectNow->error
    ]);
}

$connectNow->close();
