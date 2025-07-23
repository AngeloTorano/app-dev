import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection/api_connection.dart';
import 'utils/activity_logger.dart';
import 'otp_FP.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starkey App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/starkeyLogo.png', width: 200, height: 200),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF3E61AC)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      Fluttertoast.showToast(
        msg: 'You must agree to the Terms and Conditions',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(ApiConnection.login),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'username': username, 'password': password},
      );

      setState(() => _isLoading = false);
      print('🔁 Login Response: ${response.body}');

      if (!response.body.trim().startsWith('{')) {
        Fluttertoast.showToast(
          msg: 'Server error. Please try again later.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final data = json.decode(response.body);
      final message = data['message'] ?? 'Invalid username or password';

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['userData'];
        final userId = int.tryParse(userData['UserID'].toString()) ?? 0;

        await ActivityLogger.log(
          userId: userId,
          actionType: 'Login',
          description: 'User "$username" logged in successfully',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(userData: userData),
          ),
        );
      } else {
        final lockMatch = RegExp(r'Try again in (\d+)s').firstMatch(message);
        if (lockMatch != null) {
          final seconds = lockMatch.group(1) ?? '30';

          Fluttertoast.showToast(
            msg: 'Account is locked. Please wait $seconds seconds.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );

          await ActivityLogger.log(
            userId: null,
            actionType: 'Login',
            description:
                'Blocked login for "$username" — Account locked for $seconds seconds',
            status: 'Failed',
          );
        } else if (message.toLowerCase().contains('user not found')) {
          Fluttertoast.showToast(
            msg: 'No account found with username "$username".',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );

          await ActivityLogger.log(
            userId: null,
            actionType: 'Login',
            description: 'Failed login attempt for "$username" — $message',
            status: 'Failed',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Network Exception: $e');
      Fluttertoast.showToast(
        msg: 'Network error. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SizedBox(
          height: 350,
          width: 300,
          child: SingleChildScrollView(
            child: const Text(
              '''DATA PRIVACY AND MEDICAL RECORDS DISCLOSURE IN THE PHILIPPINES
Compliance with RA 10173 – The Data Privacy Act of 2012

🔐 YOUR OBLIGATION: KEEP PATIENT RECORDS CONFIDENTIAL
Medical records are classified as Sensitive Personal Information. Unauthorized access, use, or disclosure can lead to fines, imprisonment, and civil damages.

🧾 COVERED BY LAW:
• 1987 Constitution – Right to Privacy
• Data Privacy Act of 2012 (RA 10173)
• IRR of the DPA & NPC Circulars
• DOH Administrative Orders & PMA Code of Ethics

✅ DISCLOSURE IS ONLY LEGAL WHEN:
📃 With Informed, Written Consent
- Clearly states purpose, scope, and who receives the info
- Can be revoked at any time

⚖️ With a Valid Court Order or Subpoena
- Must verify authenticity before complying

🚑 In Emergencies
- Life-threatening situations requiring immediate care

🧪 For Public Health or Research
- Must be authorized, anonymized, or with consent

👩‍⚕️ HEALTHCARE PROVIDERS MUST:
• Appoint a Data Protection Officer (DPO)
• Maintain organizational, physical, and technical safeguards
• Execute Data Processing Agreements with third parties (e.g., HMOs, billing services)
• Report data breaches to the NPC within the required timeframe

🧍‍♂️ PATIENT RIGHTS UNDER THE LAW:
🧠 Right to Be Informed
📂 Right to Access Records
✏️ Right to Correct Errors
❌ Right to Erasure or Blocking
🛑 Right to Object to Processing
💸 Right to Claim Damages

🚨 PENALTIES FOR VIOLATIONS:
📄 Administrative Fines
⚖️ Civil Damages
🚔 Criminal Liability (Fines + Imprisonment)

✅ BEST PRACTICES CHECKLIST:
✔️ Always obtain and record written consent
✔️ Limit data access based on role/responsibility
✔️ Regularly train staff and conduct audits
✔️ Prepare a data breach response plan
✔️ Keep disclosure logs (date, purpose, recipient, scope)
''',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF146884),
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
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
              height: MediaQuery.of(context).size.height * .72,
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your username'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OtpFP(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() => _agreedToTerms = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
