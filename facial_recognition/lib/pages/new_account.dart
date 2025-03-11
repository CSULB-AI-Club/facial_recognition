import 'package:flutter/material.dart';

class NewAccount extends StatelessWidget{
  const NewAccount({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Account'),
        centerTitle: true,
        ),

      );
  }
}