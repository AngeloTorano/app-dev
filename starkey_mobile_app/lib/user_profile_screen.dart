import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'edit_profile_screen.dart';
import 'utils/activity_logger.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const UserProfileScreen({super.key, this.userData});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _avatarImage = File(path);
      });
    } else {
      setState(() {
        _avatarImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData ?? {};
    final name = "${userData['FirstName'] ?? ''} ${userData['LastName'] ?? ''}".trim();
    final position = "${userData['RoleName'] ?? 'Position'}";

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
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: _avatarImage != null
                        ? FileImage(_avatarImage!)
                        : const AssetImage('assets/user_profile.png') as ImageProvider,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name.isEmpty ? 'User' : name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(20, 104, 132, 1),
                    ),
                  ),
                  Text(
                    position,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color.fromRGBO(20, 104, 132, 1),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // My Profile
                  _buildProfileAction(
                    icon: Icons.person,
                    label: 'My Profile',
                    onTap: () async {
                      final updatedUserData = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: userData),
                        ),
                      );
                      if (updatedUserData != null) {
                        setState(() {
                          userData.addAll(updatedUserData);
                        });
                        _loadAvatar();
                     
                      }
                    },
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Language
                  _buildProfileAction(
                    icon: Icons.settings,
                    label: 'Language',
                    onTap: null,
                    trailing: StatefulBuilder(
                      builder: (context, setState) {
                        String selectedLanguage = 'English';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: selectedLanguage,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              items: const [
                                DropdownMenuItem(value: 'English', child: Text('English')),
                                DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedLanguage = value;
                                  });
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout
                  _buildProfileAction(
                    icon: Icons.logout,
                    label: 'Log Out',
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        // ✅ Log Logout
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
                    },
                    trailing: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromRGBO(20, 104, 132, 1)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.white,
      minLeadingWidth: 0,
    );
  }
}
