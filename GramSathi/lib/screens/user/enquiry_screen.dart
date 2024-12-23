import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';

class EnquiryScreen extends StatefulWidget {
  final String username;

  EnquiryScreen({required this.username});

  @override
  _EnquiryScreenState createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends State<EnquiryScreen> {
  final TextEditingController _enquiryController = TextEditingController();
  List<Map<String, dynamic>> _enquiries = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEnquiries();
  }

  Future<void> _fetchEnquiries() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/queries?username=${widget.username}&type=1'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> enquiriesJson = json.decode(response.body);
        setState(() {
          _enquiries =
              enquiriesJson.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load enquiries';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _createEnquiry() async {
    final matter = _enquiryController.text;
    if (matter.isEmpty) {
      return;
    }

    final newEnquiry = {
      'username': widget.username,
      'matter': matter,
      'time': DateTime.now().toIso8601String(),
      'type': '1',
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/createQuery'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newEnquiry),
      );

      if (response.statusCode == 200) {
        setState(() {
          _enquiries.insert(0, newEnquiry);
          _enquiryController.clear();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to create enquiry';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  DateTime convertUtcToIst(DateTime utcDateTime) {
    return utcDateTime.add(Duration(hours: 5, minutes: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE6F4E3), // Light green color
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchEnquiries,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage))
                        : ListView.builder(
                            itemCount: _enquiries.length,
                            itemBuilder: (context, index) {
                              final enquiry = _enquiries[index];
                              final dateTimeUtc =
                                  DateTime.parse(enquiry['time']);
                              final dateTimeIst = convertUtcToIst(dateTimeUtc);

                              final formattedDate =
                                  DateFormat('dd-MM-yy').format(dateTimeIst);
                              final formattedTime =
                                  DateFormat('hh:mm a').format(dateTimeIst);

                              return AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      enquiry['admin_response'] != null
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: enquiry['admin_response'] != null
                                          ? Colors.green
                                          : Colors.green,
                                    ),
                                    title: Text(
                                      enquiry['matter'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$formattedDate • $formattedTime',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        AnimatedOpacity(
                                          opacity:
                                              enquiry['admin_response'] != null
                                                  ? 1.0
                                                  : 0.5,
                                          duration: Duration(seconds: 1),
                                          child: Text(
                                            enquiry['admin_response'] ??
                                                'Awaiting response',
                                            style: TextStyle(
                                              color:
                                                  enquiry['admin_response'] !=
                                                          null
                                                      ? Colors.black
                                                      : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _showEnquiryDialog(enquiry);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF015F3E)
                      .withOpacity(0.1), // Light green background for emphasis
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF015F3E)
                          .withOpacity(0.1), // Soft shadow for highlight effect
                      blurRadius: 8,
                      offset: Offset(0, 2),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _enquiryController,
                        decoration: InputDecoration(
                          hintText: 'Enter your enquiry',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _createEnquiry,
                      backgroundColor: Color(0xff015F3E),
                      child: Icon(
                        Icons.send,
                        color: Colors.white, // Set the icon color to white
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showEnquiryDialog(Map<String, dynamic> enquiry) {
    final dateTimeUtc = DateTime.parse(enquiry['time']);
    final dateTimeIst = convertUtcToIst(dateTimeUtc);

    final formattedDate = DateFormat('dd-MM-yy').format(dateTimeIst);
    final formattedTime = DateFormat('hh:mm a').format(dateTimeIst);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enquiry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enquiry['matter'],
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              Text(
                enquiry['admin_response'] ?? 'Awaiting response',
                style: TextStyle(
                  color: enquiry['admin_response'] != null
                      ? Colors.black
                      : Colors.red,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '$formattedDate • $formattedTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
