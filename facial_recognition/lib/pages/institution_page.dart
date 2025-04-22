import 'package:facial_recognition/pages/link_institution.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InstitutionPage extends StatefulWidget {
  @override
  _InstitutionPageState createState() => _InstitutionPageState();
}

class _InstitutionPageState extends State<InstitutionPage> {
  List<Map<String, dynamic>> _institutions = [];
  bool _isLoading = true;
  Set<String> _connectedInstitutionIds = {};


  // UPDATE THIS with your backend IP address or use 10.0.2.2 for Android emulator
  final String backendUrl = 'http://127.0.0.1:5001';

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
  final response = await http.post(
    Uri.parse('$backendUrl/unlink_institution'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "user_id": "your_user_id_here", 
      "institution_id": institutionId,
    }),
  );

  if (response.statusCode == 200) {
    setState(() {
      _connectedInstitutionIds.remove(institutionId);
    });
  } else {
    print("Failed to disconnect: ${response.body}");
  }
}


  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;

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
            : _institutions.isEmpty
                ? Center(child: Text('No institutions found', style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    itemCount: _institutions.length,
                    itemBuilder: (context, index) {
                      final inst = _institutions[index];
                      return institutionCard(context, inst);
                    },
                  ),
      ),
    );
  }

Widget institutionCard(BuildContext context, Map<String, dynamic> inst) {
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
      //  trailing: _connectedInstitutionIds.contains(inst["institution_id"])
      //  ? ElevatedButton(
      //  onPressed: null,
     //   child: Text("Connected"),
      //  style: ElevatedButton.styleFrom(
     //     backgroundColor: Colors.grey,
      //  ),
      //)
      trailing: _connectedInstitutionIds.contains(inst["institution_id"])
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
              setState(() {
                _connectedInstitutionIds.add(linkedId);
              });
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

