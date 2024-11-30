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

      final DateTime now = DateTime.now();
      final String time = now.hour.toString().padLeft(2, '0') +
          now.minute.toString().padLeft(2, '0'); // Format time as HHMM
      final String month =
          now.month.toString().padLeft(2, '0'); // Format month as MM
      final String year = now.year.toString(); // Format year as YYYY
      final String baseId =
          '${time}_${month}_${year}_${widget.clubName}'; // Base ID format

      try {
        // Initialize the approvals list
        final List<String> adminIds = [
          "ACAD_VP",
          "CAS_DEAN",
          "CBA_DEAN",
          "CEAC_DEAN",
          "CED_DEAN",
          "DSA",
          "QUAPS",
          "VP_ADMIN",
        ];

        // Filter out department-specific _DEAN admin if post matches the user's department
        final filteredAdminIds = adminIds.where((adminId) {
          return adminId.endsWith('_DEAN')
              ? adminId.startsWith(widget.clubDepartment)
              : true;
        }).toList();

        // Upload images and get URLs
        List<String> imageUrls = await _uploadImages();

        CollectionReference postsCollection =
            FirebaseFirestore.instance.collection('Posts');

        // Check for existing documents with the same baseId
        QuerySnapshot existingPosts = await postsCollection
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: baseId)
            .get();

        int increment = 0;
        for (var doc in existingPosts.docs) {
          if (doc.id.startsWith(baseId)) {
            increment++;
          }
        }

        // Add increment to the UID if necessary
        String finalDocId =
            increment > 0 ? '${baseId}_${increment + 1}' : '${baseId}_1';

        // Create the main post document
        DocumentReference postDocRef = postsCollection.doc(finalDocId);
        await postDocRef.set({
          'club_Id': widget.clubEmail,
          'department': widget.clubDepartment,
          'title': title,
          'content': content,
          'timestamp': Timestamp.now(),
          'clubName': widget.clubName, // Pass clubName to Firestore
          'imageUrls': imageUrls, // Attach the list of image URLs
        });

        // Add approvals as a subcollection
        CollectionReference approvalsSubCollection =
            postDocRef.collection('approvals');

        for (var adminId in filteredAdminIds) {
          await approvalsSubCollection.doc(adminId).set({
            'adminId': adminId,
            'status': 'pending', // Default status is pending
          });
        }

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
