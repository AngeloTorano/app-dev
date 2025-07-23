<?php
header('Content-Type: application/json');
include '../connection.php';

$patient_id = $_GET['patient_id'] ?? null;

if (!$patient_id) {
    echo json_encode(['success' => false, 'message' => 'Missing patient_id']);
    exit;
}

// Fetch patient info with region and city name
$patient_stmt = $connectNow->prepare("
    SELECT 
        p.*, 
        c.CountryName AS country_name, 
        ci.CityName AS city_name 
    FROM patients p
    LEFT JOIN countries c ON p.country_id = c.id
    LEFT JOIN cities ci ON p.city_id = ci.CityID
    WHERE p.id = ?
");
$patient_stmt->bind_param("i", $patient_id);
$patient_stmt->execute();
$patient_result = $patient_stmt->get_result();
$row = $patient_result->fetch_assoc();

if (!$row) {
    echo json_encode(['success' => false, 'message' => 'Patient not found']);
    exit;
}

// Helper to replace null with "N/A"
function na($value) {
    return $value !== null ? $value : 'N/A';
}

// Format patient info
$patient = [
    'SHF ID' => na($row['shf_id']),
    'Surname' => na($row['surname']),
    'First Name' => na($row['first_name']),
    'Region/District' => na($row['country_name']),
    'City/Village' => na($row['city_name']),
    'Gender' => na($row['gender']),
    'Date of Birth' => na($row['birthdate']),
    'Age' => na($row['age']),
    'Mobile Number' => na($row['mobile_number']),
    'Alternative Number' => na($row['alt_number']),
    'Current Student? Y/N' => $row['is_current_student'] ? 'Yes' : 'No',
    'School Name' => na($row['school_name']),
    'School Phone Number' => na($row['school_phone']),
    'Highest Level of Education Attained' => na($row['education_level']),
    'Employment Status' => na($row['employment_status'])
];

// Fetch visits
$visits_stmt = $connectNow->prepare("SELECT * FROM visits WHERE patient_id = ? ORDER BY id ASC");
$visits_stmt->bind_param("i", $patient_id);
$visits_stmt->execute();
$visits_result = $visits_stmt->get_result();

$phases = ['Phase 1' => [], 'Phase 2' => [], 'Phase 3' => []];

while ($visit = $visits_result->fetch_assoc()) {
    $visit_id = $visit['id'];
    $phase = $visit['phase'];

    // Fetch related data for this visit
    $general_hearing = fetchSingle("SELECT * FROM general_hearing_questions WHERE patient_id = ?", [$patient_id]);
    $ear_screening = fetchSingle("SELECT * FROM ear_screening WHERE visit_id = ?", [$visit_id]);
    $otoscopy = fetchSingle("SELECT * FROM otoscopy WHERE visit_id = ?", [$visit_id]);
    $hearing_screening = fetchSingle("SELECT * FROM hearing_screening WHERE visit_id = ?", [$visit_id]);
    $final_qc = fetchSingle("SELECT * FROM final_quality_control WHERE visit_id = ?", [$visit_id]);
    $hearing_aid_fitting = fetchSingle("SELECT * FROM hearing_aid_fitting WHERE visit_id = ?", [$visit_id]);
    $fitting_qc = fetchSingle("SELECT * FROM fitting_quality_control WHERE visit_id = ?", [$visit_id]);
    $counseling = fetchSingle("SELECT * FROM counseling WHERE visit_id = ?", [$visit_id]);
    $aftercare_eval = fetchSingle("SELECT * FROM aftercare_evaluation WHERE visit_id = ?", [$visit_id]);
    $aftercare_services = fetchSingle("SELECT * FROM aftercare_services WHERE visit_id = ?", [$visit_id]);

    // Build phase-specific structure
    if ($phase === 'Phase 1') {
        $phases['Phase 1'][] = [
            'visit' => $visit,
            'general_hearing_questions' => $general_hearing,
            'ear_screening' => $ear_screening, // ✅ Already included
            'otoscopy' => $otoscopy,           // ✅ Already included
            'hearing_screening' => $hearing_screening,
            'final_quality_control' => $final_qc,
        ];
    } elseif ($phase === 'Phase 2') {
        $phases['Phase 2'][] = [
            'visit' => $visit,
            'ear_screening' => $ear_screening,
            'otoscopy' => $otoscopy,
            'hearing_screening' => $hearing_screening,
            'hearing_aid_fitting' => $hearing_aid_fitting,
            'fitting_quality_control' => $fitting_qc,
            'counseling' => $counseling,
            'final_quality_control' => $final_qc,
        ];
    } else {
        $phases['Phase 3'][] = [
            'visit' => $visit,
            'ear_screening_otoscopy' => $otoscopy,
            'aftercare_assessment' => $aftercare_eval,
            'evaluation' => $hearing_screening,
            'services_completed' => $aftercare_services,
            'final_quality_control' => $final_qc,
        ];
    }
}

// Output JSON response
echo json_encode([ 
    'success' => true,
    'patient' => $patient,
    'phases' => $phases
]);

// Reusable fetcher
function fetchSingle($query, $params = []) {
    global $connectNow;

    $stmt = $connectNow->prepare($query);
    if (!$stmt) return null;

    if (!empty($params)) {
        $types = str_repeat('i', count($params)); // assuming integers
        $stmt->bind_param($types, ...$params);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    return $result ? $result->fetch_assoc() : null;
}
?>
