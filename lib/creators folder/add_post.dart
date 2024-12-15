import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage import
import 'package:image_picker/image_picker.dart'; // Image Picker import
import 'dart:io';

class AddPostDialog extends StatefulWidget {
  final String clubEmail; // Club email to identify the creator
  final String clubName;
  final String clubDepartment;
  final String clubId;
  final String creatorAccountType;

  const AddPostDialog({
    super.key,
    required this.clubEmail,
    required this.clubName,
    required this.clubDepartment,
    required this.clubId,
    required this.creatorAccountType,
  });

  @override
  _AddPostDialogState createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  List<XFile>? _selectedImages = [];

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

  // Function to save the post to Firestore
  Future<void> _savePost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });

      try {
        final DateTime now = DateTime.now();
        final String baseId =
            '${now.hour}${now.minute}_${now.month}_${now.year}_${widget.clubName}';

        List<String> adminIds = [
          "ACAD_VP",
          "CAS_DEAN",
          "CBA_DEAN",
          "CEAC_DEAN",
          "CED_DEAN",
          "DSA",
          "QUAPS",
          "VP_ADMIN",
        ];

        List<String> filteredAdminIds = adminIds;

        if (widget.clubDepartment == 'Non Academic') {
          filteredAdminIds =
              adminIds.where((adminId) => !adminId.contains('_DEAN')).toList();
        } else if (adminIds
            .any((adminId) => adminId.startsWith(widget.clubDepartment))) {
          filteredAdminIds = ['${widget.clubDepartment}_DEAN', 'QUAPS', 'DSA'];
        }

        List<String> imageUrls = await _uploadImages();

        CollectionReference postsCollection =
            FirebaseFirestore.instance.collection('Posts');

        QuerySnapshot existingPosts = await postsCollection
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: baseId)
            .get();

        int increment = 0;
        for (var doc in existingPosts.docs) {
          if (doc.id.startsWith(baseId)) {
            increment++;
          }
        }

        String finalDocId =
            increment > 0 ? '${baseId}_${increment + 1}' : '${baseId}_1';

        DocumentReference postDocRef = postsCollection.doc(finalDocId);
        await postDocRef.set({
          'creatorId': widget.clubId,
          'creatorName': widget.clubName,
          'email': widget.clubEmail,
          'department': widget.clubDepartment,
          'creatorAccountType': widget.creatorAccountType,
          'title': title,
          'content': content,
          'timestamp': Timestamp.now(),
          'imageUrls': imageUrls, // Save expiration date
        });

        CollectionReference approvalsSubCollection =
            postDocRef.collection('approvals');

        for (var adminId in filteredAdminIds) {
          await approvalsSubCollection.doc(adminId).set({
            'adminId': adminId,
            'status': 'pending',
          });
        }

        _titleController.clear();
        _contentController.clear();
        _selectedImages = [];
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Post',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Title',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter the title',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Content',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter the content',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const SizedBox(height: 20.0),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Attach Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // Display selected images with remove button
                    if (_selectedImages!.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _selectedImages!.map((image) {
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(File(image.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
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
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _savePost(context),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
