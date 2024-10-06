import 'package:bulletin/creators%20folder/create_account.dart';
import 'package:bulletin/student%20folder/student_create_account.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select Account Type:', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Student account creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentCreateAccount(), // Replace with your actual Student page
                  ),
                );
              },
              child: Text('Student'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to Creator account creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreatorCreateAccount(), // Replace with your actual Creator page
                  ),
                );
              },
              child: Text('Creator'),
            ),
          ],
        ),
      ),
    );
  }
}
