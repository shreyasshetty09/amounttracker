import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyExpenditurePage extends StatefulWidget {
  final String userEmail;

  MonthlyExpenditurePage({required this.userEmail});

  @override
  _MonthlyExpenditurePageState createState() => _MonthlyExpenditurePageState();
}

class _MonthlyExpenditurePageState extends State<MonthlyExpenditurePage> {
  String _selectedMonth = 'January';
  List<Map<String, dynamic>> _expenditures = [];
  double _totalExpenditure = 0.0;

  void _fetchExpenditures(String month) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(widget.userEmail)
          .collection('expenditures')
          .where('month', isEqualTo: month)
          .get();

      List<Map<String, dynamic>> expenditures = [];
      double total = 0.0;

      snapshot.docs.forEach((doc) {
        List<dynamic> details = doc['details'];
        details.forEach((item) {
          expenditures.add({
            'name': item['name'],
            'amount': item['amount'],
          });
          total += item['amount'];
        });
      });

      setState(() {
        _expenditures = expenditures;
        _totalExpenditure = total;
      });
    } catch (e) {
      print('Error fetching expenditures: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchExpenditures(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Expenditure'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedMonth,
              items: [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December'
              ]
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                  _fetchExpenditures(_selectedMonth);
                });
              },
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Expenditure Name')),
                    DataColumn(label: Text('Amount')),
                  ],
                  rows: _expenditures
                      .map(
                        (expenditure) => DataRow(
                          cells: [
                            DataCell(Text(expenditure['name'])),
                            DataCell(Text(
                                '₹${expenditure['amount'].toStringAsFixed(2)}')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Total Expenditure: ₹${_totalExpenditure.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
