import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPostsScreen extends StatelessWidget {
  final String clubEmail;

  const UserPostsScreen({super.key, required this.clubEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc('creators')
            .collection(clubEmail) // Use clubEmail as the collection name
            .doc('posts') // Document based on the creator's email
            .collection('posts')
            .snapshots(), // Fetch posts of the specific user
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['content'] ?? 'No content',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['timestamp'] != null
                            ? DateFormat('EEE. MMM d, yyyy: h:mm a').format(
                                (post['timestamp'] as Timestamp).toDate(),
                              )
                            : 'N/A',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      // Display images if available
                      if (post['imageUrls'] != null &&
                          (post['imageUrls'] as List).isNotEmpty)
                        SizedBox(
                          height: 100, // Adjust height as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (post['imageUrls'] as List).length,
                            itemBuilder: (context, imageIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.network(
                                  (post['imageUrls'] as List)[imageIndex],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
