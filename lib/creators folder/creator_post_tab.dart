import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPostsScreen extends StatelessWidget {
  final String clubId;

  const UserPostsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Posts')
            .where('club_Id', isEqualTo: clubId)
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
                            ? DateFormat('MMM d, yyyy: h:mm a').format(
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
                      const SizedBox(height: 8),
                      // Checkboxes for approvals
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Posts')
                            .doc(posts[index].id)
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

                              return ListTile(
                                minTileHeight: 2,
                                title: Text(adminId),
                                trailing: getApprovalStatusIcon(status),
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
    );
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
