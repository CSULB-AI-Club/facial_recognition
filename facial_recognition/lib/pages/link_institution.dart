import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class InstitutionLinkPage extends StatefulWidget {
  final Map<String, dynamic> institution;

  InstitutionLinkPage({required this.institution});

  @override
  _InstitutionLinkPageState createState() => _InstitutionLinkPageState();
}

class _InstitutionLinkPageState extends State<InstitutionLinkPage> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  List<String> userIds = [];
  String? matchedUserId;

  String backendUrl = "http://127.0.0.1:5001"; 

@override
void initState() {
  super.initState();
  fetchUserInstitutionIds();

  final fields = widget.institution["login_requirements"] ?? [];
  for (var field in fields) {
    _controllers[field["field_name"]] = TextEditingController();
  }
}

Future<void> fetchUserInstitutionIds() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('user_institutions')
      .get();

  final ids = snapshot.docs
    .where((doc) => doc.data().containsKey('user_id'))
    .map((doc) => doc['user_id'].toString())
    .toList();

  print("Fetched user IDs: $ids");

  setState(() {
    userIds = ids;
    matchedUserId = ids.isNotEmpty ? ids.first : null; // Use the first one for now
  });
}


  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> submitCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    final credentials = {
      for (var key in _controllers.keys) key: _controllers[key]!.text
    };

  final response = await http.post(
  Uri.parse('$backendUrl/link_institution_account'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    "user_id": matchedUserId,
    "institution_id": widget.institution["institution_id"],
    "credentials": credentials,
  }),
);


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Linked! Link ID: ${data['link_id']}");
      Navigator.pop(context, widget.institution["institution_id"]);
    } else {
      final err = jsonDecode(response.body);
      print("Failed to link: ${err['error']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${err['error']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.institution["login_requirements"] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Connect to ${widget.institution['name']}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...fields.map((field) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: _controllers[field["field_name"]],
                      obscureText: field["field_type"] == "password",
                      keyboardType: field["field_type"] == "email"
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: field["field_label"] ?? field["field_name"],
                        hintText: field["placeholder"] ?? '',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((field["required"] ?? false) && (value == null || value.isEmpty)) {
                          return "${field["field_label"] ?? field["field_name"]} is required";
                        }
                        return null;
                      },
                    ),
                  )),
              SizedBox(height: 20),
              ElevatedButton(
              onPressed: submitCredentials,
              child: Text("Connect"),
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // 👈 this makes it green
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
