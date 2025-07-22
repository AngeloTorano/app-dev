import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:starkey_mobile_app/api_connection/api_connection.dart';

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

  Widget _buildSectionItems(Map<String, dynamic> sections) {
    List<Widget> items = [];
    if (sections.containsKey('general_hearing_questions')) {
      items.add(buildGeneralHearingQuestions(sections));
    } else {
      sections.forEach((key, value) {
        if (key != 'visit' && value != null) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                key.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          );
          if (value is Map<String, dynamic>) {
            value.forEach((field, content) {
              items.add(Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                child: Text('$field: ${content ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
              ));
            });
          }
          items.add(const SizedBox(height: 8));
        }
      });
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
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
  
  Widget buildGeneralHearingQuestions(Map<String, dynamic> data) {
    final earScreening = data['ear_screening'] ?? {};
    final otoscopy = data['otoscopy'] ?? {};
    final hearingScreening = data['hearing_screening'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('GENERAL HEARING QUESTIONS'),
        const SizedBox(height: 10),
        radioQuestion("1. Do you have a hearing loss?", ["No", "Undecided", "Yes"], mapIndex(data['general_hearing_questions']?['has_hearing_loss'], undecided: true)),
        radioQuestion("2. Do you use sign language?", ["No", "A little", "Yes"], mapIndex(data['general_hearing_questions']?['uses_sign_language'])),
        radioQuestion("3. Do you use speech?", ["No", "A little", "Yes"], mapIndex(data['general_hearing_questions']?['uses_speech'])),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("4. Hearing Loss Cause", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
                child: Text(data['general_hearing_questions']?['hearing_loss_cause'] ?? 'N/A'),
              ),
            ],
          ),
        ),
        radioQuestion("5. Do you experience a ringing sensation in your ear?", ["No", "Undecided", "Yes"], mapIndex(data['general_hearing_questions']?['has_ringing'], undecided: true)),
        radioQuestion("6. Do you have pain in your ear?", ["No", "A little", "Yes"], mapIndex(data['general_hearing_questions']?['has_pain'])),
        radioQuestion("7. How satisfied are you with your hearing?", ["Unsatisfied", "Undecided", "Satisfied"], mapSatisfactionIndex(data['general_hearing_questions']?['hearing_satisfaction'])),
        radioQuestion("8. Do you ask people to repeat themselves or speak louder in conversation?", ["No", "Sometimes", "Yes"], mapIndex(data['general_hearing_questions']?['asks_to_repeat'], undecided: true)),

        const SizedBox(height: 5),
        sectionTitle('EAR SCREENING'),
        const SizedBox(height: 10),
        radioQuestion(
          "Ear Clear for Impressions:",
          ["No", "Yes"],
          earScreening['is_clear'] == 'Yes' ? 1 : 0,
        ),

        const SizedBox(height: 5),
        sectionTitle('OTOSCOPY'),
        const SizedBox(height: 10),

        Table(
          columnWidths: const {
            0: FlexColumnWidth(3), // Condition label
            1: FlexColumnWidth(1), // Left
            2: FlexColumnWidth(1), // Right
          },
          children: [
            // Header row with LEFT and RIGHT labels
            const TableRow(
              children: [
                SizedBox(), // Empty for the condition label
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'LEFT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'RIGHT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _otoscopyRow('Wax', otoscopy['wax']),
            _otoscopyRow('Infection', otoscopy['infection']),
            _otoscopyRow('Perforation', otoscopy['perforation']),
            _otoscopyRow('Tinnitus', otoscopy['tinnitus']),
            _otoscopyRow('Atresia', otoscopy['atresia']),
            _otoscopyRow('Implant', otoscopy['implant']),
            _otoscopyRow('Other', otoscopy['other']),
            _otoscopyRow('Medical Recommendation', otoscopy['med_recommendation']),
          ],
        ),


        const SizedBox(height: 16),
        const Text('Medical Given:'),
        Wrap(
          spacing: 10,
          children: ['Antibiotic', 'Analgesic', 'Antiseptic', 'Antifungal'].map((med) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: otoscopy['medication_given']?.contains(med) ?? false,
                  onChanged: null,
                ),
                Text(med),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        const Text('Ears Clear for Impressions:'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('LEFT:'),
                const SizedBox(width: 12),
                Radio(value: 'No', groupValue: otoscopy['ears_clear_for_assessment_left'], onChanged: null),
                const Text('No'),
                const SizedBox(width: 12),
                Radio(value: 'Yes', groupValue: otoscopy['ears_clear_for_assessment_left'], onChanged: null),
                const Text('Yes'),
              ],
            ),
            Row(
              children: [
                const Text('RIGHT:'),
                const SizedBox(width: 8),
                Radio(value: 'No', groupValue: otoscopy['ears_clear_for_assessment_right'], onChanged: null),
                const Text('No'),
                const SizedBox(width: 12),
                Radio(value: 'Yes', groupValue: otoscopy['ears_clear_for_assessment_right'], onChanged: null),
                const Text('Yes'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Comments:'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: (otoscopy['comments'] == null || otoscopy['comments'].toString().trim().isEmpty)
              ? 'N/A'
              : otoscopy['comments'],
          maxLines: 3,
          enabled: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      
      //HEARING SCREENING
      const SizedBox(height: 15),
      sectionTitle('HEARING SCREENING'),
      const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Screening Method:"),
            const SizedBox(height: 6),
            Row(
              children: [
                Radio<String>(
                  value: 'Audiogram',
                  groupValue: hearingScreening['method'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('Audiogram'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'WFA® Voice Test',
                  groupValue: hearingScreening['method'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('WFA® Voice Test'),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Left Ear:"),
            Row(
              children: [
                Radio<String>(
                  value: 'Pass',
                  groupValue: hearingScreening['left_result'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('Pass'),
                const SizedBox(width: 50),
                Radio<String>(
                  value: 'Fail',
                  groupValue: hearingScreening['left_result'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('Fail'),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Right Ear:"),
            Row(
              children: [
                Radio<String>(
                  value: 'Pass',
                  groupValue: hearingScreening['right_result'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('Pass'),
                const SizedBox(width: 50),
                Radio<String>(
                  value: 'Fail',
                  groupValue: hearingScreening['right_result'] ?? 'N/A',
                  onChanged: null,
                ),
                const Text('Fail'),
              ],
            ),
            const SizedBox(height: 10),
            const Text("How satisfied are you with your hearing?"),
            const SizedBox(height: 6),
            Row(
              children: [
                Radio<String>(
                  value: 'Unsatisfied',
                  groupValue: hearingScreening['hearing_satisfaction'] ?? 'N/A',
                  onChanged: null,
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Unsatisfied'),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Undecided',
                  groupValue: hearingScreening['hearing_satisfaction'] ?? 'N/A',
                  onChanged: null,
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Undecided'),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Satisfied',
                  groupValue: hearingScreening['hearing_satisfaction'] ?? 'N/A',
                  onChanged: null,
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Satisfied'),
              ],
            ),
          ],
        ),

        //EAR IMPRESSIONS
        const SizedBox(height: 5),
        sectionTitle('EAR IMPRESSIONS'),
        Row(
          children: [
            const Text('Ear Impressions:'),
            const SizedBox(width: 12),
            Radio(value: 'Left', groupValue: earScreening['impressions_collected'], onChanged: null),
            const Text('Left'),
            const SizedBox(width: 12),
            Radio(value: 'Right', groupValue: earScreening['impressions_collected'], onChanged: null),
            const Text('Right'),
            ],
          ),
        const Text('Comments:'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: (earScreening['comments'] == null || earScreening['comments'].toString().trim().isEmpty)
              ? 'N/A'
              : earScreening['comments'],
          maxLines: 3,
          enabled: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        //FINAL QUALITY CONTROL
      ],
    );
  }

  Widget radioQuestion(String question, List<String> options, int? selectedIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 20,
            children: List.generate(
              options.length,
              (i) => _buildInlineRadio(options[i], selectedIndex, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineRadio(String label, int? selectedIndex, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selectedIndex == index ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selectedIndex == index ? Colors.teal : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(label),
        const SizedBox(width: 16),
      ],
    );
  }

  int? mapIndex(dynamic value, {bool undecided = false}) {
    if (value == null) return null;
    if (undecided) return value == 1 ? 2 : value == 0 ? 0 : 1;
    return value == 1 ? 2 : 0;
  }

  int? mapSatisfactionIndex(dynamic value) {
    if (value == null) return null;
    int val = int.tryParse(value.toString()) ?? 0;
    if (val >= 6) return 2;
    if (val == 5) return 1;
    return 0;
  }

  TableRow _otoscopyRow(String label, dynamic value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label),
      ),
      Center(
        child: Radio(
          value: 'Left',
          groupValue: value,
          onChanged: null,
        ),
      ),
      Center(
        child: Radio(
          value: 'Right',
          groupValue: value,
          onChanged: null,
        ),
      ),
    ]);
  }

  Widget sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.blueGrey.shade100,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
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
                    ...phaseRecords.entries.map((entry) => _buildPhaseSection(entry.key, entry.value)),
                  ],
                ),
    );
  }
}
