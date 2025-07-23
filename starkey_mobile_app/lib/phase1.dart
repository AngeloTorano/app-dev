import 'package:flutter/material.dart';

Widget phase1(Map<String, dynamic> data) {
  final earScreening = data['ear_screening'] ?? {};
  final otoscopy = data['otoscopy'] ?? {};
  final hearingScreening = data['hearing_screening'] ?? {};

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('GENERAL HEARING QUESTIONS'),
      const SizedBox(height: 10),
      _radioQuestion("1. Do you have a hearing loss?", ["No", "Undecided", "Yes"], _mapIndex(data['general_hearing_questions']?['has_hearing_loss'], undecided: true)),
      _radioQuestion("2. Do you use sign language?", ["No", "A little", "Yes"], _mapIndex(data['general_hearing_questions']?['uses_sign_language'])),
      _radioQuestion("3. Do you use speech?", ["No", "A little", "Yes"], _mapIndex(data['general_hearing_questions']?['uses_speech'])),
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
      _radioQuestion("5. Do you experience a ringing sensation in your ear?", ["No", "Undecided", "Yes"], _mapIndex(data['general_hearing_questions']?['has_ringing'], undecided: true)),
      _radioQuestion("6. Do you have pain in your ear?", ["No", "A little", "Yes"], _mapIndex(data['general_hearing_questions']?['has_pain'])),
      _radioQuestion("7. How satisfied are you with your hearing?", ["Unsatisfied", "Undecided", "Satisfied"], _mapSatisfactionIndex(data['general_hearing_questions']?['hearing_satisfaction'])),
      _radioQuestion("8. Do you ask people to repeat themselves or speak louder in conversation?", ["No", "Sometimes", "Yes"], _mapIndex(data['general_hearing_questions']?['asks_to_repeat'], undecided: true)),

      const SizedBox(height: 5),
      _sectionTitle('EAR SCREENING'),
      const SizedBox(height: 10),
      _radioQuestion(
        "Ear Clear for Impressions:",
        ["No", "Yes"],
        earScreening['is_clear'] == 'Yes' ? 1 : 0,
      ),

      const SizedBox(height: 5),
      _sectionTitle('OTOSCOPY'),
      const SizedBox(height: 10),

      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          const TableRow(
            children: [
              SizedBox(),
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
    _sectionTitle('HEARING SCREENING'),
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
      _sectionTitle('EAR IMPRESSIONS'),
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
    ],
  );
}

Widget _sectionTitle(String title) {
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

Widget _radioQuestion(String question, List<String> options, int? selectedIndex) {
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

int? _mapIndex(dynamic value, {bool undecided = false}) {
  if (value == null) return null;
  if (undecided) return value == 1 ? 2 : value == 0 ? 0 : 1;
  return value == 1 ? 2 : 0;
}

int? _mapSatisfactionIndex(dynamic value) {
  if (value == null) return null;
  int val = int.tryParse(value.toString()) ?? 0;
  if (val >= 6) return 2;
  if (val == 5) return 1;
  return 0;
}

TableRow _otoscopyRow(String label, String? value) {
  final sides = _parseSides(value);

  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label),
      ),
      Center(
        child: Radio<bool>(
          value: true,
          groupValue: sides.contains('left'),
          onChanged: null,
        ),
      ),
      Center(
        child: Radio<bool>(
          value: true,
          groupValue: sides.contains('right'),
          onChanged: null,
        ),
      ),
    ],
  );
}

List<String> _parseSides(String? value) {
  return value?.toLowerCase().split(',').map((e) => e.trim()).toList() ?? [];
}