import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting
import 'package:starkey_mobile_app/api_connection/api_connection.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchTerm = '';
  String _sortOption = 'All';

  final TextEditingController _searchController = TextEditingController();
  final String fetchUrl = ApiConnection.getSmsLogs;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(fetchUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Connection timeout"),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          List<dynamic> data = jsonData['data'];

          setState(() {
            _messages.clear();
            _messages.addAll(data.map((e) {
              final DateTime sentDate = DateTime.tryParse(e['sent_at'] ?? '') ?? DateTime.now();
              return {
                'patientName': e['patient_name'] ?? 'Unknown',
                'city': e['city'] ?? 'Unknown',
                'recipientNumber': e['recipient_number'] ?? '',
                'message': e['message'] ?? '',
                'time': DateFormat('HH:mm').format(sentDate),
                'date': DateFormat('MMMM dd, yyyy').format(sentDate),
                'status': e['status'],
                'isSent': e['status'] == 'sent',
                'sentAt': sentDate,
              };
            }));
            _isLoading = false;
            _hasError = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMessages {
    List<Map<String, dynamic>> filtered = _messages.where((msg) {
      final query = _searchTerm.toLowerCase();
      return msg['patientName'].toLowerCase().contains(query) ||
          msg['recipientNumber'].toLowerCase().contains(query) ||
          msg['city'].toLowerCase().contains(query);
    }).toList();

    switch (_sortOption) {
      case 'Newest to Oldest':
        filtered.sort((a, b) => b['sentAt'].compareTo(a['sentAt']));
        break;
      case 'Oldest to Newest':
        filtered.sort((a, b) => a['sentAt'].compareTo(b['sentAt']));
        break;
      case 'Success Only':
        filtered = filtered.where((msg) => msg['status'] == 'sent').toList();
        break;
      case 'Failed Only':
        filtered = filtered.where((msg) => msg['status'] == 'failed').toList();
        break;
      case 'All':
      default:
        break;
    }

    return filtered;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortItem('All'),
            _buildSortItem('Newest to Oldest'),
            _buildSortItem('Oldest to Newest'),
            _buildSortItem('Success Only'),
            _buildSortItem('Failed Only'),
          ],
        );
      },
    );
  }

  Widget _buildSortItem(String option) {
    return ListTile(
      title: Text(option, style: const TextStyle(color: Colors.white)),
      onTap: () => _selectSortOption(option),
    );
  }

  void _selectSortOption(String option) {
    setState(() {
      _sortOption = option;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Logs', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      ),
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchTerm = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name, number, city...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white24,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onPressed: _showSortOptions,
                  tooltip: 'Sort Options',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _hasError
                    ? const Center(
                        child: Text('Failed to load messages.', style: TextStyle(color: Colors.white)),
                      )
                    : _filteredMessages.isEmpty
                        ? const Center(
                            child: Text('No messages to show.', style: TextStyle(color: Colors.white)),
                          )
                        : ListView.builder(
                            itemCount: _filteredMessages.length,
                            itemBuilder: (context, index) =>
                                _buildMessageItem(_filteredMessages[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isSent = msg['isSent'] as bool;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSent)
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color.fromRGBO(20, 104, 132, 1)),
            ),
          Expanded(
            child: Card(
              color: isSent ? Colors.teal : Colors.white.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${msg['patientName']} (${msg['recipientNumber']})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSent ? Colors.white : Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('City: ${msg['city']}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(msg['message'], style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${msg['date']} • ${msg['time']}', style: const TextStyle(color: Colors.white70)),
                        if (isSent)
                          const Icon(Icons.done_all, size: 16, color: Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSent)
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color.fromRGBO(20, 104, 132, 1)),
            ),
        ],
      ),
    );
  }
}
