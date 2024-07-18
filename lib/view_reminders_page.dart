import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewRemindersPage extends StatelessWidget {
  final String userEmail;

  ViewRemindersPage({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('reminders')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reminders found.'));
          }

          var remindersData = snapshot.data!.docs;
          return ListView.builder(
            itemCount: remindersData.length,
            itemBuilder: (context, index) {
              var reminder = remindersData[index];
              var reminderName = reminder['name'];
              var reminderDate = reminder['date'].toDate();

              return ListTile(
                title: Text(reminderName),
                subtitle:
                    Text(DateFormat('yyyy-MM-dd – kk:mm').format(reminderDate)),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userEmail)
                        .collection('reminders')
                        .doc(reminder.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
