import 'package:bulletin/creators%20folder/settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File
import '../login_page.dart'; // Ensure this is the correct path for LoginPage
import 'functions.dart'; // Import the functions file

class ProfileDialog extends StatefulWidget {
  final String clubName; // Club name of the creator
  final String department; // Department of the creator
  final String email;
  final String clubId; // Email of the creator

  const ProfileDialog({
    super.key,
    required this.clubName,
    required this.department,
    required this.email,
    required this.clubId,
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
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white.withOpacity(0.95), // Slight transparency
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
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
                                    as ImageProvider, // Placeholder image if none exists
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

                  // Club Name
                  Text(
                    'Club Name: ${widget.clubName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Club ID: ${widget.clubId}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Department
                  Text(
                    'Department: ${widget.department}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Email
                  Text(
                    'Email: ${widget.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Settings Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CreatorSettingsPage(clubId: widget.clubId)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // About Us Button
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

                  // Logout Button
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
