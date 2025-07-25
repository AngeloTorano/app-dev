import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection/api_connection.dart';
import 'main.dart';
import 'utils/activity_logger.dart'; 

class ResetPasswordScreen extends StatefulWidget {
  final String username;
  const ResetPasswordScreen({super.key, required this.username});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _password = '';

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
      'check': (String value) =>
          RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value),
    },
    {
      'label': 'No spaces allowed',
      'check': (String value) => !value.contains(' '),
    },
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse(ApiConnection.resetPassword),
      body: {
        'username': widget.username,
        'password': _passwordController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await ActivityLogger.log(
        userId: null,
        actionType: 'UpdatePassword',
        description: "User '${widget.username}' reset their password via OTP",
      );

      Fluttertoast.showToast(msg: "Password reset successful");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      Fluttertoast.showToast(
        msg: data['message'] ?? "Password reset failed",
        backgroundColor: Colors.red,
      );
    }
  } catch (e) {
    Fluttertoast.showToast(
      msg: "Error: ${e.toString()}",
      backgroundColor: Colors.red,
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (value) {
                  setState(() => _password = value);
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  final unmet = passwordRules
                      .where((rule) => !(rule['check'](value ?? '') as bool))
                      .toList();
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (unmet.isNotEmpty) {
                    return 'Password does not meet all requirements';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ...passwordRules.map((rule) {
                bool isMet = rule['check'](_password);
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
              }),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50, // fixed height prevents resizing
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146884),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'RESET PASSWORD',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
