<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

include '../connection.php';

// ✅ Check DB connection
if (!$connectNow) {
    echo json_encode(['success' => false, 'message' => 'DB connection failed']);
    exit();
}

// ✅ Sanitize input
$username = trim($_POST['username'] ?? '');
$otp = trim($_POST['otp'] ?? '');

// ✅ Validate inputs
if (empty($username) || empty($otp)) {
    echo json_encode(['success' => false, 'message' => 'Username and OTP are required']);
    exit();
}

if (!ctype_digit($otp) || strlen($otp) !== 6) {
    echo json_encode(['success' => false, 'message' => 'Invalid OTP format']);
    exit();
}

// ✅ Step 1: Get user ID
$stmtUser = $connectNow->prepare("SELECT UserID FROM users WHERE username = ?");
$stmtUser->bind_param("s", $username);
$stmtUser->execute();
$resultUser = $stmtUser->get_result();

if ($resultUser->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'User not found']);
    $stmtUser->close();
    exit();
}

$user = $resultUser->fetch_assoc();
$userId = $user['UserID'];
$stmtUser->close();

// ✅ Step 2: Fetch OTP
$stmtOtp = $connectNow->prepare("
    SELECT otp_code, created_at
    FROM otp_codes
    WHERE user_id = ? AND otp_code = ?
    ORDER BY id DESC
    LIMIT 1
");
$stmtOtp->bind_param("is", $userId, $otp);
$stmtOtp->execute();
$resultOtp = $stmtOtp->get_result();

if ($resultOtp->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid OTP']);
    $stmtOtp->close();
    exit();
}

$otpData = $resultOtp->fetch_assoc();
$stmtOtp->close();

// ✅ Step 3: Check expiration (within 5 minutes)
$createdAt = strtotime($otpData['created_at']);
if ($createdAt === false) {
    echo json_encode(['success' => false, 'message' => 'Invalid OTP timestamp']);
    exit();
}

$expiresAt = $createdAt + (5 * 60);
$currentTime = time();

if ($currentTime > $expiresAt) {
    echo json_encode(['success' => false, 'message' => 'OTP expired']);
    exit();
}

// ✅ OTP is valid
echo json_encode(['success' => true, 'message' => 'OTP verified']);
exit();
?>
