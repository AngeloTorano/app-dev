  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:multi_select_flutter/multi_select_flutter.dart';
  import '../api_connection/api_connection.dart'; // make sure the path is correct

  class CreateMessageScreen extends StatefulWidget {
    const CreateMessageScreen({super.key});

    @override
    State<CreateMessageScreen> createState() => _CreateMessageScreenState();
  }

  class _CreateMessageScreenState extends State<CreateMessageScreen> {
    final TextEditingController _messageController = TextEditingController();

    List<String> _cities = [];
    List<String> _selectedCities = [];
    bool _isSending = false;
    bool _isLoadingCities = true;

    @override
    void initState() {
      super.initState();
      _fetchCities();
    }

    Future<void> _fetchCities() async {
      try {
        final response = await http.get(Uri.parse(ApiConnection.getCities));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _cities = data.map<String>((e) => e['CityName'].toString()).toList();
            _isLoadingCities = false;
          });
        } else {
          print('Failed to load cities: ${response.statusCode}');
          setState(() => _isLoadingCities = false);
        }
      } catch (e) {
        print("Failed to load cities: $e");
        setState(() => _isLoadingCities = false);
      }
    }

    Future<void> _sendMessage() async {
      final message = _messageController.text.trim();
      if (message.isEmpty || _selectedCities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one city and enter a message.')),
        );
        return;
      }

      setState(() => _isSending = true);

      try {
        final response = await http.post(
          Uri.parse(ApiConnection.sendSms),
          body: {
            'cities': jsonEncode(_selectedCities),
            'message': message,
          },
        );
        final data = json.decode(response.body);

        if (data['status'] == 'sent') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message sent successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to send message')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending message')),
        );
      } finally {
        setState(() => _isSending = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
        appBar: AppBar(
          title: const Text('Send Message', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _isLoadingCities
                  ? const Center(child: CircularProgressIndicator())
                  : MultiSelectDialogField(
                      items: _cities.map((city) => MultiSelectItem<String>(city, city)).toList(),
                      title: const Text("Select Cities"),
                      selectedColor: Colors.teal,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal),
                      ),
                      buttonText: const Text("Select Cities", style: TextStyle(color: Colors.black)),
                      onConfirm: (values) {
                        setState(() {
                          _selectedCities = List<String>.from(values);
                        });
                      },
                      initialValue: _selectedCities,
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: Colors.teal,
                        textStyle: const TextStyle(color: Colors.white),
                        onTap: (value) {
                          setState(() {
                            _selectedCities.remove(value);
                          });
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Write your message...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _isSending
                    ? const Text("Sending...")
                    : const Text("Send Message"),
                onPressed: _isSending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromRGBO(20, 104, 132, 1),
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
