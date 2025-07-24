import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  File? _avatarImage;
  String? _avatarUrl;
  bool _isLoadingAvatar = false;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _uploadAvatar(File imageFile) async {
    final userData = widget.userData;
    if (userData == null || userData['UserID'] == null) return;

    setState(() => _isLoadingAvatar = true);

    try {
      final userId = userData['UserID'].toString();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConnection.uploadAvatar),
      );

      request.fields['action'] = 'upload';
      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          filename: 'avatar_$userId.jpg',
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() => _avatarUrl = data['data']['avatar_url']);
      }
    } finally {
      setState(() => _isLoadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      await _uploadAvatar(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData ?? {};
    final name = "${userData['FirstName'] ?? ''} ${userData['LastName'] ?? ''}"
        .trim();
    final position = userData['RoleName'] ?? 'Position';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
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
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : const AssetImage('assets/user_profile.png')
                                    as ImageProvider,
                        ),
                        if (_isLoadingAvatar) const CircularProgressIndicator(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      final updatedData =
                          await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(userData: userData),
                            ),
                          );
                      if (updatedData != null) {
                        setState(() => userData.addAll(updatedData));
                        _loadAvatar();
                      }
                    },
                  ),

                  _buildProfileTile(
                    icon: Icons.settings,
                    title: 'Language',
                    onTap: null,
                    trailing: DropdownButton<String>(
                      value: 'English',
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'Filipino',
                          child: Text('Filipino'),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                  ),

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
