<?php
// filepath: c:\xampp\htdocs\api_starkey\user\patient.php
include '../connection.php';
header('Content-Type: application/json');

// Get search parameters from POST (or GET for flexibility)
$patientID = $_POST['PatientID'] ?? null;
$surname = $_POST['Surname'] ?? null;
$firstName = $_POST['FirstName'] ?? null;
$school = $_POST['School'] ?? null;
$city = $_POST['City'] ?? null;

// Build dynamic WHERE clause
$where = [];
$params = [];
$types = '';

if ($patientID) {
    $where[] = 'id = ?';
    $params[] = $patientID;
    $types .= 'i';
}
if ($surname) {
    $where[] = 'surname LIKE ?';
    $params[] = "%$surname%";
    $types .= 's';
}
if ($firstName) {
    $where[] = 'first_name LIKE ?';
    $params[] = "%$firstName%";
    $types .= 's';
}
if ($school) {
    $where[] = 'school_name LIKE ?';
    $params[] = "%$school%";
    $types .= 's';
}
if ($city) {
    $where[] = 'city_or_village LIKE ?';
    $params[] = "%$city%";
    $types .= 's';
}

// Build SQL
$sql = "SELECT 
    id AS `SHF Patient ID`,
    shf_id,
    CONCAT(first_name, ' ', surname) AS `Name`,
    TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) AS `Age`,
    birthdate AS `Birthdate`,
    gender AS `Gender`,
    mobile_number AS `Mobile`,
    school_name AS `School`,
    education_level AS `Education`,
    employment_status AS `Employment`
    FROM patients";

// If there are conditions, add WHERE clause
if (!empty($where)) {
    $sql .= " WHERE " . implode(' AND ', $where);
}

$stmt = $connectNow->prepare($sql);

if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $patients = [];
    while ($row = $result->fetch_assoc()) {
        $patients[] = $row;
    }
    echo json_encode([
        "success" => true,
        "patients" => $patients
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "No patients found"
    ]);
}

$stmt->close();
$connectNow->close();
