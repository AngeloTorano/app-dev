import 'package:flutter/material.dart';

Widget phase3(Map<String, dynamic> data) {
  final earScreening = data['ear_screening'] ?? {};
  final otoscopy = data['otoscopy'] ?? {};
  final hearingAid = data['hearing_aid_fitting'] ?? {};
  final aftercareEval = data['aftercare_assessment'] ?? {};
  final List<String> leftAid = (aftercareEval['left_aid_issues'] as String?)?.split(',') ?? [];
  final List<String> rightAid = (aftercareEval['right_aid_issues'] as String?)?.split(',') ?? [];
  final List<String> leftEarmold = (aftercareEval['left_earmold_issues'] as String?)?.split(',') ?? [];
  final List<String> rightEarmold = (aftercareEval['right_earmold_issues'] as String?)?.split(',') ?? [];
  final aftercareService = data['services_completed'] ?? {};
  final List<String> leftAidSer = (aftercareService['left_aid_services'] as String?)?.split(',') ?? [];
  final List<String> rightAidSer = (aftercareService['right_aid_services'] as String?)?.split(',') ?? [];
  final List<String> leftEarmoldSer = (aftercareService['left_earmold_services'] as String?)?.split(',') ?? [];
  final List<String> rightEarmoldSer = (aftercareService['right_earmold_services'] as String?)?.split(',') ?? [];
  final genServices = (aftercareService['gen_services'] ?? '') .toString() .split(',') .map((e) => e.trim().toLowerCase()) .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 5),
      _sectionTitle('EAR SCREENING'),
      const SizedBox(height: 10),
      _radioQuestion(  
        "Ear Clear for Impressions:",
        ["No", "Yes"],
        earScreening['is_clear'] == 'Yes' ? 1 : 0,
      ),

      //EAR SCREENING/OTOSCOPY
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
          // Header row
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
      const Text('Ears Clear for Assessment:'),
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

      //AFTERCARE ASSESSMENT
      const SizedBox(height: 15),
      _sectionTitle('EVALUATION'),
      const SizedBox(height: 10),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          // Header Row
          const TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'HEARING AID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'LEFT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'RIGHT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Aid conditions
          ...[
            'Dead',
            'Internal Feedback',
            'Power Change Needed',
            'Lost/Stolen',
            'No Problem'
          ].map((condition) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _aidConditionLabel(condition),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: leftAid.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: rightAid.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
              ],
            );
          }),
        ],
      ),

      const SizedBox(height: 10),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          // Header Row
          const TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'EARMOLD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'LEFT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'RIGHT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Aid conditions
          ...[
            'Too Tight',
            'Too Loose',
            'Cracked/Damaged',
            'Lost/Stolen',
            'No Problem'
          ].map((condition) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _earmoldConditionLabel(condition),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: leftEarmold.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: rightEarmold.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      
      //SERVICES COMPLETED
      const SizedBox(height: 20),
      _sectionTitle("SERVICES COMPLETED"),
      const SizedBox(height: 10),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          // Header Row
          const TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'HEARING AID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'LEFT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'RIGHT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Aid conditions
          ...[
            'Tested',
            'Sent for Repair',
            'Refit',
            'Not Benefiting'
          ].map((condition) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _aidLabel(condition),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: leftAidSer.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: rightAidSer.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
              ],
            );
          }),
        ],
      ),

      const SizedBox(height: 10),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          // Header Row
          const TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'EARMOLD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'LEFT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'RIGHT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Aid conditions
          ...[
            'Retubed',
            'Modified',
            'Stock Refit',
            'Custom Refit',
            'New Ear Impression'
          ].map((condition) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _earmoldLabel(condition),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: leftEarmoldSer.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: rightEarmoldSer.contains(condition) ? const Text('✅') : const Text(''),
                  ),
                ),
              ],
            );
          }),
        ],
      ),

      const SizedBox(height: 10),
      const Text("General Services", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),

      CheckboxListTile(
      value: genServices.contains('counseling'),
      onChanged: null,
      title: const Text(
        'Counseling',
        style: TextStyle(color: Colors.black),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      ),
      CheckboxListTile(
        value: genServices.contains('batteries'),
        onChanged: null,
        title: const Text(
          'Batteries Provided',
          style: TextStyle(color: Colors.black),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
      CheckboxListTile(
        value: genServices.contains('refer to aftercare'),
        onChanged: null,
        title: const Text(
          'Refer to AfterCare Services Center',
          style: TextStyle(color: Colors.black),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
      CheckboxListTile(
        value: genServices.contains('refer to next'),
        onChanged: null,
        title: const Text(
          'Refer to next Phase 2 Mission',
          style: TextStyle(color: Colors.black),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),

      const Text('Comments:'),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: (aftercareService['notes'] == null || aftercareService['notes'].toString().trim().isEmpty)
            ? 'N/A'
            : aftercareService['notes'],
        maxLines: 3,
        enabled: false,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),

      //HEARING AID FITTING
      const SizedBox(height: 20),
      _sectionTitle("HEARING AID FITTING"),
      const SizedBox(height: 10),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            "Updated Hearing Aid and/or Earmold Information",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              _tableCell(""),
              _tableCell("LEFT", bold: true, center: true),
              _tableCell("RIGHT", bold: true, center: true),
            ],
          ),
          TableRow(
            children: [
              _tableCell("Power Level"),
              _tableCell(hearingAid['left_power_level'] ?? '-', center: true),
              _tableCell(hearingAid['right_power_level'] ?? '-', center: true),
            ],
          ),
          TableRow(
            children: [
              _tableCell("Volume"),
              _tableCell(hearingAid['left_volume'] ?? '-', center: true),
              _tableCell(hearingAid['right_volume'] ?? '-', center: true),
            ],
          ),
          TableRow(
            children: [
              _tableCell("Battery"),
              _tableCell(hearingAid['left_battery'] ?? '-', center: true),
              _tableCell(hearingAid['right_battery'] ?? '-', center: true),
            ],
          ),
          TableRow(
            children: [
              _tableCell("Earmold"),
              _tableCell(hearingAid['left_earmold'] ?? '-', center: true),
              _tableCell(hearingAid['right_earmold'] ?? '-', center: true),
            ],
          ),
        ],
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

String _aidConditionLabel(String key) {
  switch (key) {
    case 'Dead':
      return 'Hearing Aid is Dead or Broken';
    case 'Internal Feedback':
      return 'Hearing Aid has Internal Feedback';
    case 'Power Change Needed':
      return 'Hearing Aid Power Change Needed';
    case 'Lost/Stolen':
      return 'Hearing Aid was Lost or Stolen';
    case 'No Problem':
      return 'No Problem with Hearing Aid';
    default:
      return key;
  }
}

String _earmoldConditionLabel(String key) {
  switch (key) {
    case 'Too Tight':
      return 'Discomfort/Earmold too Tight';
    case 'Too Loose':
      return 'Feedback/Earmold too Loose';
    case 'Cracked/Damaged':
      return 'Earmold is Damaged or Tubing is Cracked';
    case 'Lost/Stolen':
      return 'Earmold was Lost or Stolen';
    case 'No Problem':
      return 'No Problem with Hearing Aid';
    default:
      return key;
  }
}

String _aidLabel(String key) {
  switch (key) {
    case 'Tested':
      return 'Tested with WFA® Fitting Method using Demo Hearing Aids';
    case 'Sent for Repair':
      return 'Hearing Aid Sent to SHF for Repair or Replacement';
    case 'Refit':
      return 'Refit new Hearing Aid';
    case 'Not Benefiting':
      return 'Not Benefiting from Hearing Aid';
    default:
      return key;
  }
}

String _earmoldLabel(String key) {
  switch (key) {
    case 'Retubed':
      return 'Retubed or Unplugged Earmold';
    case 'Modified':
      return 'Modified Earmold';
    case 'Stock Refit':
      return 'Fit Stock Earmold';
    case 'Custom Refit':
      return 'Took new Ear Impression';
    case 'New Ear Impression':
      return 'Refit Custom Earmold';
    default:
      return key;
  }
}

Widget _tableCell(String text, {bool bold = false, bool center = false}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}