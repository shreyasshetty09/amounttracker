import 'package:flutter/material.dart';

class TotalExpenditurePage extends StatelessWidget {
  final String userEmail;

  TotalExpenditurePage({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Expenditure'),
      ),
      body: Center(
        child: Text('Total Expenditure Page'),
      ),
    );
  }
}
