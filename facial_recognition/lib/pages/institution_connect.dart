import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class InstitutionConnect extends StatefulWidget {
  final String institution_id;
  final String uid;
  final String institution_name;
  const InstitutionConnect({super.key, required this.institution_id, required this.uid, required this.institution_name});

  @override
  State<InstitutionConnect> createState() => _InstitutionConnectState();
}

class _InstitutionConnectState extends State<InstitutionConnect> {
  Future<void> linkInstitution(Map<String, TextEditingController> controllers) async {
    Map<String, String> credentials_str = {};
    controllers.forEach((key, value) {
      credentials_str[key] = value.text.trim();
    });
    String backendUrl = 'http://192.168.0.54:5001';
    final response = await http.post(
          Uri.parse('$backendUrl/link_institution_account'),
          headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "uid": widget.uid,
          "institution_id": widget.institution_id,
          "credentials": credentials_str,
          "institution_name": widget.institution_name
        }),
      );
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");
      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
      }
    
  }
  @override
  Widget build(BuildContext context) {
    Map<String, TextEditingController> credentialControllers = {};
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 75),
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: ElevatedButton(onPressed: (){
              Navigator.pop(context);
            }, 
            child: Icon(Icons.arrow_back_ios_new, color: Colors.black),),
          ),
          Center(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('institutions').doc(widget.institution_id).snapshots(),
            builder: (context, snapshot){
              if (!snapshot.hasData){
                return Center(child: CircularProgressIndicator());
              }
              final institutionData = snapshot.data!;
              final credentialFields = institutionData['login_requirements'] ?? [];
              for (var field in credentialFields){
                final label = field['field_label'] ?? 'Unknown Field';
                if (!credentialControllers.containsKey(label)) {
                  //creates a new controller only if it doesn't exist
                  credentialControllers[label] = TextEditingController();// Skip if the controller already exists
                }
              }
        
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Log In", 
                  style: TextStyle(color: Colors.black, fontSize: 60, 
                  fontWeight: FontWeight.bold)),
                  Text(widget.institution_name, style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.normal,
                  )),
                  ...credentialFields.map<Widget>((field){
                    return Padding(
                      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: TextField(
                        controller: credentialControllers[field['field_label'] ?? 'Unknown Field'],
                        decoration: InputDecoration(
                          labelText: field['field_label'] ?? 'Unknown Field',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: (field['field_label'] == 'Password'),
                        
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 20),
                  GestureDetector(
                  onTap: () => linkInstitution(credentialControllers),
                  child: Container(
                    height: 60,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Color(0xff9F1FFF),
                        border: Border.all(
                          color: Color.fromARGB(255, 192, 113, 253),
                          width: 5
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    child: Center(
                      child: Text("Log In", style: TextStyle(
                        color: Colors.white, 
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ))
                    ),
                  ),
                ),
                ],
              );
        
            }
          ),
        ),
      ]),
    );
    
  }
}