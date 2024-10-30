import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage import
import 'package:image_picker/image_picker.dart'; // Image Picker import
import 'dart:io'; // Import for File

class AddPostDialog extends StatefulWidget {
  final String clubEmail; // Club email to identify the creator
  final String clubName;
  final String clubDepartment; // Club name to be passed to Firebase

  const AddPostDialog({
    super.key,
    required this.clubEmail,
    required this.clubName,
    required this.clubDepartment,
  });

  @override
  _AddPostDialogState createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  List<XFile>? _selectedImages = []; // List to store selected images

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Function to handle image selection
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles =
        await picker.pickMultiImage(); // Select multiple images
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages!.addAll(pickedFiles); // Add selected images to the list
      });
    }
  }

  // Function to upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    final storageRef = FirebaseStorage.instance.ref();

    for (var image in _selectedImages!) {
      String fileName = '${widget.clubName}_${image.name}';
      Reference ref = storageRef.child('posts_files/$fileName');
      await ref.putFile(File(image.path));
      String downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl); // Store the download URL
    }

    return imageUrls; // Return list of image URLs
  }

  // Function to handle saving the post with clubName
  Future<void> _savePost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        _isSaving = true; // Show loading state
      });

      Timestamp timestamp = Timestamp.now();

      try {
        List<String> imageUrls =
            await _uploadImages(); // Upload images and get URLs

        CollectionReference postsCollection =
            FirebaseFirestore.instance.collection('Posts');

        // Save the post to Firestore under the creator's document
        await postsCollection.doc(title).set({
          'club_Id': widget.clubEmail,
          'department': widget.clubDepartment,
          'title': title,
          'content': content,
          'timestamp': timestamp,
          'status': 'Pending', // Initially set status to 'Pending'
          'clubName': widget.clubName, // Pass clubName to Firestore
          'imageUrls': imageUrls, // Attach the list of image URLs
        });

        _titleController.clear();
        _contentController.clear();
        _selectedImages = []; // Clear selected images
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post added successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding post: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Function to remove selected image
  void _removeImage(XFile image) {
    setState(() {
      _selectedImages!.remove(image); // Remove the selected image from the list
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic width and height for the dialog based on the screen size
    double dialogWidth = MediaQuery.of(context).size.width * 0.9;
    double dialogHeight = MediaQuery.of(context).size.height * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                // Wrap in SingleChildScrollView for adjustable height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Add Post',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _pickImages,
                      child: const Text('Attach Images'),
                    ),
                    const SizedBox(height: 8.0),
                    // Display selected images with remove button
                    _selectedImages!.isNotEmpty
                        ? Wrap(
                            spacing: 8.0,
                            children: _selectedImages!.map((image) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: FileImage(File(image.path)),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  Positioned(
                                    right: -5,
                                    top: -5,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeImage(image),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        : const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8.0), // Add space before buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8.0),
                _isSaving
                    ? const CircularProgressIndicator() // Show loading indicator while saving
                    : ElevatedButton(
                        onPressed: () => _savePost(context),
                        child: const Text('Save'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
