class ApiConnection {
  // Network locations
  // static const hostConnect = 'http://192.168.1.2/api_starkey'; // bahay
  // static const hostConnect = 'http://192.168.195.83/api_starkey'; // school
  static const hostConnect =
      'http://192.168.1.62/api_starkeyhf'; // 🔍 Make sure this IP is correct

  static const hostConnectUser = "$hostConnect/user";

  // Auth & Profile
  static const login = "$hostConnectUser/login.php";
  static const updateProfile = "$hostConnectUser/update_profile.php";
  static const verifyPassword = "$hostConnectUser/verify_password.php";
  static const getUser = "$hostConnectUser/patient.php";

  // OTP & Password Reset
  static const sendOtp = "$hostConnectUser/send_otp.php";
  static const verifyOtp = "$hostConnectUser/verify_otp.php";
  static const resetPassword = "$hostConnectUser/reset_password.php";

  // SMS API
  static const sendSms = "$hostConnectUser/send_sms.php";
  static const getSmsLogs = "$hostConnectUser/get_sms_logs.php";

  // City API
  static const getCities = "$hostConnectUser/get_cities.php";

  // Activity Logs API
  static const getActivityLogs = "$hostConnectUser/get_activity_logs.php";
  static const insertActivityLog = "$hostConnectUser/insert_activity_log.php";
  static const getUserByUsername = "$hostConnectUser/get_user.php";

  // Avatar per user
  static const String uploadAvatar = "$hostConnectUser/upload_avatar.php";

  //new
  static const getPatientHistory = "$hostConnectUser/get_patient_history.php";

  // Dasgboard statistics
  static const dashboardStats = "$hostConnectUser/dashboard_stats.php";

  // WebView
  static const mapCities = "$hostConnectUser/get_city_patient_stats.php";
}
