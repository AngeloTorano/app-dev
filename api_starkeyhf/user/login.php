<?php
include '../connection.php';
header('Content-Type: application/json');

$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($username) || empty($password)) {
    echo json_encode([
        "success" => false,
        "message" => "Username and password are required"
    ]);
    exit();
}

// Query user by username
$stmt = $connectNow->prepare("
    SELECT u.UserID, u.FirstName, u.LastName, u.Username, u.PhoneNumber, u.Gender, u.Birthdate,
           u.Password, u.FailedAttempts, u.LastFailedLogin, r.RoleName
    FROM users u
    INNER JOIN roles r ON u.RoleID = r.RoleID
    WHERE u.Username = ?
");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

// Username not found: do NOT log to DB, just return error
if ($result->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "message" => "No account found"
    ]);
    exit();
}

$user = $result->fetch_assoc();
$userId = (int)$user['UserID'];
$failedAttempts = (int)$user['FailedAttempts'];
$lastFailed = $user['LastFailedLogin'];
$lockDuration = 30; // in seconds
$maxAttempts = 3;

// ⏳ Check lock status
if ($failedAttempts >= $maxAttempts && $lastFailed) {
    $lastFailedTime = strtotime($lastFailed);
    $currentTime = time();
    $remainingLock = $lockDuration - ($currentTime - $lastFailedTime);

    if ($remainingLock > 0) {
        echo json_encode([
            "success" => false,
            "message" => "Account locked. Try again in {$remainingLock}s",
            "status" => "locked"
        ]);
        exit();
    }
}

// 🔐 Validate password using hashed password
if (password_verify($password, $user['Password'])) {
    // ✅ Success: Reset attempts
    $resetStmt = $connectNow->prepare("UPDATE users SET FailedAttempts = 0, LastFailedLogin = NULL WHERE UserID = ?");
    $resetStmt->bind_param("i", $userId);
    $resetStmt->execute();
    $resetStmt->close();

    unset($user['Password'], $user['FailedAttempts'], $user['LastFailedLogin']);

    echo json_encode([
        "success" => true,
        "message" => "Login successful",
        "userData" => $user
    ]);
} else {
    // ❌ Wrong password: update attempt count and timestamp
    $failedAttempts++;
    $now = date('Y-m-d H:i:s');

    $updateStmt = $connectNow->prepare("UPDATE users SET FailedAttempts = ?, LastFailedLogin = ? WHERE UserID = ?");
    $updateStmt->bind_param("isi", $failedAttempts, $now, $userId);
    $updateStmt->execute();
    $updateStmt->close();

    echo json_encode([
        "success" => false,
        "message" => "Incorrect password",
        "status" => "wrong_password"
    ]);
}

$stmt->close();
$connectNow->close();
