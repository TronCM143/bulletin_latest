import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import

class AddPostDialog extends StatefulWidget {
  final String clubEmail; // Club email to identify the creator
  final String clubName; // Club name to be passed to Firebase

  const AddPostDialog({
    super.key,
    required this.clubEmail,
    required this.clubName,
  });

  @override
  _AddPostDialogState createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Function to handle saving the post with clubName
  Future<void> _savePost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        _isSaving = true; // Show loading state
      });

      String postId = DateTime.now().millisecondsSinceEpoch.toString();
      Timestamp timestamp = Timestamp.now();

      try {
        CollectionReference postsCollection = FirebaseFirestore.instance
            .collection('creator')
            .doc(widget.clubEmail) // Document based on the creator's email
            .collection('posts');

        // Save the post to Firestore under the creator's document
        await postsCollection.doc(postId).set({
          'title': title,
          'content': content,
          'timestamp': timestamp,
          'status': 'Pending', // Initially set status to 'Pending'
          'clubName': widget.clubName, // Pass clubName to Firestore
        });

        _titleController.clear();
        _contentController.clear();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding post: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false; // Remove loading state
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double dialogWidth = MediaQuery.of(context).size.width * 0.8;
    double dialogHeight = MediaQuery.of(context).size.height * 0.5;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Add Post',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Spacer(),
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
