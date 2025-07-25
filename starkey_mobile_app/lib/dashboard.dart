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

class Dashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const Dashboard({super.key, this.userData});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? _avatarUrl;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
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

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logoLogin.png', height: 40),
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
                padding: const EdgeInsets.all(16.0),
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
                        await _loadAvatar();
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
                            roleName: widget.userData?['RoleName'] ?? '',
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityLogScreen(
                            userId: widget.userData?['UserID'] ?? 0,
                            role: widget.userData?['RoleName'] ?? '',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // ========== TOMTOM WEBVIEW MAP ========== //
              Container(
                height: 240,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: Listener(
                  onPointerDown: (_) {},
                  onPointerMove: (_) {},
                  onPointerUp: (_) {},
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _TomTomWebMap(
                      apiKey: 'MP7TrwgffBilV5TD6SmqTAGZIiK0Firj',
                    ),
                  ),
                ),
              ),
              // ========== END MAP ========== //
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
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
    );
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
    _initializeWebViewController();
    _loadCityData();
  }

  void _initializeWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Set up fullscreen change listeners
            _controller.runJavaScript('''
              // Initialize scroll behavior
              document.body.style.overflow = 'hidden';
              document.getElementById('map').style.overflow = 'hidden';
              
              // Set up fullscreen change listener
              document.addEventListener('fullscreenchange', function() {
                if (document.fullscreenElement) {
                  document.body.style.overflow = 'auto';
                  document.getElementById('map').style.overflow = 'auto';
                } else {
                  document.body.style.overflow = 'hidden';
                  document.getElementById('map').style.overflow = 'hidden';
                }
              });
              
              // Reload map when page is shown
              document.addEventListener('visibilitychange', function() {
                if (!document.hidden) {
                  map.resize();
                }
              });
            ''');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
  }

  Future<void> _loadCityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(ApiConnection.mapCities));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          final cities = jsonData['data'] as List;
          final htmlContent = _buildHtmlContent(cities);
          await _controller.loadHtmlString(htmlContent);
        }
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildHtmlContent(List<dynamic> cities) {
    final markersJS = cities.map((city) {
      final cityId = city['city_id'];
      final lat = city['lat'];
      final lon = city['lon'];
      final cityName = jsonEncode(city['city_name']);
      final count = city['patient_count'];

      return '''
        const markerElement$cityId = document.createElement('div');
        markerElement$cityId.className = 'circle-marker';
        
        const marker$cityId = new tt.Marker({
          element: markerElement$cityId,
          anchor: 'center'
        }).setLngLat([$lon, $lat]).addTo(map);
        
        const popup$cityId = new tt.Popup({ offset: 25 }).setHTML(
          '<div class="popup-content">' +
            '<h4>' + $cityName + '</h4>' +
            '<p>Patients: $count</p>' +
          '</div>'
        );
        marker$cityId.setPopup(popup$cityId);
      ''';
    }).join();

    return '''
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
        touch-action: none;
      }
      
      body:fullscreen #map {
        touch-action: auto;
      }
      
      .circle-marker {
        width: 16px;
        height: 16px;
        border-radius: 50%;
        background-color: #42a5f5;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: 10px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        border: 2px solid white;
      }
      
      .popup-content {
        font-family: Arial, sans-serif;
        padding: 8px;
      }
      
      .popup-content h4 {
        margin: 0 0 4px 0;
        font-size: 14px;
        color: #333;
      }
      
      .popup-content p {
        margin: 0;
        font-size: 12px;
        color: #666;
      }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        // Initialize map
        const map = tt.map({
            key: '${widget.apiKey}',
            container: 'map',
            center: [122.937894, 12.509089],
            zoom: 3.5,
            style: 'https://api.tomtom.com/style/2/custom/style/dG9tdG9tQEBAVzVIak5Sa1psMEl5Y1VjUDu-_JasLpVOe7ObWhVQUtMj/drafts/0.json?key=${widget.apiKey}'
        });

        // Add controls
        map.addControl(new tt.FullscreenControl());

        // Add markers
        $markersJS
        
        // Handle fullscreen changes
        function handleFullscreenChange() {
          if (!document.fullscreenElement) {
            map.dragPan.disable();
            map.touchZoomRotate.disable();
            map.doubleClickZoom.disable();
            map.scrollZoom.disable();
          } else {
            map.dragPan.enable();
            map.touchZoomRotate.enable();
            map.doubleClickZoom.enable();
            map.scrollZoom.enable();
          }
        }
        
        document.addEventListener('fullscreenchange', handleFullscreenChange);
        handleFullscreenChange(); // Initialize
        
        // Reload map when page becomes visible
        document.addEventListener('visibilitychange', function() {
          if (!document.hidden) {
            map.resize();
          }
        });
        
        // Handle page reload
        window.addEventListener('pageshow', function() {
          map.resize();
        });
    </script>
</body>
</html>
''';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes active again
    _loadCityData();
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
