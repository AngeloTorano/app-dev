import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:starkey_mobile_app/api_connection/api_connection.dart';
import 'package:starkey_mobile_app/utils/activity_logger.dart';
import 'package:starkey_mobile_app/patient_history.dart'; 

class QuickViewScreen extends StatefulWidget {
  final int userId;
  const QuickViewScreen({super.key, required this.userId});

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

    Map<String, String> body = {};
    if (_searchBy != 'All') {
      final paramKey = paramMap[_searchBy]!;
      body[paramKey] = _searchController.text;
    }

    try {
      final response = await http.post(url, body: body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['patients'] != null) {
          setState(() {
            _patients = List<Map<String, dynamic>>.from(data['patients']);
          });
        } else {
          setState(() {
            _patients = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'No patients found')),
          );

          if (_searchBy != 'All' && _searchController.text.trim().isNotEmpty) {
            await ActivityLogger.log(
              userId: widget.userId,
              actionType: 'SearchPatientFailed',
              description:
                  'No patients found for "${_searchController.text.trim()}" by $_searchBy',
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching patients')),
        );
      }

      if (_searchBy != 'All' &&
          _searchController.text.trim().isNotEmpty &&
          _patients.isNotEmpty) {
        await ActivityLogger.log(
          userId: widget.userId,
          actionType: 'SearchPatient',
          description:
              'User searched for "${_searchController.text.trim()}" by $_searchBy',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  void _sortPatients() {
    setState(() {
      String sortField;
      switch (_searchBy) {
        case 'SHF Patient ID':
          sortField = 'SHF Patient ID';
          break;
        case 'Surname':
          sortField = 'Surname';
          break;
        case 'First Name':
          sortField = 'FirstName';
          break;
        case 'City/Village':
          sortField = 'City';
          break;
        default:
          sortField = 'SHF Patient ID';
      }

      _patients.sort((a, b) {
        dynamic aValue = a[sortField] ?? '';
        dynamic bValue = b[sortField] ?? '';
        int result;
        if (sortField == 'SHF Patient ID' || sortField == 'Age') {
          int aInt = int.tryParse(aValue.toString()) ?? 0;
          int bInt = int.tryParse(bValue.toString()) ?? 0;
          result = aInt.compareTo(bInt);
        } else {
          result = aValue.toString().compareTo(bValue.toString());
        }
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
            _buildPatientRow('SHF Patient ID:', patient['SHF Patient ID']),
            _buildPatientRow('Name:', patient['Name']),
            _buildPatientRow('Age:', patient['Age']),
            _buildPatientRow('Birthdate:', patient['Birthdate']),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientHistoryScreen(
                        userId: widget.userId,
                        patientId: int.tryParse(
                                patient['SHF Patient ID'].toString()) ??
                            0,
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
        title: const Text(
          'Patient Quick View',
          style: TextStyle(color: Colors.white),
        ),
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
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
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
                          const SnackBar(
                            content:
                                Text('Please change "Search by" to search.'),
                          ),
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
                  if (_searchBy != 'All') {
                    _searchPatients();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_patients.isEmpty && _hasSearched)
              const Text(
                'No patients found.',
                style: TextStyle(color: Colors.white),
              )
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
