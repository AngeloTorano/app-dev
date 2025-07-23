<?php
ob_clean();
header('Content-Type: application/json');
error_reporting(0);
ini_set('display_errors', 0);

include '../connection.php';

if (!$connectNow) {
    echo json_encode(['success' => false, 'message' => 'DB connection failed']);
    exit();
}

$username = trim($_POST['username'] ?? '');
if (empty($username)) {
    echo json_encode(['success' => false, 'message' => 'Username is required']);
    exit();
}

$stmt = $connectNow->prepare("SELECT UserID, FirstName, LastName, PhoneNumber FROM users WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'User not found']);
    exit();
}

$user = $result->fetch_assoc();
$userId = $user['UserID'];
$phone = $user['PhoneNumber'];
$fullName = $user['FirstName'] . ' ' . $user['LastName'];
$otp = rand(100000, 999999);

// Format phone number (in case stored as 09xxxxxxxxx)
if (strpos($phone, '09') === 0) {
    $phone = '+63' . substr($phone, 1); // convert 09xxxxxxx to +639xxxxxxxxx
}

// httpSMS configuration
$httpSMS_url = "https://api.httpsms.com/v1/messages/send";
$api_key = "uk_pBxkJLNmPH6u8vL7si5dDGjVmzOlAXJINdy4nW5ebCID5W3THPH8fTylcNULzmqD"; // Replace with your actual httpSMS API key
$sender = "+639708710682"; // Replace with your httpSMS sender number

$payload = json_encode([
    "content" => "Hello this is Starkey, Your OTP code is $otp. It expires in 5 minutes.",
    "from" => $sender,
    "to" => $phone
]);

$ch = curl_init($httpSMS_url);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "x-api-key: $api_key",
    "Content-Type: application/json",
    "Accept: application/json"
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);

$responseBody = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

// Check for curl error
if (!empty($curlError)) {
    echo json_encode(['success' => false, 'message' => 'Curl error: ' . $curlError]);
    exit();
}

// Check for httpSMS success (httpSMS typically returns 200 for success)
if ($httpCode === 200) {
    $insertStmt = $connectNow->prepare("INSERT INTO otp_codes (user_id, otp_code) VALUES (?, ?)");
    $insertStmt->bind_param("is", $userId, $otp);
    $insertStmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'OTP sent',
        'user' => ['name' => $fullName]
    ]);
    exit();
}

// Handle httpSMS error
$responseDecoded = json_decode($responseBody, true);
$errorDetails = $responseDecoded['message'] ?? 'Unknown error';

echo json_encode([
    'success' => false,
    'message' => 'httpSMS error: ' . $errorDetails,
    'status_code' => $httpCode,
    'response' => $responseDecoded
]);
exit();
?>