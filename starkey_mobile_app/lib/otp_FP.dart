import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reset_password.dart';
import 'api_connection/api_connection.dart';
import 'utils/activity_logger.dart'; 

class OtpFP extends StatefulWidget {
  const OtpFP({super.key});

  @override
  State<OtpFP> createState() => _OtpFPState();
}

class _OtpFPState extends State<OtpFP> {
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _userDisplayName;

  @override
  void dispose() {
    _usernameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your username.");
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConnection.sendOtp),
        body: {'username': username},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
          _userDisplayName = data['user']?['name'] ?? 'User';
        });
        Fluttertoast.showToast(msg: "OTP sent to your registered number.");
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? "Failed to send OTP",
          backgroundColor: Colors.red,
        );
        if (data['message'] == 'User not found') {
          _usernameController.clear();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Connection error: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
  final otp = _otpController.text.trim();
  if (otp.length != 6) {
    Fluttertoast.showToast(msg: "Enter a valid 6-digit OTP.");
    return;
  }

  setState(() => _isLoading = true);
  try {
    final username = _usernameController.text.trim();
    final response = await http.post(
      Uri.parse(ApiConnection.verifyOtp),
      body: {'username': username, 'otp': otp},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      // ✅ Log OTP verification success
      await ActivityLogger.log(
        userId: null,
        actionType: 'VerifyOTP',
        description: "OTP verified successfully for user '$username'",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(username: username),
        ),
      );
    } else {
      // ✅ Log OTP verification failure
      await ActivityLogger.log(
        userId: null,
        actionType: 'VerifyOTP',
        description: "Failed OTP verification attempt for user '$username'",
        status: 'Failed',
      );

      Fluttertoast.showToast(
        msg: data['message'] ?? "Invalid OTP",
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
      backgroundColor: const Color(0xFF146884),
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
  child: SizedBox(
    height: MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        MediaQuery.of(context).padding.top,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 30),
            Center(
              child: Image.asset(
                'assets/logoLogin.png',
                width: 300,
                height: 300,
              ),
            ),
        Container(
          height: MediaQuery.of(context).size.height * .47,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(50),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  0,
                  100,
                  182,
                ).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.only(
            top: 50,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            children: [
              Text(
                _otpSent ? 'Enter OTP' : 'Forgot Password',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _otpSent
                    ? 'OTP sent to ${_userDisplayName ?? "your account"}'
                    : 'Enter username to receive OTP',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (!_otpSent)
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (_otpSent)
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '6-digit OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(height: 23),
              // Main OTP Button
              SizedBox(
                width: double.infinity,
                height: 50, // Fixed height to prevent resizing on loading
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _otpSent
                          ? _verifyOtp
                          : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFF146884),
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
                      : Text(
                          _otpSent ? 'VERIFY OTP' : 'SEND OTP',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Resend OTP TextButton (only shown when _otpSent is true)
              if (_otpSent)
                SizedBox(
                  height: 40, // Fixed height to keep layout stable
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text('Resend OTP'),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
),
      );
  }
}
