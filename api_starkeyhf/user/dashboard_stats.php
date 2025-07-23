<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../connection.php';

if (!$connectNow) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $stats = [];
    
    // Patients Served
    $result = $connectNow->query("SELECT COUNT(DISTINCT patient_id) AS count FROM visits");
    if (!$result) throw new Exception("Patients served query failed");
    $stats['patients_served'] = (int)$result->fetch_assoc()['count'];
    
    // Patients Fitted
    $result = $connectNow->query("SELECT COUNT(DISTINCT id) AS count FROM hearing_aid_fitting WHERE num_hearing_aids > 0");
    if (!$result) throw new Exception("Patients fitted query failed");
    $stats['patients_fitted'] = (int)$result->fetch_assoc()['count'];
    
    // Hearing Aids Fitted
    $result = $connectNow->query("SELECT SUM(CASE WHEN num_hearing_aids = '1' THEN 1 WHEN num_hearing_aids = '2' THEN 2 ELSE 0 END) AS total FROM hearing_aid_fitting");
    if (!$result) throw new Exception("Hearing aids query failed");
    $stats['hearing_aids_fitted'] = (int)($result->fetch_assoc()['total'] ?? 0);
    
    // Mission Cities
    $result = $connectNow->query("SELECT COUNT(DISTINCT city_id) AS count FROM patients WHERE city_id IS NOT NULL");
    if (!$result) throw new Exception("Mission cities query failed");
    $stats['mission_cities'] = (int)$result->fetch_assoc()['count'];

    echo json_encode([
        'success' => true,
        'data' => $stats
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Internal server error'
    ]);
} finally {
    $connectNow->close();
}
?>