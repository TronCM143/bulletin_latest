import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String schoolId; // ID of the student

  const SettingsPage({super.key, required this.schoolId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailController = TextEditingController();
  final _updateEmailController =
      TextEditingController(); // Controller for updating email.
  late String currentEmail; // To store current email

  bool _isPasswordVisible = false; // Toggle for password visibility
  final _newPasswordController = TextEditingController();
  late String _password = ''; // Store current password
  late String _newPassword = ''; // Store new password for update

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
    _fetchPasswordFromFirebase(); // Fetch current email from Firestore and password
  }

  // Fetch current user's email and password from Firestore
  void _fetchCurrentUserDetails() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId) // Use the student's ID as the document ID
          .get();

      if (studentDoc.exists) {
        setState(() {
          currentEmail = studentDoc.data()?['email'] ?? '';
          _password = studentDoc.data()?['password'] ??
              ''; // Fetch the current password
          _emailController.text = currentEmail; // Pre-fill with current email
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student record not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: $e')),
      );
    }
  }

  // Function to validate email format
  bool _isValidEmail(String email) {
    return email.contains('@'); // Check if email contains '@'
  }

  // Update email in Firestore and Firebase Authentication
  Future<void> _updateEmailInFirestore() async {
    String newEmail = _updateEmailController.text.trim();

    if (newEmail.isEmpty || !_isValidEmail(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    try {
      // Update the email in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget
              .schoolId) // Use the student's schoolId to identify the document
          .update({'email': newEmail});

      // Optionally, update the email in Firebase Authentication (if the user is logged in)
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateEmail(
            newEmail); // Update email in Firebase Authentication as well
        await user.reload();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated successfully')),
      );
    } catch (error) {
      print('Error updating email: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update email: $error')),
      );
    }
  }

  Future<void> _fetchPasswordFromFirebase() async {
    try {
      // Assuming you have a 'users' collection and each user document is named by their username
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _password = userDoc[
              'password']; // Assuming the password is stored as a plain text string
        });
      } else {
        print('User not found');
      }
    } catch (error) {
      print('Error fetching password: $error');
    }
  }

  Future<void> _updatePasswordInFirebase() async {
    if (_newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    try {
      // Update the password in Firebase
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.schoolId)
          .update({'password': _newPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      print('Error updating password: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Display current email in a read-only TextFormField
            TextFormField(
              controller: _emailController,
              readOnly: true, // Make this field read-only
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "Your current email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Editable TextFormField to update email
            TextFormField(
              controller: _updateEmailController,
              decoration: const InputDecoration(
                labelText: "Update Email",
                hintText: "Enter new email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Button to save changes for email
            ElevatedButton(
              onPressed: () async {
                if (_updateEmailController.text.isNotEmpty) {
                  await _updateEmailInFirestore(); // Update email
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please enter a new email.'),
                  ));
                }
              },
              child: const Text('Save Email Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            // Current Password field with visibility toggle
            TextFormField(
              controller: TextEditingController(text: _password),
              obscureText: !_isPasswordVisible, // Toggle password visibility
              readOnly: true, // Password should be read-only
              decoration: InputDecoration(
                labelText: "Current Password",
                hintText: "Your current password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New Password field
            TextFormField(
              controller: _newPasswordController,
              obscureText: true, // Always hide new password input
              decoration: const InputDecoration(
                labelText: "New Password",
                hintText: "Enter new password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Button to save changes for password
            ElevatedButton(
              onPressed: () async {
                _newPassword =
                    _newPasswordController.text; // Set the new password
                await _updatePasswordInFirebase(); // Update password
              },
              child: const Text('Save Password Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
