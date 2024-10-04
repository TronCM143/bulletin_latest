import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_post.dart'; // Ensure this is the correct path for AddPostDialog

class CreatorHomePage extends StatelessWidget {
  final String clubEmail; // Club email to identify the creator

  const CreatorHomePage({super.key, required this.clubEmail});

  // Function to show the Add Post dialog
  void _showAddPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AddPostDialog(clubEmail: clubEmail), // Pass the club email here
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Home Page')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Stream to get accepted posts for the specific creator
              stream: FirebaseFirestore.instance
                  .collection('creator')
                  .doc(clubEmail) // Use the club email as document ID
                  .collection('posts')
                  .where('status',
                      isEqualTo:
                          'Accepted') // Only show accepted posts for the creator
                  .snapshots(),
              builder: (context, creatorSnapshot) {
                if (creatorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final creatorPosts = creatorSnapshot.data?.docs ?? [];

                // Stream to get globally accepted posts
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('posts')
                      .where('status',
                          isEqualTo:
                              'Accepted') // Only show accepted posts globally
                      .snapshots(),
                  builder: (context, globalSnapshot) {
                    if (globalSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final globalPosts = globalSnapshot.data?.docs ?? [];

                    // Combine creator posts and global posts
                    final combinedPosts = [
                      ...creatorPosts,
                      ...globalPosts,
                    ];

                    if (combinedPosts.isEmpty) {
                      return const Center(
                          child: Text('No accepted posts available.'));
                    }

                    return ListView.builder(
                      itemCount: combinedPosts.length,
                      itemBuilder: (context, index) {
                        final postData =
                            combinedPosts[index].data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  postData['title'] ??
                                      'N/A', // Use N/A if title is null
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  postData['content'] ??
                                      'N/A', // Use N/A if content is null
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  postData['timestamp'] != null
                                      ? (postData['timestamp'] as Timestamp)
                                          .toDate()
                                          .toString()
                                      : 'N/A', // Use N/A if timestamp is null
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${postData['status'] ?? 'Pending'}', // Default to 'Pending'
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FloatingActionButton to trigger the dialog
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddPostDialog(context), // Call the function with context
        child: const Icon(Icons.add), // Icon for adding a post
        tooltip: 'Add Post',
      ),
    );
  }
}
