import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPostsScreen extends StatelessWidget {
  final String clubId;

  const UserPostsScreen({super.key, required this.clubId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo_ndmu.png'), // Your background image
            fit: BoxFit.cover, // Adjust the image size as needed
            colorFilter: ColorFilter.mode(
              Colors.green
                  .withOpacity(0.35), // Add a dark overlay for readability
              BlendMode.dstATop,
            ),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Posts')
              .where('creatorId', isEqualTo: clubId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No posts available.'));
            }

            final posts = snapshot.data!.docs;

            // Sort the posts by timestamp in descending order (latest first)
            posts.sort((a, b) {
              final aTimestamp = a['timestamp'] as Timestamp?;
              final bTimestamp = b['timestamp'] as Timestamp?;
              return bTimestamp?.compareTo(aTimestamp ?? Timestamp.now()) ?? 0;
            });

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePost(context, postId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['content'] ?? 'No content',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Timestamp
                        Text(
                          post['timestamp'] != null
                              ? DateFormat('MMM d, yyyy: h:mm a').format(
                                  (post['timestamp'] as Timestamp).toDate(),
                                )
                              : 'N/A',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        // Expiration Date
                        if (post['expirationDate'] != null)
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                "Expire Date: ${DateFormat('MMM d, yyyy').format((post['expirationDate'] as Timestamp).toDate())}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        // Display images if available
                        if (post['imageUrls'] != null &&
                            (post['imageUrls'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Images:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100, // Adjust height as needed
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (post['imageUrls'] as List).length,
                                  itemBuilder: (context, imageIndex) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          (post['imageUrls']
                                              as List)[imageIndex],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        // Post approvals section
                        const Text(
                          'Post Approvals:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Posts')
                              .doc(postId)
                              .collection('approvals')
                              .get(),
                          builder: (context, approvalSnapshot) {
                            if (approvalSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final approvals = approvalSnapshot.data!.docs;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: approvals.map((approval) {
                                final approvalData =
                                    approval.data() as Map<String, dynamic>;
                                final adminId = approvalData['adminId'];
                                final status = approvalData['status'];

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 0), // Reduced space between items
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 0,
                                        horizontal: 8), // Reduced padding
                                    title: Text(adminId),
                                    trailing: getApprovalStatusIcon(status),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _deletePost(BuildContext context, String postId) async {
    // Show a confirmation dialog
    bool confirmDeletion = await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, // Prevents closing the dialog by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this post? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(false), // Cancel the deletion
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(true), // Confirm the deletion
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    // If user confirms deletion, proceed with the deletion
    if (confirmDeletion) {
      try {
        // First, delete any subcollections (like 'approvals')
        await _deleteSubcollections(postId);

        // Then delete the post document
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .delete();

        // Ensure that the widget is still mounted before showing the snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post.')),
          );
        }
      }
    }
  }

  Future<void> _deleteSubcollections(String postId) async {
    try {
      // Retrieve the subcollection 'approvals'
      var approvalsSnapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .get();

      // Delete each document in the 'approvals' subcollection
      for (var doc in approvalsSnapshot.docs) {
        await doc.reference.delete();
      }

      // You can add more subcollections to delete if necessary
    } catch (e) {
      print('Failed to delete subcollections: $e');
    }
  }

  Widget getApprovalStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return const Icon(Icons.check_box, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.check_box_outline_blank, color: Colors.grey);
    }
  }
}
