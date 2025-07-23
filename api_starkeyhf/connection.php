<?php
$serverHost = "localhost";
$user = "root";
$password = "";
$database = "starkeyhf";

$connectNow = new mysqli($serverHost, $user, $password, $database);

if ($connectNow->connect_error) {
    die(json_encode([
        "success" => false,
        "error" => "Connection failed: " . $connectNow->connect_error
    ]));
}
