import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAcceptedPosts(studentDepartment),
              builder: (context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final acceptedPosts = snapshot.data ?? [];

                if (acceptedPosts.isEmpty) {
                  return const Center(
                      child: Text('No accepted posts available.'));
                }

                return ListView.builder(
                  itemCount: acceptedPosts.length,
                  itemBuilder: (context, index) {
                    final postData = acceptedPosts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Displaying Club Name at the top
                            Text(
                              postData['clubName'] ?? 'Unknown Club',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                                height: 4), // Space between club and department
                            // Displaying Department Name below the Club Name
                            Text(
                              postData['department'] ?? 'Unknown Department',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Displaying Post Title
                            Text(
                              postData['title'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Displaying Post Content
                            Text(
                              postData['content'] ?? 'N/A',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            // Displaying Timestamp
                            Text(
                              postData['timestamp'] != null
                                  ? DateFormat('MMMM-dd-yyyy hh:mm a').format(
                                      (postData['timestamp'] as Timestamp)
                                          .toDate())
                                  : 'N/A', // Use N/A if timestamp is null
                              style: const TextStyle(color: Colors.grey),
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
        ],
      ),
    );
  }

  // Function to fetch accepted posts from the student's department and Non-Academic department
  Future<List<Map<String, dynamic>>> fetchAcceptedPosts(
      String department) async {
    List<Map<String, dynamic>> acceptedPosts = [];

    // Fetch accepted posts from the student's department
    var departmentPostsSnapshot = await FirebaseFirestore.instance
        .collection('creator')
        .where('department', isEqualTo: department)
        .get();

    for (var creator in departmentPostsSnapshot.docs) {
      var postsSnapshot = await FirebaseFirestore.instance
          .collection('creator')
          .doc(creator.id)
          .collection('posts')
          .where('status', isEqualTo: 'Accepted')
          .get();

      for (var post in postsSnapshot.docs) {
        var postData = post.data();
        postData['clubName'] =
            creator.id; // Assuming the creator ID is the club name
        postData['department'] = department; // Add department info to postData
        acceptedPosts.add(postData);
      }
    }

    // Fetch accepted posts from the Non-Academic department
    var nonAcadPostsSnapshot = await FirebaseFirestore.instance
        .collection('creator')
        .where('department', isEqualTo: 'Non Academic')
        .get();

    for (var creator in nonAcadPostsSnapshot.docs) {
      var postsSnapshot = await FirebaseFirestore.instance
          .collection('creator')
          .doc(creator.id)
          .collection('posts')
          .where('status', isEqualTo: 'Accepted')
          .get();

      for (var post in postsSnapshot.docs) {
        var postData = post.data();
        postData['clubName'] =
            creator.id; // Assuming the creator ID is the club name
        postData['department'] =
            'Non Academic'; // Add department info to postData
        acceptedPosts.add(postData);
      }
    }

    // Sort posts by timestamp in descending order (latest first)
    acceptedPosts.sort((a, b) {
      Timestamp timestampA = a['timestamp'] ?? Timestamp(0, 0);
      Timestamp timestampB = b['timestamp'] ?? Timestamp(0, 0);
      return timestampB.compareTo(timestampA); // Sort descending
    });

    return acceptedPosts;
  }
}
