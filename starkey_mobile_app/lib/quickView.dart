// Make sure this import is present:
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:starkey_mobile_app/api_connection/api_connection.dart';
import 'package:starkey_mobile_app/utils/activity_logger.dart';
import 'package:starkey_mobile_app/patient_history.dart';
import 'package:intl/intl.dart';

class QuickViewScreen extends StatefulWidget {
  final int userId;
  final String roleName;

  const QuickViewScreen({
    super.key,
    required this.userId,
    required this.roleName,
  });

  @override
  State<QuickViewScreen> createState() => _QuickViewScreenState();
}

class _QuickViewScreenState extends State<QuickViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchBy = 'All';
  bool _isLoading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _patients = [];

  final List<String> _searchOptions = [
    'All',
    'SHF Patient ID',
    'Surname',
    'First Name',
    'City/Village',
  ];
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _searchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPatients() async {
    setState(() {
      _isLoading = true;
      _patients = [];
      _hasSearched = true;
    });

    final Map<String, String> paramMap = {
      'SHF Patient ID': 'PatientID',
      'Surname': 'Surname',
      'First Name': 'FirstName',
      'School': 'School',
      'City/Village': 'City',
    };

    final url = Uri.parse(ApiConnection.getUser);

    final Map<String, String> body = {
      'UserID': widget.userId.toString(),
      'Role': widget.roleName,
    };

    if (_searchBy != 'All') {
      final paramKey = paramMap[_searchBy]!;
      body[paramKey] = _searchController.text.trim();
    }

    try {
      print("🔍 Fetching patients with payload: $body");
      final response = await http.post(url, body: body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("🔁 Response data: $data");
        if (data['success'] == true && data['patients'] != null) {
          setState(() {
            _patients = List<Map<String, dynamic>>.from(data['patients']);
          });
        } else {
          _showNoPatientsMessage(data['message'] ?? 'No patients found');
        }
      } else {
        _showErrorMessage('Error fetching patients (status ${response.statusCode})');
      }

      if (_searchBy != 'All' &&
          _searchController.text.trim().isNotEmpty &&
          _patients.isNotEmpty) {
        await ActivityLogger.log(
          userId: widget.userId,
          actionType: 'SearchPatient',
          description: 'User searched for "${_searchController.text.trim()}" by $_searchBy',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Network error');
    }
  }

  void _showNoPatientsMessage(String message) {
    setState(() {
      _patients = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (_searchBy != 'All' && _searchController.text.trim().isNotEmpty) {
      ActivityLogger.log(
        userId: widget.userId,
        actionType: 'SearchPatient',
        description: 'No patients found for "${_searchController.text.trim()}" by $_searchBy',
      );
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _sortPatients() {
    setState(() {
      String sortField;
      switch (_searchBy) {
        case 'SHF Patient ID':
          sortField = 'shf_id';
          break;
        case 'Surname':
        case 'First Name':
          sortField = 'Name';
          break;
        case 'City/Village':
          sortField = 'City';
          break;
        default:
          sortField = 'shf_id';
      }

      _patients.sort((a, b) {
        final aValue = a[sortField] ?? '';
        final bValue = b[sortField] ?? '';
        final result = aValue.toString().compareTo(bValue.toString());
        return _ascending ? result : -result;
      });
    });
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF207088), width: 2),
      ),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientRow('SHF ID:', patient['shf_id']),
            _buildPatientRow('Name:', patient['Name']),
            _buildPatientRow('Age:', patient['Age']),
            _buildPatientRow('Birthdate:', _formatDate(patient['Birthdate'])),
            _buildPatientRow('Gender:', patient['Gender']),
            _buildPatientRow('City:', patient['City']),
            _buildPatientRow('Mobile:', patient['Mobile']),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF207088),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientHistoryScreen(
                        userId: widget.userId,
                        patientId: int.tryParse(patient['SHF Patient ID'].toString()) ?? 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return '';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('MMMM d, y').format(date);
    } catch (_) {
      return rawDate.toString();
    }
  }

  Widget _buildPatientRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF207088),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${value ?? ''}',
              style: const TextStyle(
                color: Color(0xFF207088),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Quick View', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {
              setState(() {
                _ascending = !_ascending;
              });
              _sortPatients();
            },
            tooltip: 'Toggle Sort',
          ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Search by:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _searchBy,
                  dropdownColor: const Color.fromRGBO(20, 104, 132, 1),
                  style: const TextStyle(color: Colors.white),
                  items: _searchOptions
                      .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _searchBy = value;
                        _searchController.clear();
                        _patients = [];
                        _hasSearched = false;
                      });
                      _searchPatients();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            AbsorbPointer(
              absorbing: _searchBy == 'All',
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _searchBy == 'All'
                      ? 'Change "Search by" first.'
                      : 'Enter $_searchBy...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_searchBy == 'All') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please change "Search by" to search.')),
                        );
                      } else {
                        _searchPatients();
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                onFieldSubmitted: (_) {
                  if (_searchBy != 'All') _searchPatients();
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_patients.isEmpty && _hasSearched)
              const Text('No patients found.', style: TextStyle(color: Colors.white))
            else
              Expanded(
                child: ListView(
                  children: _patients.map(_buildPatientCard).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
