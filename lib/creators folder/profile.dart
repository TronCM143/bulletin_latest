import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File
import '../login_page.dart'; // Ensure this is the correct path for LoginPage
import 'functions.dart'; // Import the functions file
import 'settings.dart';

class ProfileDialog extends StatefulWidget {
  final String clubName; // Club name of the creator
  final String department; // Department of the creator
  final String email;
  final String clubId;
  final String college; // Email of the creator

  const ProfileDialog({
    super.key,
    required this.clubName,
    required this.department,
    required this.email,
    required this.clubId,
    required this.college,
  });

  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  File? _profileImage; // To hold the selected image
  String? _profileImageURL; // To hold the image URL from Firebase

  @override
  void initState() {
    super.initState();
    loadProfileImage(widget.clubId, (url) {
      setState(() {
        _profileImageURL = url;
      });
    }); // Load profile image on dialog open
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      backgroundColor: Colors.grey[200], // Classic background color
      child: FractionallySizedBox(
        widthFactor: 0.9,
        heightFactor: 0.85, // Adjust dialog size relative to screen
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // Modern font
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Image (Avatar)
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
                            backgroundColor: Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Club Info
                      _modernText('Club Name: ${widget.clubName}'),
                      _modernText('Club ID: ${widget.clubId}'),
                      _modernText('College: ${widget.college}'),
                      _modernText('Department: ${widget.department}'),
                      _modernText('Email: ${widget.email}'),

                      const SizedBox(height: 20),

                      // Buttons
                      SizedBox(
                        width: double
                            .infinity, // Ensures buttons stretch across the dialog
                        child: Column(
                          children: [
                            _modernButton(
                              context,
                              label: 'Settings',
                              icon: Icons.settings,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatorSettingsPage(
                                      clubId: widget.clubId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _modernButton(
                              context,
                              label: 'About Us',
                              icon: Icons.info,
                              onPressed: () {
                                Navigator.pop(context);
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Your App Name',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: const Icon(Icons.info),
                                  children: const [
                                    Text(
                                        'This is the About Us section of the app.'),
                                  ],
                                );
                              },
                            ),
                            _modernButton(
                              context,
                              label: 'Logout',
                              icon: Icons.exit_to_app,
                              onPressed: () {
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _modernText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Roboto', // Modern font
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _modernButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300], // Classic button color
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // Modern font
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Aligning to the left
          children: [
            Icon(icon, color: Colors.black), // Icon aligned to the left
            const SizedBox(width: 10), // Space between the icon and text
            Text(
              label,
              style: const TextStyle(
                color: Colors.black, // Button text color
              ),
            ),
          ],
        ),
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
              }, widget.clubId);
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
              }, widget.clubId);
            },
          ),
        ],
      ),
    );
  }
}
