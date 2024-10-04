import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentHomePage extends StatelessWidget {
  final String studentDepartment; // Department of the student

  const StudentHomePage({super.key, required this.studentDepartment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Home Page')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('creator') // Get all creators
                  .where('department',
                      isEqualTo: studentDepartment) // Match department
                  .snapshots(),
              builder: (context, creatorSnapshot) {
                if (creatorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (creatorSnapshot.hasError) {
                  return Center(child: Text('Error: ${creatorSnapshot.error}'));
                }

                final creators = creatorSnapshot.data?.docs ?? [];

                if (creators.isEmpty) {
                  return const Center(
                      child: Text('No creators found for this department.'));
                }

                // List to hold accepted posts
                List<DocumentSnapshot> acceptedPosts = [];

                // Fetch accepted posts for each creator
                Future<void> fetchPosts() async {
                  for (var creator in creators) {
                    // Fetch accepted posts from the posts sub-collection
                    var postsSnapshot = await FirebaseFirestore.instance
                        .collection('creator') // Use the creator collection
                        .doc(creator
                            .id) // Reference the specific creator document
                        .collection(
                            'posts') // Assuming posts is a sub-collection under each creator
                        .where('status',
                            isEqualTo: 'Accepted') // Only accepted posts
                        .get();

                    acceptedPosts.addAll(
                        postsSnapshot.docs); // Add accepted posts to the list
                  }
                }

                // Call fetchPosts in a separate function (to avoid calling it multiple times)
                fetchPosts().then((_) {
                  // Build the ListView after fetching the posts
                  return ListView.builder(
                    itemCount: acceptedPosts.length,
                    itemBuilder: (context, index) {
                      final postData =
                          acceptedPosts[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postData['title'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                postData['content'] ?? 'N/A',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                postData['timestamp'] != null
                                    ? (postData['timestamp'] as Timestamp)
                                        .toDate()
                                        .toString()
                                    : 'N/A',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${postData['status'] ?? 'Pending'}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                });

                return Center(
                    child:
                        CircularProgressIndicator()); // Show loading until posts are fetched
              },
            ),
          ),
        ],
      ),
    );
  }
}
