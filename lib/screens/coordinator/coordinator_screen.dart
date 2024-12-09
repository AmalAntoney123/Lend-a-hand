import 'package:flutter/material.dart';

class CoordinatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Coordinator Dashboard')),
      body: Center(child: Text('Coordinator Screen - Pending Approval')),
    );
  }
}
