<?php
header("Content-Type: application/json");

include '../connection.php'; // Ensure your DB credentials are there

// Get inputs
$cities = isset($_POST['cities']) ? json_decode($_POST['cities'], true) : [];
$message = $_POST['message'] ?? '';

if (empty($cities) || empty($message)) {
    echo json_encode(['status' => 'error', 'message' => 'City and message are required']);
    exit;
}

// Infobip API configuration
$infobip_api_key = '9fcd398109f2af2652badb34cb8e3d59-3ff8fc5b-2773-4269-accb-bed666df2bad';
$sender = '447491163443';
$base_url = 'https://z3lyrw.api.infobip.com';

$send_results = [];
$success_count = 0;
$fail_count = 0;

foreach ($cities as $city) {
    // Prepare and run query
    $stmt = $conn->prepare("SELECT PatientID, MobileNumber FROM patients WHERE CityOrVillage = ? AND MobileNumber IS NOT NULL AND MobileNumber != ''");
    $stmt->bind_param("s", $city);
    $stmt->execute();
    $result = $stmt->get_result();

    // Loop through patients
    while ($row = $result->fetch_assoc()) {
        $patientId = $row['PatientID'];
        $number = $row['MobileNumber'];

        // Prepare Infobip payload
        $payload = [
            'messages' => [[
                'from' => $sender,
                'destinations' => [['to' => $number]],
                'text' => $message
            ]]
        ];

        $ch = curl_init("$base_url/sms/2/text/advanced");
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Authorization: App $infobip_api_key",
            "Content-Type: application/json",
            "Accept: application/json"
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $status = ($http_code === 200) ? 'sent' : 'failed';

        // Save log
        $logStmt = $conn->prepare("INSERT INTO sms_logs (PatientID, RecipientNumber, Message, Status) VALUES (?, ?, ?, ?)");
        $logStmt->bind_param("isss", $patientId, $number, $message, $status);
        $logStmt->execute();

        $send_results[] = [
            'PatientID' => $patientId,
            'to' => $number,
            'status' => $status
        ];

        if ($status === 'sent') {
            $success_count++;
        } else {
            $fail_count++;
        }
    }

    $stmt->close();
}

$conn->close();

echo json_encode([
    'status' => 'sent',
    'message' => "Message sent to $success_count recipients, failed for $fail_count.",
    'details' => $send_results
]);
?>
