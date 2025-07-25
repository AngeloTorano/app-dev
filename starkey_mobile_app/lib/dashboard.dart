import 'package:flutter/material.dart';
import 'quickView.dart';
import 'sms.dart';
import 'logs.dart';
import 'user_profile_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_connection/api_connection.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/gestures.dart';


class Dashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const Dashboard({super.key, this.userData});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? _avatarUrl;
  bool _isLoadingAvatar = false;
  late TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _loadAvatar();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    super.dispose();
  }

void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Center(
        child: Text(
          'Terms and Conditions for Use of the Starkey Connect Mobile Application',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        height: 400,
        width: 300,
        child: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.5),
              children: [
                TextSpan(
                  text: 'IMPORTANT NOTICE TO EMPLOYEES\n\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'As an employee of Starkey Hearing Foundation, Philippines, you are granted access to the Starkey Connect mobile application (“the App”) solely for the purpose of supporting healthcare-related functions in line with your assigned role. Your use of the App is subject to the following terms and conditions, grounded in the ',
                ),
                TextSpan(
                  text: 'Data Privacy Act of 2012 (DPA)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' and relevant Department of Health (DOH) guidelines. By using this App, you acknowledge and agree to comply with the following:\n\n',
                ),
                // Sections
                TextSpan(
                  text: '1. Lawful and Ethical Use\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Use the App lawfully, fairly, and ethically.\n'),
                TextSpan(text: '• Access data only on a '),
                TextSpan(
                  text: '“need-to-know” basis.\n\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '2. Data Privacy and Confidentiality\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Keep all patient information strictly confidential.\n'),
                TextSpan(text: '• Do not share data via unsecured platforms.\n\n'),
                TextSpan(
                  text: '3. Consent and Transparency\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Obtain consent before processing data.\n'),
                TextSpan(text: '• Inform patients how data will be used.\n\n'),
                TextSpan(
                  text: '4. Data Minimization\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Collect and process only necessary data.\n\n'),
                TextSpan(
                  text: '5. Access Control\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Access is based on roles and responsibilities.\n'),
                TextSpan(text: '• Do not share login credentials.\n\n'),
                TextSpan(
                  text: '6. Security Measures\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Use passwords and encrypted channels.\n'),
                TextSpan(text: '• Report lost or compromised devices.\n\n'),
                TextSpan(
                  text: '7. Physical and Digital Security\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Do not store or export patient data improperly.\n'),
                TextSpan(text: '• Properly dispose of printed records.\n\n'),
                TextSpan(
                  text: '8. Reporting of Data Breaches\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Report breaches to the DPO immediately.\n'),
                TextSpan(text: '• Failure to report may result in legal action.\n\n'),
                TextSpan(
                  text: '9. Patient Rights\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Respect patients’ rights to access, correct, or object to their data usage.\n\n'),
                TextSpan(
                  text: '10. Training and Compliance\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '• Stay updated through organizational training.\n\n'),
                TextSpan(
                  text: '11. Disciplinary and Legal Consequences\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '• Unauthorized use may lead to suspension, termination, or legal consequences under the DPA.\n\n',
                ),
                TextSpan(
                  text: 'Acknowledgement\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: 'By proceeding, you acknowledge that:\n'),
                TextSpan(text: '• You have read and understood these Terms.\n'),
                TextSpan(text: '• You agree to comply fully with them.\n'),
                TextSpan(text: '• You accept your responsibilities under the DPA and Foundation policies.\n\n'),
                TextSpan(
                  text: 'If you do not agree, please exit the app and inform your supervisor immediately.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
      ],
    ),
  );
}



  Future<void> _loadAvatar() async {
    final userData = widget.userData;
    if (userData == null || userData['UserID'] == null) return;

    setState(() => _isLoadingAvatar = true);

    try {
      final userId = userData['UserID'].toString();
      final response = await http.post(
        Uri.parse(ApiConnection.uploadAvatar),
        body: {'action': 'get', 'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _avatarUrl = data['data']['avatar_url']);
        }
      }
    } finally {
      setState(() => _isLoadingAvatar = false);
    }
  }

  ImageProvider _getAvatarImageProvider() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }

    final userAvatarUrl = widget.userData?['avatar'];
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      return NetworkImage(userAvatarUrl);
    }

    return const AssetImage('assets/user_profile.png');
  }

  Future<Map<String, int>> fetchStatistics() async {
    final response = await http.get(
      Uri.parse(ApiConnection.dashboardStats),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final stats = data['data'];
        return {
          'patients_served': stats['patients_served'] ?? 0,
          'patients_fitted': stats['patients_fitted'] ?? 0,
          'hearing_aids_fitted': stats['hearing_aids_fitted'] ?? 0,
          'mission_cities': stats['mission_cities'] ?? 0,
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to load stats');
      }
    } else {
      throw Exception('Failed with status ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
    '${widget.userData?['FirstName'] ?? ''} ${widget.userData?['LastName'] ?? ''}';
    final roleName = (widget.userData?['RoleName'] ?? 'Role').toUpperCase();

    return Scaffold(
      appBar: AppBar(
      title: Padding(
        padding: const EdgeInsets.only(top: 10.0), 
        child: Text(
          '$roleName DASHBOARD',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 21,
          ),
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
    ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAvatar();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                color: const Color.fromRGBO(20, 104, 132, 1),
                padding: const EdgeInsets.fromLTRB(16.0, 3.0, 16.0, 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(userData: widget.userData),
                          ),
                        );
                        await _loadAvatar(); // Refresh avatar after return
                      },
                      child: _isLoadingAvatar
                          ? const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white,
                              child: CircularProgressIndicator(),
                            )
                          : CircleAvatar(
                              radius: 25,
                              backgroundImage: _getAvatarImageProvider(),
                              child:
                                  _avatarUrl == null &&
                                      (widget.userData?['avatar'] == null ||
                                          widget.userData!['avatar'].isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          name.trim().isEmpty ? 'User' : name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavButton(Icons.dashboard, 'Quick View', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuickViewScreen(
                          userId: widget.userData?['UserID'] ?? 0,
                          roleName: widget.userData?['RoleName'] ?? '', // ✅ pass role name
                        ),
                      ),
                    );
                  }),
                    _buildNavButton(Icons.sms, 'SMS', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SmsScreen(),
                        ),
                      );
                    }),
                    _buildNavButton(Icons.history, 'Activity Log', () {
                    print("userData: ${widget.userData}");
                    print("Navigating to ActivityLogScreen with role: ${widget.userData?['RoleName']}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityLogScreen(
                          userId: widget.userData?['UserID'] ?? 0,
                          role: widget.userData?['RoleName'] ?? 'User',
                        ),
                      ),
                    );
                  }),


                  ],
                ),
              ),
              // ========== TOMTOM WEBVIEW MAP ==========
              Container(
                height: 240,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _TomTomWebMap(
                    apiKey: 'MP7TrwgffBilV5TD6SmqTAGZIiK0Firj',
                  ),
                ),
              ),
              // ========== END MAP ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<Map<String, int>>(
                  future: fetchStatistics(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final data = snapshot.data!;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildDataCard(
                            'Patients Served',
                            data['patients_served']!,
                          ),
                          _buildDataCard(
                            'Patients Fitted',
                            data['patients_fitted']!,
                          ),
                          _buildDataCard(
                            'Hearing Aids Fitted',
                            data['hearing_aids_fitted']!,
                          ),
                          _buildDataCard(
                            'Mission Cities',
                            data['mission_cities']!,
                          ),
                        ],
                      );
                    } else {
                      return const Text('No statistics available.');
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 1.0, bottom: 20.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: GestureDetector(
                        onTap: () => _openExternalUrl(
                          'https://www.starkeyhearingfoundation.org/starkey-hearing-institute-philippines/',
                        ),
                        child: Image.asset('assets/logoLogin.png', height: 50),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          children: [
                            const TextSpan(text: 'Connect with Us    ●   '),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon('assets/icons/fb.png', 'https://www.facebook.com/StarkeyHearingFoundation'),
                        _verticalLine(),
                        _socialIcon('assets/icons/linkedin.png', 'https://www.linkedin.com/company/starkey-hearing-foundation/'),
                        _verticalLine(),
                        _socialIcon('assets/icons/ig.png', 'https://www.instagram.com/starkeyhearingfoundation/'),
                        _verticalLine(),
                        _socialIcon('assets/icons/x.png', 'https://twitter.com/starkeyfnd'),
                        _verticalLine(),
                        _socialIcon('assets/icons/yt.png', 'https://www.youtube.com/@StarkeyHearingFndn'),
                      ],
                    ),
                  ),
                    const SizedBox(height: 5),
                    const Text(
                      '© 2025 Starkey Connect',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
    );
  }

