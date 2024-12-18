import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../login_page.dart';
import 'functions.dart';
import 'settings.dart';

class StudentProfileDialog extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String college;
  final String department;
  final String club;
  final String schoolId;

  const StudentProfileDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department,
    required this.schoolId,
    required this.college,
    required this.club,
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
    _loadProfileImage(widget.schoolId);
  }

  // Loads the profile image from a URL if it exists
  void _loadProfileImage(String schoolId) {
    loadProfileImage(schoolId, (url) {
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
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.9,
              ),
              child: IntrinsicHeight(
                // Ensures that the widgets are rendered flexibly.
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
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
                            child: _profileImage == null &&
                                    _profileImageURL == null
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
                      const SizedBox(height: 5),
                      Text(
                        'Email: ${widget.email}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'College: ${widget.college}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Department: ${widget.department}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Club: ${widget.club}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'School ID: ${widget.schoolId}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(
                                schoolId: widget.schoolId,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About Us'),
                        onTap: () {
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
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to show image source options (Gallery/Camera)
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
