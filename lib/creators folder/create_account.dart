import 'package:bulletin/login_page.dart';
import 'package:bulletin/registration_list.dart';
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
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedClub;
  String? _clubType; // To store the selected club type

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final clubEmail = _clubEmailController.text.trim();
      final password = _passwordController.text.trim();
      String? clubName;

      // Determine clubName based on the club type
      if (_clubType == 'Non-Departmental Club') {
        clubName = '${_selectedClub ?? ''} SC';
      } else if (_clubType == 'Departmental Club') {
        clubName = '${_selectedDepartment ?? ''} SC';
        _selectedClub = _selectedDepartment ?? '';
      } else if (_clubType == 'College Student Council') {
        clubName = '${_selectedCollege ?? ''} SC';
        _selectedDepartment = _selectedCollege ?? '';
        _selectedClub = _selectedCollege ?? '';
      } else {
        clubName = _selectedClub ?? '';
      }

      try {
        // Check if the email already exists in the 'Users' collection
        final emailDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(clubEmail)
            .get();

        if (emailDoc.exists) {
          // Show error message if email already exists
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email already exists.',
                style: TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.white,
            ),
          );
        } else {
          // Check if the club already exists under the selected college and department
          final clubQuery = await FirebaseFirestore.instance
              .collection('Users')
              .where('department', isEqualTo: _selectedDepartment)
              .where('creatorName', isEqualTo: clubName)
              .get();

          if (clubQuery.docs.isNotEmpty) {
            // Show error message if club already exists
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Club already exists.',
                  style: TextStyle(color: Colors.red),
                ),
                backgroundColor: Colors.white,
              ),
            );
          } else {
            // Find the largest existing UID with 'c' prefix in the 'Users' collection
            final userDocs =
                await FirebaseFirestore.instance.collection('Users').get();

            int maxId = 0;
            for (var doc in userDocs.docs) {
              final uid = doc.id;
              if (uid.startsWith('c')) {
                final idPart = int.tryParse(uid.substring(1));
                if (idPart != null && idPart > maxId) {
                  maxId = idPart;
                }
              }
            }

            // Generate the new creatorId
            int newId = maxId + 1;
            String creatorId = 'c$newId';

            // Create a document under the specified collection
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(creatorId)
                .set({
              'creatorId': creatorId, // Auto-incremented creatorID
              'email': clubEmail,
              'college': _selectedCollege,
              'department': _selectedDepartment,
              'creatorName': clubName,
              'club': _selectedClub,
              'creatorAccountType': _clubType,
              'password': password,
              'approvalStatus': 'pending',
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
          }
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
    setState(() {
      _selectedCollege = null;
      _selectedDepartment = null;
      _selectedClub = null;
      _clubType = null; // Reset the club type
    });
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
              // Dropdown for selecting College
              DropdownButtonFormField<String>(
                value: _selectedCollege,
                hint: Text('Select College'),
                items: ['CAS', 'CED', 'CEAC', 'CBA', 'Non Academic']
                    .map((college) {
                  return DropdownMenuItem(
                    value: college,
                    child: Text(college),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                    _selectedDepartment = null;
                    _selectedClub = null; // Reset selected department and club
                    // If "Non Academic" is selected, show the department and club dropdowns
                    if (_selectedCollege == 'Non Academic') {
                      _clubType =
                          'Non-Departmental Club'; // Reset the clubType when Non Academic is selected
                    }
                  });
                },
              ),

              // Club Type Dropdown (Departmental or Non-Departmental)
              if (_selectedCollege != null &&
                  _selectedCollege != 'Non Academic')
                DropdownButtonFormField<String>(
                  value: _clubType,
                  hint: const Text('Select Club Type'),
                  items: [
                    'College Student Council',
                    'Departmental Club',
                    'Non-Departmental Club',
                  ].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _clubType = value;
                      _selectedDepartment = null;
                      _selectedClub =
                          null; // Reset selected club when club type changes
                    });
                  },
                ),

              // Show department and club options for all club types except "College Governor"
              if (_selectedCollege != null &&
                  _clubType != 'College Student Council')
                RegistrationList(
                  selectedCollege: _selectedCollege,
                  selectedDepartment: _selectedDepartment,
                  selectedClub: _selectedClub,
                  onCollegeChanged: (value) {
                    setState(() {
                      _selectedCollege = value;
                      _selectedDepartment = null;
                      _selectedClub = null;
                    });
                  },
                  onDepartmentChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                      _selectedClub = null;
                    });
                  },
                  onClubChanged: (value) {
                    setState(() {
                      _selectedClub = value;
                    });
                  },
                  showDepartment: true,
                  showClub: _clubType == 'Non-Departmental Club',
                ),

              // Email input field
              TextFormField(
                controller: _clubEmailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),

              // Password input field
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

              // Confirm Password input field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.0),

              // Register button
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
