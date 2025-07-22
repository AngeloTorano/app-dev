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

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
        'username': widget.userData['Username'],
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
          userId: widget.userData['UserID'],
          actionType: 'UpdatePassword',
          description: 'Attempted password change with incorrect old password',
          status: 'Failed',
        );
        return;
      }

      final userData = widget.userData;
      final response = await http.post(
        Uri.parse(ApiConnection.updateProfile),
        body: {
          'username': userData['Username'],
          'old_username': userData['Username'],
          'FirstName': userData['FirstName'],
          'LastName': userData['LastName'],
          'Gender': userData['Gender'],
          'Birthdate': userData['Birthdate'],
          'PhoneNumber': userData['PhoneNumber'],
          'PasswordHash': _newPasswordController.text,
        },
      );

      setState(() => _isLoading = false);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await ActivityLogger.log(
          userId: widget.userData['UserID'],
          actionType: 'UpdatePassword',
          description: 'Password changed successfully',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
        Navigator.pop(context);
      } else {
        await ActivityLogger.log(
          userId: widget.userData['UserID'],
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
        userId: widget.userData['UserID'],
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
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your new password' : null,
              ),
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
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
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
