<?php
include '../connection.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

$response = [];

$query = "
    SELECT 
        a.LogID,
        a.UserID,
        CASE 
            WHEN a.UserID IS NULL THEN 'System'
            ELSE COALESCE(CONCAT(u.FirstName, ' ', u.LastName), 'Unknown User')
        END AS FullName,
        a.ActionType,
        a.Description,
        a.Status,
        a.CreatedAt
    FROM activity_logs a
    LEFT JOIN users u ON a.UserID = u.UserID
    ORDER BY a.CreatedAt DESC
";

$result = $connectNow->query($query);

if ($result) {
    $logs = [];
    while ($row = $result->fetch_assoc()) {
        $logs[] = $row;
    }
    $response['success'] = true;
    $response['logs'] = $logs;
} else {
    $response['success'] = false;
    $response['error'] = $connectNow->error;
}

echo json_encode($response);
?>
