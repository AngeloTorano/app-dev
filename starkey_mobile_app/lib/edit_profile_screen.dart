import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:starkey_mobile_app/api_connection/api_connection.dart';
import 'package:starkey_mobile_app/change_password_screen.dart';
import 'package:starkey_mobile_app/utils/activity_logger.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late String _birthday;
  DateTime? _birthdateDate;
  String _age = '';
  File? _avatarImage;
  bool _isUploading = false;
  bool _isLoadingAvatar = false;
  String? _avatarUrl;
  ImageProvider? _cachedImageProvider;

  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  late TextEditingController _ageController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late String _oldUsername;
  late int _userId;

  bool _hasLoggedUpdate = false;
  bool _hasChanges = false;
  late Map<String, dynamic> _initialValues;

  @override
  void initState() {
    super.initState();
    final userData = widget.userData ?? {};
    _userId = int.tryParse(userData['UserID'].toString()) ?? 0;
    _firstNameController = TextEditingController(
      text: userData['FirstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: userData['LastName'] ?? '',
    );
    _usernameController = TextEditingController(
      text: userData['Username'] ?? '',
    );
    _oldUsername = userData['Username'] ?? '';
    _phoneController = TextEditingController(
      text: userData['PhoneNumber'] ?? '',
    );
    _gender = userData['Gender'] ?? '';
    _birthday = userData['Birthdate'] ?? '';
    _birthdateDate = _birthday.isNotEmpty ? DateTime.tryParse(_birthday) : null;
    _age = _birthdateDate != null
        ? _calculateAge(_birthdateDate!).toString()
        : '';
    _birthdayController = TextEditingController(
      text: _birthdateDate != null ? _formatDate(_birthdateDate!) : '',
    );
    _ageController = TextEditingController(text: _age);
    _loadAvatar();

    _initialValues = {
      'FirstName': _firstNameController.text,
      'LastName': _lastNameController.text,
      'Username': _usernameController.text,
      'PhoneNumber': _phoneController.text,
      'Gender': _gender,
      'Birthdate': _birthday,
    };

    _firstNameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
    _usernameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final hasAnyChanges =
        _firstNameController.text != _initialValues['FirstName'] ||
        _lastNameController.text != _initialValues['LastName'] ||
        _usernameController.text != _initialValues['Username'] ||
        _phoneController.text != _initialValues['PhoneNumber'] ||
        _gender != _initialValues['Gender'] ||
        _birthday != _initialValues['Birthdate'];
    if (_hasChanges != hasAnyChanges) {
      setState(() {
        _hasChanges = hasAnyChanges;
      });
    }
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

  Future<String?> _fetchAvatarUrl() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConnection.uploadAvatar),
        body: {'action': 'get', 'user_id': _userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['avatar_url'] ?? data['avatar'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Fetch avatar URL error: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Avatar'),
          content: const Text('Are you sure you want to update your avatar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (shouldUpdate == true) {
        setState(() => _isUploading = true);
        try {
          final uploadSuccess = await _uploadAvatar(File(pickedFile.path));
          if (uploadSuccess) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('avatar_path_$_userId'); // Clear old cache
            await _loadAvatar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar updated successfully!')),
            );
            await ActivityLogger.log(
              userId: _userId,
              actionType: 'UpdateAvatar',
              description: 'User updated their avatar',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload avatar')),
            );
          }
        } finally {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<bool> _uploadAvatar(File imageFile) async {
    try {
      final compressedImage = await _compressImage(imageFile);
      final url = Uri.parse(ApiConnection.uploadAvatar);
      var request = http.MultipartRequest('POST', url)
        ..fields['action'] = 'upload'
        ..fields['user_id'] = _userId.toString()
        ..files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            compressedImage.path,
            filename: 'avatar_$_userId.jpg',
          ),
        );

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      return jsonData['status'] == 'success';
    } catch (e) {
      debugPrint('Upload Exception: $e');
      return false;
    }
  }

  Future<File> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.absolute.path}_compressed.jpg',
      quality: 80,
    );
    return File(result?.path ?? file.path);
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  ImageProvider _getAvatarImageProvider() {
    if (_cachedImageProvider != null) return _cachedImageProvider!;

    if (_avatarImage != null) {
      _cachedImageProvider = FileImage(_avatarImage!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      _cachedImageProvider = NetworkImage(_avatarUrl!);
    } else if (widget.userData?['avatar'] != null &&
        widget.userData!['avatar'].toString().isNotEmpty) {
      _cachedImageProvider = NetworkImage(widget.userData!['avatar']);
    } else {
      _cachedImageProvider = const AssetImage('assets/user_profile.png');
    }

    return _cachedImageProvider!;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      ),
      body: (_isUploading || _isLoadingAvatar)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarImageProvider(),
                            child:
                                _avatarImage == null &&
                                    _avatarUrl == null &&
                                    (widget.userData?['avatar'] == null ||
                                        widget.userData!['avatar']
                                            .toString()
                                            .isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: PopupMenuButton<String>(
                              icon: const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color.fromRGBO(
                                  20,
                                  104,
                                  132,
                                  1,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              onSelected: (value) {
                                if (value == 'gallery') {
                                  _pickImage(ImageSource.gallery);
                                } else if (value == 'camera') {
                                  _pickImage(ImageSource.camera);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'gallery',
                                  child: Text('Upload from Gallery'),
                                ),
                                PopupMenuItem(
                                  value: 'camera',
                                  child: Text('Take a Picture'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your first name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your last name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender.isNotEmpty ? _gender : null,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gender = value ?? '';
                          _onFormChanged();
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select gender'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _birthdayController,
                      decoration: InputDecoration(
                        labelText: 'Birthday',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Color.fromRGBO(20, 104, 132, 1),
                          ),
                          onPressed: () async {
                            DateTime initialDate =
                                _birthdateDate ?? DateTime(2000, 1, 1);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _birthdateDate = picked;
                                _birthday = _formatDate(picked);
                                _age = _calculateAge(picked).toString();
                                _birthdayController.text = _birthday;
                                _ageController.text = _age;
                                _onFormChanged();
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) => _birthdateDate == null
                          ? 'Please pick your birthday'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              20,
                              104,
                              132,
                              1,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordScreen(
                                  userData: {
                                    'UserID': _userId,
                                    'Username': _usernameController.text,
                                    'FirstName': _firstNameController.text,
                                    'LastName': _lastNameController.text,
                                    'Gender': _gender,
                                    'Birthdate': _birthday,
                                    'PhoneNumber': _phoneController.text,
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text('Change Password'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _hasChanges
                              ? () async {
                                  if (_formKey.currentState!.validate()) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Save Changes'),
                                        content: const Text(
                                          'Are you sure you want to save changes to your profile?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final updatedUserData =
                                          await _updateProfile();
                                      if (!mounted) return;
                                      if (updatedUserData != null) {
                                        Navigator.pop(context, updatedUserData);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to update profile.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              : null,
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<Map<String, dynamic>?> _updateProfile() async {
    final url = Uri.parse(ApiConnection.updateProfile);
    try {
      final response = await http.post(
        url,
        body: {
          'username': _usernameController.text,
          'old_username': _oldUsername,
          'FirstName': _firstNameController.text,
          'LastName': _lastNameController.text,
          'Gender': _gender,
          'Birthdate': _birthday,
          'PhoneNumber': _phoneController.text,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _oldUsername = _usernameController.text;
          if (!_hasLoggedUpdate) {
            await ActivityLogger.log(
              userId: _userId,
              actionType: 'UpdateProfile',
              description: 'User updated their profile',
            );
            _hasLoggedUpdate = true;
          }
          setState(() {
            _hasChanges = false;
            _initialValues = {
              'FirstName': _firstNameController.text,
              'LastName': _lastNameController.text,
              'Username': _usernameController.text,
              'PhoneNumber': _phoneController.text,
              'Gender': _gender,
              'Birthdate': _birthday,
            };
          });
          return data['userData'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
