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

// Check required fields
if (
    !isset($_POST['username']) ||
    !isset($_POST['old_username']) ||
    !isset($_POST['FirstName']) ||
    !isset($_POST['LastName']) ||
    !isset($_POST['Gender']) ||
    !isset($_POST['Birthdate']) ||
    !isset($_POST['PhoneNumber'])
) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Missing required fields"
    ]);
    exit();
}

$username = trim($_POST['username']);
$oldUsername = trim($_POST['old_username']);
$firstName = trim($_POST['FirstName']);
$lastName = trim($_POST['LastName']);
$gender = trim($_POST['Gender']);
$birthdate = trim($_POST['Birthdate']);
$phone = trim($_POST['PhoneNumber']);
$newPassword = isset($_POST['PasswordHash']) ? trim($_POST['PasswordHash']) : null;

// Check if new username already exists (and is not the same as the old one)
if ($username !== $oldUsername) {
    $check = $connectNow->prepare("SELECT Username FROM users WHERE Username=?");
    $check->bind_param("s", $username);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        echo json_encode([
            "success" => false,
            "message" => "Username already taken"
        ]);
        $check->close();
        exit();
    }
    $check->close();
}

// Build the update query
if (!empty($newPassword)) {
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    $stmt = $connectNow->prepare(
        "UPDATE users SET FirstName=?, LastName=?, Gender=?, Birthdate=?, PhoneNumber=?, Username=?, Password=? WHERE Username=?"
    );
    $stmt->bind_param("ssssssss", $firstName, $lastName, $gender, $birthdate, $phone, $username, $hashedPassword, $oldUsername);
} else {
    $stmt = $connectNow->prepare(
        "UPDATE users SET FirstName=?, LastName=?, Gender=?, Birthdate=?, PhoneNumber=?, Username=? WHERE Username=?"
    );
    $stmt->bind_param("sssssss", $firstName, $lastName, $gender, $birthdate, $phone, $username, $oldUsername);
}

if ($stmt->execute()) {
    $select = $connectNow->prepare(
        "SELECT FirstName, LastName, Username, PhoneNumber, Gender, Birthdate FROM users WHERE Username=?"
    );
    $select->bind_param("s", $username);
    $select->execute();
    $result = $select->get_result();
    $userData = $result->fetch_assoc();

    echo json_encode([
        "success" => true,
        "message" => "Profile updated successfully",
        "userData" => $userData
    ]);
    $select->close();
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to update profile"
    ]);
}

$stmt->close();
$connectNow->close();
?>
