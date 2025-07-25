import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:starkey_mobile_app/api_connection/api_connection.dart';
import 'package:starkey_mobile_app/utils/activity_logger.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChangePasswordScreen({super.key, required this.userData});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late int userId;
  late String username;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Store new password input for live validation feedback
  String _newPasswordInput = '';

  // Password validation rules
  final List<Map<String, dynamic>> passwordRules = [
    {
      'label': 'Minimum 8 characters',
      'check': (String value) => value.length >= 8,
    },
    {
      'label': 'At least 1 uppercase letter',
      'check': (String value) => RegExp(r'[A-Z]').hasMatch(value),
    },
    {
      'label': 'At least 1 lowercase letter',
      'check': (String value) => RegExp(r'[a-z]').hasMatch(value),
    },
    {
      'label': 'At least 1 number',
      'check': (String value) => RegExp(r'\d').hasMatch(value),
    },
    {
      'label': 'At least 1 special character',
      'check': (String value) => RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value),
    },
    {
      'label': 'No spaces allowed',
      'check': (String value) => !value.contains(' '),
    },
  ];

  @override
  void initState() {
    super.initState();
    userId = widget.userData['UserID'];
    username = widget.userData['Username'] ?? '';
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _verifyOldPassword() async {
    final response = await http.post(
      Uri.parse(ApiConnection.verifyPassword),
      body: {
        'username': username,
        'password': _oldPasswordController.text,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<void> _changePassword() async {
    setState(() => _isLoading = true);
    try {
      final isOldPasswordCorrect = await _verifyOldPassword();
      if (!isOldPasswordCorrect) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Old password is incorrect.')),
        );

        await ActivityLogger.log(
          userId: userId,
          actionType: 'UpdatePassword',
          description: 'Attempted password change with incorrect old password',
          status: 'Failed',
        );
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConnection.updateProfile),
        body: {
          'username': username,
          'old_username': username,
          'FirstName': widget.userData['FirstName'],
          'LastName': widget.userData['LastName'],
          'Gender': widget.userData['Gender'],
          'Birthdate': widget.userData['Birthdate'],
          'PhoneNumber': widget.userData['PhoneNumber'],
          'PasswordHash': _newPasswordController.text,
        },
      );

      setState(() => _isLoading = false);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await ActivityLogger.log(
          userId: userId,
          actionType: 'UpdatePassword',
          description: 'Password changed successfully',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
        Navigator.pop(context);
      } else {
        await ActivityLogger.log(
          userId: userId,
          actionType: 'UpdatePassword',
          description: 'Server error during password change',
          status: 'Failed',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to change password.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );

      await ActivityLogger.log(
        userId: userId,
        actionType: 'UpdatePassword',
        description: 'Exception during password change: $e',
        status: 'Failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your old password' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (value) {
                  setState(() {
                    _newPasswordInput = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) {
                  final unmet = passwordRules.where((rule) => !(rule['check'](value ?? '') as bool)).toList();
                  if (value == null || value.isEmpty) {
                    return 'Enter your new password';
                  }
                  if (unmet.isNotEmpty) {
                    return 'Password does not meet all requirements';
                  }
                  return null;
                },
              ),

              // Password rules feedback UI:
              const SizedBox(height: 8),
              ...passwordRules.map((rule) {
                bool isMet = rule['check'](_newPasswordInput);
                return Row(
                  children: [
                    Icon(
                      isMet ? Icons.check_circle : Icons.cancel,
                      color: isMet ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rule['label'],
                      style: TextStyle(
                        color: isMet ? Colors.green : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList(),

              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirm your new password';
                  if (value != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            if (_oldPasswordController.text == _newPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New password cannot be the same as old password')),
                              );
                              return;
                            }
                            _changePassword();
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
