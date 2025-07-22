import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_connection/api_connection.dart';

IconData getIcon(String? actionType, [String? status]) {
  final type = actionType?.toLowerCase() ?? '';
  final stat = status?.toLowerCase() ?? '';

  switch (type) {
    case 'login':
      return Icons.login;
    case 'logout':
      return Icons.logout;
    case 'updateprofile':
      return Icons.person;
    case 'searchpatient':
      return Icons.search;
    case 'changepassword':
      return Icons.lock_reset;
    case 'updatepassword':
      return stat == 'failed' ? Icons.info_outline : Icons.lock_reset;
    case 'updateavatar':
      return Icons.camera_alt;
    default:
      return Icons.info_outline;
  }
}

Color getColor(String? actionType, [String? status]) {
  final type = actionType?.toLowerCase() ?? '';
  final stat = status?.toLowerCase() ?? '';

  switch (type) {
    case 'login':
      return stat == 'failed' ? Colors.red : Colors.green;
    case 'logout':
      return Colors.red;
    case 'updateprofile':
      return Colors.blue;
    case 'searchpatient':
      return Colors.orange;
    case 'changepassword':
      return Colors.purple;
    case 'updatepassword':
      return stat == 'failed' ? Colors.grey : Colors.purple;
    case 'updateavatar':
      return Colors.teal;
    default:
      return Colors.grey;
  }
}

class ActivityLogScreen extends StatefulWidget {
  final int userId;
  const ActivityLogScreen({super.key, required this.userId});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<dynamic> logs = [];
  List<dynamic> filteredLogs = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedActionType = 'All';
  String sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      final response = await http.get(Uri.parse(ApiConnection.getActivityLogs));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['logs'] != null) {
          final userLogs = (data['logs'] as List).where((log) {
            final logUserID = log['UserID'];
            return logUserID == null || logUserID.toString() == widget.userId.toString();
          }).toList();

          setState(() {
            logs = userLogs;
            filteredLogs = userLogs;
            isLoading = false;
          });
        } else {
          setState(() {
            logs = [];
            filteredLogs = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        logs = [];
        filteredLogs = [];
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredLogs = logs.where((log) {
        final action = log['ActionType']?.toString().toLowerCase() ?? '';
        final desc = log['Description']?.toString().toLowerCase() ?? '';
        final status = log['Status']?.toString().toLowerCase() ?? '';
        final matchesSearch = action.contains(searchQuery.toLowerCase()) ||
            desc.contains(searchQuery.toLowerCase()) ||
            status.contains(searchQuery.toLowerCase());
        final matchesDropdown = selectedActionType == 'All' || log['ActionType'] == selectedActionType;
        return matchesSearch && matchesDropdown;
      }).toList();
      sortLogs();
    });
  }

  void filterLogs(String query) {
    searchQuery = query;
    applyFilters();
  }

  void sortLogs() {
    if (sortBy == 'Newest') {
      filteredLogs.sort((a, b) => DateTime.parse(b['CreatedAt']).compareTo(DateTime.parse(a['CreatedAt'])));
    } else if (sortBy == 'Oldest') {
      filteredLogs.sort((a, b) => DateTime.parse(a['CreatedAt']).compareTo(DateTime.parse(b['CreatedAt'])));
    } else if (sortBy == 'Status: Success') {
      filteredLogs.sort((a, b) => (b['Status'] == 'Success' ? 1 : 0).compareTo(a['Status'] == 'Success' ? 1 : 0));
    } else if (sortBy == 'Status: Failed') {
      filteredLogs.sort((a, b) => (b['Status'] == 'Failed' ? 1 : 0).compareTo(a['Status'] == 'Failed' ? 1 : 0));
    }
  }

  String formatTimestamp(String? timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp ?? '');
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (_) {
      return timestamp ?? '';
    }
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        title: const Text("Filter by Action Type", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...['All', ...logs.map((log) => log['ActionType'] ?? '').where((type) => type != '').toSet()].map(
                (type) => ListTile(
                  title: Text(type, style: const TextStyle(color: Colors.white)),
                  tileColor: selectedActionType == type ? Colors.teal : null,
                  onTap: () {
                    setState(() {
                      selectedActionType = type;
                      applyFilters();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        title: const Text("Sort Logs", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...['Newest', 'Oldest', 'Status: Success', 'Status: Failed'].map(
                (val) => ListTile(
                  title: Text(val, style: const TextStyle(color: Colors.white)),
                  tileColor: sortBy == val ? Colors.teal : null,
                  onTap: () {
                    setState(() {
                      sortBy = val;
                      sortLogs();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: fetchLogs),
        ],
      ),
      backgroundColor: const Color.fromRGBO(20, 104, 132, 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: filterLogs,
                    decoration: InputDecoration(
                      hintText: 'Search activities...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
                  onPressed: showFilterDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onPressed: showSortDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLogs.isEmpty
                    ? const Center(child: Text('No activity logs found.', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white, width: 0.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: getColor(log['ActionType'], log['Status']),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      getIcon(log['ActionType'], log['Status']),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['ActionType'] ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          log['Description'] ?? 'No description',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Text(
                                          'Status: ${log['Status'] ?? 'Unknown'}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatTimestamp(log['CreatedAt']),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
