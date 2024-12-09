import 'package:bulletin/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorCreateAccount extends StatefulWidget {
  @override
  _CreatorCreateAccountState createState() => _CreatorCreateAccountState();
}

class _CreatorCreateAccountState extends State<CreatorCreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clubnameController = TextEditingController();
  final TextEditingController _clubEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedDepartment;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final clubName = _clubnameController.text.trim();
      final clubEmail = _clubEmailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // Check if the email already exists in the 'creator_users' collection
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(clubEmail) // Document for account details
            .get();

        if (doc.exists) {
          // Show error message if email already exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email already exists.',
                style: TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.white,
            ),
          );
        } else {
          // Get the counter document
          DocumentReference counterRef = FirebaseFirestore.instance
              .collection('ID_counter')
              .doc('clubIdCounter');

          // Run a transaction to safely increment the counter
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentSnapshot counterSnapshot =
                await transaction.get(counterRef);

            if (!counterSnapshot.exists) {
              throw Exception("Counter document does not exist!");
            }

            int lastClubId = counterSnapshot['lastClubId'];
            int newID = lastClubId + 1;
            String clubID = 'c$newID';

            // Update the counter document
            transaction.update(counterRef, {'lastClubId': newID});

            // Create a document under the specified collection
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(clubID) // Document for account details
                .set({
              'clubName': clubName,
              'email': clubEmail,
              'department': _selectedDepartment,
              'password': password, // Handle securely in production
              'approvalStatus': 'pending',
              'clubID': clubID, // Add the auto-incremented creatorID
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Registration successful. Wait for the admin to verify your account')),
            );

            // Clear all fields
            _clearFields();

            // Navigate back to LoginPage without stacking
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  void _clearFields() {
    _clubnameController.clear();
    _clubEmailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Creator Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                hint: Text('Select Department'),
                items: [
                  DropdownMenuItem(
                      value: 'CED', child: Text('College of Education')),
                  DropdownMenuItem(
                      value: 'CEAC',
                      child: Text(
                          'College of Engineering Architechture and Com...')),
                  DropdownMenuItem(
                      value: 'CBA',
                      child: Text('College of Business Administration')),
                  DropdownMenuItem(
                      value: 'CAS',
                      child: Text('College of Arts and Sciences')),
                  DropdownMenuItem(
                      value: 'Non Academic', child: Text('Non Academic')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a department';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _clubnameController,
                decoration: InputDecoration(labelText: 'Club Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Club Name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _clubEmailController,
                decoration: InputDecoration(labelText: 'Club Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your club email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
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
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
