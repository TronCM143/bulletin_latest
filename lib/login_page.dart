import 'create_account_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'creators folder/creator_home_page.dart';
import 'student folder/stud_home.dart'; // Import your HomePage for students

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final id = _idController.text.trim();
        final password = _passwordController.text.trim();

        // First, check in the users_students collection
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('users_students')
            .doc(id) // Check by student ID
            .get();

        if (studentDoc.exists) {
          String storedPassword = studentDoc['password'];
          if (storedPassword == password) {
            // Login successful for students collection
            String studentDepartment =
                studentDoc['department'] ?? 'Unknown'; // Retrieve department
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHomePage(
                    studentDepartment:
                        studentDepartment), // Pass the department
              ),
            );
            return; // Exit the function if student login is successful
          } else {
            // Incorrect password for students collection
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Incorrect password for student.')),
            );
            return; // Exit if password is incorrect
          }
        }

        // If not found in users_students, check in creator collection
        DocumentSnapshot creatorDoc = await FirebaseFirestore.instance
            .collection('creator')
            .doc(id) // Check by club email
            .get();

        if (creatorDoc.exists) {
          String storedPassword = creatorDoc['password'];
          if (storedPassword == password) {
            // Login successful for creator collection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CreatorHomePage(
                  clubEmail: id, // Pass club email
                ),
              ),
            );
            return; // Exit the function if creator login is successful
          } else {
            // Incorrect password for creator collection
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Incorrect password for creator.')),
            );
            return; // Exit if password is incorrect
          }
        }

        // If neither student ID nor club email is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID not found in both collections.')),
        );
      } catch (e) {
        // Handle any errors that occur during login
        print('Error during login: $e'); // Debug log for developers
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _idController,
                decoration:
                    InputDecoration(labelText: 'School ID or Club Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your School ID or Club Email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              // Add the Create Account button here
              TextButton(
                onPressed: () {
                  // Navigate to CreateAccountPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAccountPage(),
                    ),
                  );
                },
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
