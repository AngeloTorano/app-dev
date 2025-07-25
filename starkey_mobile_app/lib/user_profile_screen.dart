import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:starkey_mobile_app/change_password_screen.dart';
import 'main.dart';
import 'edit_profile_screen.dart';
import 'utils/activity_logger.dart';
import 'api_connection/api_connection.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const UserProfileScreen({super.key, this.userData});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData ?? {};
    final name = "${userData['FirstName'] ?? ''} ${userData['LastName'] ?? ''}".trim();
    final position = userData['RoleName'] ?? 'Position';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : const AssetImage('assets/user_profile.png') as ImageProvider,
                      ),
                      if (_isLoadingAvatar) const CircularProgressIndicator(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(position, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),

                  _buildProfileTile(
                    icon: Icons.person,
                    title: 'My Profile',
                    onTap: () async {
                      final updatedData = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: userData),
                        ),
                      );
                      if (updatedData != null) {
                        setState(() => userData.addAll(updatedData));
                        _loadAvatar();
                      }
                    },
                  ),
                  const SizedBox(height: 12), // Add space between tiles

                  _buildProfileTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangePasswordScreen(userData: userData),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildProfileTile(
                    icon: Icons.info_outline,
                    title: 'Usage Agreement',
                    onTap: () => _showUsageAgreementDialog(context),
                  ),

                  const SizedBox(height: 12),
                  _buildProfileTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: () => _confirmLogout(context, userData),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUsageAgreementDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24), // control outer width
      contentPadding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 10),
      titlePadding: const EdgeInsets.only(top: 20),
      title: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(color: Colors.black87, fontSize: 15),
            children: [
              TextSpan(
                text: '📜 ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Privacy Policy for Starkey Connect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 380,
          maxHeight: 460,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.5),
                    children: [
                      TextSpan(text: 'Effective Date: July 25, 2025\n\n'),
                      TextSpan(text: '1. Introduction\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text:
                            'This Privacy Policy applies to all staff users of the Starkey Connect mobile application, including Admins, City Coordinators, and Country Coordinators. The app is designed exclusively for the use of Starkey Hearing Foundation personnel in managing and monitoring patient data and operational tasks.\n\n',
                      ),
                      TextSpan(text: '2. Information We Collect\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'We collect and store the following data:\n'),
                      TextSpan(text: '• Personal Information: Name, email, role, assigned cities\n'),
                      TextSpan(text: '• Login Credentials: Username and encrypted password\n'),
                      TextSpan(text: '• Activity Logs: Login history, OTP requests, password changes, user actions\n'),
                      TextSpan(text: '• Device Info: App version, device type, IP address\n\n'),
                      TextSpan(text: '3. Purpose of Data Collection\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '• Authenticate users and manage access based on roles\n'),
                      TextSpan(text: '• Track activities for accountability and security\n'),
                      TextSpan(text: '• Assign coordinators to specific regions\n'),
                      TextSpan(text: '• Generate usage and performance reports\n'),
                      TextSpan(text: '• Prevent unauthorized access or data tampering\n\n'),
                      TextSpan(text: '4. Data Use and Disclosure\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Your information is only used internally and is not shared externally except when:\n'),
                      TextSpan(text: '• Required by law or internal audit\n'),
                      TextSpan(text: '• Necessary to investigate unauthorized activity\n'),
                      TextSpan(text: '• Required by IT administrators for maintenance\n\n'),
                      TextSpan(text: '5. Data Security\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'We employ:\n'),
                      TextSpan(text: '• Role-based access control\n'),
                      TextSpan(text: '• Password hashing and OTP verification\n'),
                      TextSpan(text: '• Activity logging\n'),
                      TextSpan(text: '• Encrypted transmission\n'),
                      TextSpan(text: '• Regular system updates\n\n'),
                      TextSpan(text: '6. User Responsibilities\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Staff users must:\n'),
                      TextSpan(text: '• Keep credentials confidential\n'),
                      TextSpan(text: '• Report suspicious activity\n'),
                      TextSpan(text: '• Use system only for authorized purposes\n'),
                      TextSpan(text: '• Never share or misuse patient data\n'),
                      TextSpan(text: 'Violations may result in access suspension or disciplinary action.\n\n'),
                      TextSpan(text: '7. Retention and Deletion\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Data is retained while affiliated with the Foundation and longer if required by audit/legal compliance.\n\n'),
                      TextSpan(text: '8. Policy Updates\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'We may update this policy. Continued app use means acceptance of changes.\n\n'),
                      TextSpan(text: '9. Contact\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'IT Administrator – Starkey Hearing Foundation Philippines\n'),
                      TextSpan(text: '📧 support@starkey.ph\n'),
                      TextSpan(text: '📞 (123) 456-7890\n'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}




  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromRGBO(20, 104, 132, 1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.white,
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ActivityLogger.log(
        userId: userData['UserID'],
        actionType: 'Logout',
        description: 'User logged out',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
