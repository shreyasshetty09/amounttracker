import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'daily_expenditure_page.dart';
import 'monthly_expenditure_page.dart';
import 'total_expenditure_page.dart';
import 'login_page.dart'; // Import your login page here

class DashboardPage extends StatefulWidget {
  final String userEmail;

  DashboardPage({required this.userEmail});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? name;
  String? email;
  String? bankName;
  double? monthlySalary;

  Future<void> _getUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot docSnapshot =
          await firestore.collection('users').doc(widget.userEmail).get();
      setState(() {
        name = docSnapshot['name'];
        email = docSnapshot['email'];
        bankName = docSnapshot['bank_name'];
        monthlySalary = docSnapshot['monthly_salary'];
      });
    } catch (e) {
      print('Error retrieving user data: $e');
    }
  }

  Future<void> _getExpenditures() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot expendituresSnapshot = await firestore
          .collection('users')
          .doc(widget.userEmail)
          .collection('expenditures')
          .orderBy('date')
          .get();
    } catch (e) {
      print('Error retrieving expenditures: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getExpenditures();
  }

  void _showExpenditureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Expenditure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Daily Expenditure'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DailyExpenditurePage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Monthly Expenditure'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MonthlyExpenditurePage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Total Expenditure'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TotalExpenditurePage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenditureList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .collection('expenditures')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No expenditures found.'));
        }

        var expenditureData = snapshot.data!.docs;
        Map<String, List<Map<String, dynamic>>> monthlyExpenditures = {};

        for (var doc in expenditureData) {
          var month = doc['month'];
          var details = List<Map<String, dynamic>>.from(doc['details']);
          if (!monthlyExpenditures.containsKey(month)) {
            monthlyExpenditures[month] = [];
          }
          monthlyExpenditures[month]!.add({
            'id': doc.id,
            'date': doc['date'],
            'details': details,
          });
        }

        return ListView.builder(
          itemCount: monthlyExpenditures.keys.length,
          itemBuilder: (context, index) {
            String month = monthlyExpenditures.keys.elementAt(index);
            List<Map<String, dynamic>> monthDetails =
                monthlyExpenditures[month]!;

            return Card(
              child: ExpansionTile(
                title: Text(
                  month,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                children: monthDetails.map((expenditure) {
                  var details = expenditure['details'];
                  var date = expenditure['date'];
                  if (date is String) {
                    date = DateTime.parse(date);
                  } else if (date is Timestamp) {
                    date = date.toDate();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
                        subtitle: Column(
                          children: details.map<Widget>((detail) {
                            return ListTile(
                              title: Text(detail['name']),
                              subtitle: Text('₹${detail['amount']}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  var docRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.userEmail)
                                      .collection('expenditures')
                                      .doc(expenditure['id']);
                                  var newDetails =
                                      List<Map<String, dynamic>>.from(details)
                                        ..remove(detail);
                                  if (newDetails.isEmpty) {
                                    await docRef.delete();
                                  } else {
                                    await docRef.update({
                                      'details': newDetails,
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _logout() async {
    try {
      // Here you can perform any additional logout logic
      // For example, clearing cached data, etc.
      // Navigate to Login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false, // Prevent going back to DashboardPage
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'en_IN');

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null)
              Text('Name: $name', style: TextStyle(fontSize: 18)),
            if (email != null)
              Text('Email: $email', style: TextStyle(fontSize: 18)),
            if (bankName != null)
              Text('Bank Name: $bankName', style: TextStyle(fontSize: 18)),
            if (monthlySalary != null)
              Text('Monthly Salary: ${currencyFormatter.format(monthlySalary)}',
                  style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Expanded(child: _buildExpenditureList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenditureDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
