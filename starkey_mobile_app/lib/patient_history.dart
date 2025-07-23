import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:starkey_mobile_app/api_connection/api_connection.dart';
import 'phase1.dart';
import 'phase2.dart';
import 'phase3.dart';

class PatientHistoryScreen extends StatefulWidget {
  final int userId;
  final int patientId;

  const PatientHistoryScreen({
    super.key,
    required this.userId,
    required this.patientId,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  Map<String, List<Map<String, dynamic>>> phaseRecords = {};
  Map<String, bool> isExpandedMap = {};
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? patientInfo;

  @override
  void initState() {
    super.initState();
    fetchPatientHistory();
  }

  Future<void> fetchPatientHistory() async {
    try {
      final uri = Uri.parse(
        '${ApiConnection.hostConnectUser}/get_patient_history.php?patient_id=${widget.patientId}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['phases'] != null) {
          final Map<String, dynamic> phases = data['phases'];
          Map<String, List<Map<String, dynamic>>> grouped = {
            'Phase 1': [],
            'Phase 2': [],
            'Phase 3': [],
          };

          patientInfo = data['patient'];

          phases.forEach((phase, records) {
            for (var record in records) {
              if (grouped.containsKey(phase)) {
                grouped[phase]!.add({
                  'visit_date': record['visit']?['visit_date'] ?? 'N/A',
                  'sections': record,
                });
              } else {
                grouped[phase] = [
                  {
                    'visit_date': record['visit']?['visit_date'] ?? 'N/A',
                    'sections': record,
                  }
                ];
              }
            }
          });

          setState(() {
            phaseRecords = grouped;
            isExpandedMap = {
              for (var key in grouped.keys) key: false,
            };
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            phaseRecords = {};
          });
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget _infoField(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value?.toString() ?? 'N/A'),
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    if (patientInfo == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _infoField('Surname', patientInfo!['Surname'])),
                const SizedBox(width: 12),
                Expanded(child: _infoField('First Name', patientInfo!['First Name'])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoField('Region/District', patientInfo!['Region/District'])),
                const SizedBox(width: 12),
                Expanded(child: _infoField('City/Village', patientInfo!['City/Village'])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoField('Date of Birth', patientInfo!['Date of Birth'])),
                const SizedBox(width: 12),
                Expanded(child: _infoField('Age', patientInfo!['Age'])),
                const SizedBox(width: 12),
                Expanded(child: _infoField('Gender', patientInfo!['Gender'])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoField('Mobile Number', patientInfo!['Mobile Number'])),
                const SizedBox(width: 12),
                Expanded(child: _infoField('Alternative Number', patientInfo!['Alternative Number'])),
              ],
            ),
            const SizedBox(height: 10),
            _infoField('Current Student', patientInfo!['Current Student']),
            const SizedBox(height: 10),
            _infoField('School Name', patientInfo!['School Name']),
            const SizedBox(height: 10),
            _infoField('School Phone Number', patientInfo!['School Phone Number']),
            const SizedBox(height: 10),
            _infoField('Highest Level of Education Attained', patientInfo!['Highest Level of Education Attained']),
            const SizedBox(height: 10),
            _infoField('Employment Status', patientInfo!['Employment Status']),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> historyItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visit Date: ${historyItem['visit_date']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              _buildSectionItems(historyItem['sections']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseSection(String phase, List<Map<String, dynamic>> records) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            title: Text(
              phase,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF207088)),
            ),
            trailing: Icon(isExpandedMap[phase]! ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                isExpandedMap[phase] = !(isExpandedMap[phase] ?? false);
              });
            },
          ),
          if (isExpandedMap[phase]!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: records.map(_buildHistoryCard).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionItems(Map<String, dynamic> sections) {
    if (sections.containsKey('general_hearing_questions')) {
      return phase1(sections);
    } 
    if (sections.containsKey('hearing_aid_fitting')) {
      return phase2(sections);
    }
    if (sections.containsKey('aftercare_assessment')) {
      return phase3(sections);
    }
    
    // If none of the phase keys are found, return an empty container
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
        title: const Text('Patient History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF207088)))
          : hasError
              ? const Center(child: Text('Failed to load data. Please try again later.'))
              : ListView(
                  children: [
                    if (patientInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                        child: Card(
                          color: const Color(0xFFEDF8FB),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Text(
                                  'SHF ID: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF207088)),
                                ),
                                Text(
                                  patientInfo!['SHF ID'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    _buildPatientInfo(),
                    ...phaseRecords.entries.map((entry) => _buildPhaseSection(entry.key, entry.value)),
                  ],
                ),
    );
  }
}