<?php
header('Content-Type: application/json');
require_once '../connection.php';

function getLatLon($cityName) {
    $encodedCity = urlencode($cityName);
    $url = "https://nominatim.openstreetmap.org/search?city={$encodedCity}&country=Philippines&format=json&limit=1";

    $opts = [
        "http" => [
            "header" => "User-Agent: starkey_mobile_app/1.0\r\n"
        ]
    ];
    $context = stream_context_create($opts);
    $response = file_get_contents($url, false, $context);
    $data = json_decode($response, true);

    if (!empty($data)) {
        return [
            'lat' => $data[0]['lat'],
            'lon' => $data[0]['lon']
        ];
    }
    return ['lat' => null, 'lon' => null];
}

$query = "
SELECT 
  c.CityID,
  c.CityName,
  COUNT(p.id) AS patient_count
FROM patients p
JOIN cities c ON p.city_id = c.CityID
GROUP BY c.CityID, c.CityName
ORDER BY patient_count DESC;
";
$result = mysqli_query($connectNow, $query);

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $coords = getLatLon($row['CityName']);
    if ($coords['lat'] && $coords['lon']) {
        $data[] = [
            'city_id' => $row['CityID'],
            'city_name' => $row['CityName'],
            'patient_count' => (int)$row['patient_count'],
            'lat' => (float)$coords['lat'],
            'lon' => (float)$coords['lon'],
        ];
    }
}

echo json_encode([
    'success' => true,
    'data' => $data
]);
