import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Important
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

  final String backendUrl = "http://192.168.1.26:5001";

  late final String matchedUserId; // <-- this will be assigned in initState

  @override
  void initState() {
    super.initState();
    matchedUserId = FirebaseAuth.instance.currentUser!.uid; // Always use logged-in user
    print(matchedUserId);
    final fields = widget.institution["login_requirements"] ?? [];
    for (var field in fields) {
      _controllers[field["field_name"]] = TextEditingController();
    }
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
    print(matchedUserId);
    print(widget.institution["institution_id"]);
    final response = await http.post(
      Uri.parse('$backendUrl/link_institution_account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "uid": matchedUserId,
        "institution_id": widget.institution["institution_id"],
        "credentials": credentials,
        "institution_name": widget.institution["name"],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Linked! Link ID: ${data['link_id']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected successfully")),
      );
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
                  backgroundColor: Colors.green,
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




