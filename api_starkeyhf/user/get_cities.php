<?php
include '../connection.php';
header('Content-Type: application/json');

// Get distinct non-empty cities from patients
$sql = "SELECT DISTINCT CityOrVillage FROM patients WHERE CityOrVillage IS NOT NULL AND CityOrVillage != '' ORDER BY CityOrVillage ASC";
$result = mysqli_query($connectNow, $sql);

$cities = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $cities[] = ['CityName' => $row['CityOrVillage']];
    }
    echo json_encode($cities);
} else {
    echo json_encode(['error' => 'Failed to fetch cities']);
}
?>
