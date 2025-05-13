import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:facial_recognition/pages/link_institution.dart';

class InstitutionPage extends StatefulWidget {
  @override
  _InstitutionPageState createState() => _InstitutionPageState();
}

class _InstitutionPageState extends State<InstitutionPage> {
  List<Map<String, dynamic>> _institutions = [];
  bool _isLoading = true;

  final String backendUrl = 'http://192.168.0.54:5001';

  @override
  void initState() {
    super.initState();
    fetchInstitutions();
  }

  Future<void> fetchInstitutions() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/get_institutions'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> institutionsRaw = data['institutions'];

        setState(() {
          _institutions = institutionsRaw.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('Failed to load institutions. Code: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching institutions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> disconnectInstitution(String institutionId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final response = await http.post(
      Uri.parse('$backendUrl/unlink_institution'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId,
        "institution_id": institutionId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected successfully')),
      );
    } else {
      print("Failed to disconnect: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.of(context).size.width;
    double myHeight = MediaQuery.of(context).size.height;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Institutions'),
        centerTitle: true,
      ),
      body: Container(
        height: myHeight,
        width: myWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromRGBO(30, 90, 112, 1), Color.fromRGBO(57, 171, 214, 1)],
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user_institutions')
                    .where('user_id', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong!'));
                  }

                  final connectedInstitutions = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    itemCount: _institutions.length,
                    itemBuilder: (context, index) {
                      final inst = _institutions[index];
                      final institutionId = inst["institution_id"];

                      final isConnected = connectedInstitutions.any((doc) =>
                          doc['institution_id'] == institutionId);

                      return institutionCard(context, inst, isConnected);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget institutionCard(BuildContext context, Map<String, dynamic> inst, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          leading: inst['logo_url'] != null && inst['logo_url'].toString().isNotEmpty
              ? Image.network(inst['logo_url'], height: 50, width: 50)
              : Icon(Icons.apartment, size: 40),
          title: Text(inst['name'] ?? ''),
          trailing: isConnected
              ? ElevatedButton(
                  onPressed: () => disconnectInstitution(inst["institution_id"]),
                  child: Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstitutionLinkPage(institution: inst),
                      ),
                    ).then((linkedId) {
                      if (linkedId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected successfully')),
                        );
                      }
                    });
                  },
                  child: Text("Connect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
        ),
      ),
    );
  }
}