Widget _verticalLine() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    height: 24, 
    width: 2,
    color: Colors.white54, 
  );
}

Widget _socialIcon(String assetPath, String url) {
  return IconButton(
    icon: Image.asset(assetPath, width: 24, height: 24),
    onPressed: () => _openExternalUrl(url),
  );
}

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    Fluttertoast.showToast(msg: "Invalid URL.");
    return;
  }

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    Fluttertoast.showToast(msg: "Could not launch the URL.");
  }
}


  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          onPressed: onPressed,
          color: Colors.white,
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildDataCard(String title, int value) {
    return Card(
      elevation: 4,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NumberFormat.decimalPattern().format(value),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(202, 1, 255, 242),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TomTomWebMap extends StatefulWidget {
  final String apiKey;

  const _TomTomWebMap({required this.apiKey});

  @override
  State<_TomTomWebMap> createState() => _TomTomWebMapState();
}

class _TomTomWebMapState extends State<_TomTomWebMap> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _loadCityData();
  }

  Future<void> _loadCityData() async {
    final response = await http.get(Uri.parse(ApiConnection.mapCities));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final cities = jsonData['data'] as List;

        final markersJS = cities.map((city) {
          final cityId = city['city_id'];
          final lat = city['lat'];
          final lon = city['lon'];
          final cityName = jsonEncode(city['city_name']);
          final count = city['patient_count'];

          return '''
            const marker$cityId = new tt.Marker().setLngLat([$lon, $lat]).addTo(map);
            const popup$cityId = new tt.Popup({ offset: 30 }).setHTML("<b>" + $cityName + "</b><br/>Patients: $count");
            marker$cityId.setPopup(popup$cityId);
          ''';
        }).join();

        final htmlContent =
            '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>TomTom Map</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.25.0/maps/maps-web.min.js"></script>
    <link rel="stylesheet" href="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.25.0/maps/maps.css">
    <style>
      html, body, #map {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
      }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        const map = tt.map({
            key: '${widget.apiKey}',
            container: 'map',
            center: [121.0, 14.6],
            zoom: 5,
            style: 'https://api.tomtom.com/style/2/custom/style/dG9tdG9tQEBAVzVIak5Sa1psMEl5Y1VjUDu-_JasLpVOe7ObWhVQUtMj/drafts/0.json?key=${widget.apiKey}'
        });

        map.addControl(new tt.FullscreenControl());
        map.addControl(new tt.NavigationControl());

        $markersJS
    </script>
</body>
</html>
''';

        _controller.loadHtmlString(htmlContent);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
