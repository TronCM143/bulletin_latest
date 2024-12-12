import 'package:bulletin/student%20folder/settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../login_page.dart';
import 'functions.dart';

class StudentProfileDialog extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String department; // Add department here
  final String schoolId; // Add schoolId here

  const StudentProfileDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department, // Add department to constructor
    required this.schoolId, // Add schoolId to constructor
  });

  @override
  _StudentProfileDialogState createState() => _StudentProfileDialogState();
}

class _StudentProfileDialogState extends State<StudentProfileDialog> {
  File? _profileImage;
  String? _profileImageURL;

  @override
  void initState() {
    super.initState();
    loadProfileImage(widget.schoolId, (url) {
      setState(() {
        _profileImageURL = url;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white.withOpacity(0.95),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.8,
                maxWidth: constraints.maxWidth * 0.9,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _showImageSourceSelection(context);
                      },
                      child: CircleAvatar(
                        radius: constraints.maxWidth * 0.15,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : _profileImageURL != null
                                ? NetworkImage(_profileImageURL!)
                                : const AssetImage(
                                        'assets/placeholder_avatar.png')
                                    as ImageProvider,
                        child: _profileImage == null && _profileImageURL == null
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Name: ${widget.firstName} ${widget.lastName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Email: ${widget.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Department: ${widget.department}', // Display department
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'School ID: ${widget.schoolId}', // Display school ID
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage(
                                  schoolId: widget.schoolId,
                                )), // Navigate to the SettingsPage
                      ); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('About Us'),
                    onPressed: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'Your App Name',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.info),
                        children: const [
                          Text('This is the About Us section of the app.'),
                        ],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery, (image) {
                setState(() {
                  _profileImage = image;
                });
              }, (url) {
                setState(() {
                  _profileImageURL = url;
                });
              }, widget.schoolId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera, (image) {
                setState(() {
                  _profileImage = image;
                });
              }, (url) {
                setState(() {
                  _profileImageURL = url;
                });
              }, widget.schoolId);
            },
          ),
        ],
      ),
    );
  }
}
