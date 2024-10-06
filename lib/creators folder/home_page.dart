import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'functions.dart'; // Import the functions file

class CreatorHomePage extends StatefulWidget {
  final String clubEmail; // Club email to identify the creator

  const CreatorHomePage({super.key, required this.clubEmail});

  @override
  _CreatorHomePageState createState() => _CreatorHomePageState();
}

class _CreatorHomePageState extends State<CreatorHomePage> {
  // State variables to store creator's information
  String clubName = 'Loading...';
  String department = 'Loading...';
  String email = 'Loading...';
  String? profileImageURL; // Variable to hold the profile image URL

  @override
  void initState() {
    super.initState();
    // Use the fetchCreatorInfo method from CreatorFunctions
    CreatorFunctions.fetchCreatorInfo(widget.clubEmail, (name, dept, em) {
      setState(() {
        clubName = name;
        department = dept; // Store the department
        email = em;
      });
      _loadProfileImage(); // Load the profile image after fetching info
    }, context);
  }

  // Method to load the profile image URL from Firestore
  Future<void> _loadProfileImage() async {
    try {
      // Get the document from Firestore
      final creatorDoc = await FirebaseFirestore.instance
          .collection('creators') // Ensure correct collection name
          .doc(email) // Use the creator's email as the document ID
          .get();

      if (creatorDoc.exists) {
        // Check if 'profileImageURL' field exists
        if (creatorDoc.data() != null &&
            creatorDoc.data()!.containsKey('profileImageURL')) {
          // Set the profile image URL if it exists in Firestore
          String? imageUrl = creatorDoc.data()!['profileImageURL'];
          if (isValidImageUrl(imageUrl)) {
            setState(() {
              profileImageURL = imageUrl; // Store the valid image URL
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Method to check if the image URL is valid
  bool isValidImageUrl(String? url) {
    return url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  // Define the method to get the stream for the creator's department
  Stream<QuerySnapshot> getDepartmentStream(String department) {
    return FirebaseFirestore.instance
        .collection(department)
        .where('status', isEqualTo: 'Accepted')
        .snapshots(); // Get real-time snapshots for accepted posts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(department),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 20, // Adjust size as needed
              backgroundImage: profileImageURL != null &&
                      profileImageURL!.isNotEmpty
                  ? NetworkImage(profileImageURL!) // Use the profile image URL
                  : null, // No image will be displayed if URL is empty
              child: profileImageURL == null || profileImageURL!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 24, // Adjust icon size if needed
                      color: Colors
                          .white, // Color of the icon when no image is available
                    )
                  : null, // No child if profile image exists
            ),
            onPressed: () {
              // Use the showProfileDialog method from CreatorFunctions
              CreatorFunctions.showProfileDialog(
                context,
                clubName,
                department,
                email,
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: department.isNotEmpty
                  ? getDepartmentStream(department) // Call the method here
                  : null, // No stream if department is not set
              builder: (context, departmentSnapshot) {
                if (departmentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // List to hold all posts from the department
                List<DocumentSnapshot> allPosts = [];

                if (departmentSnapshot.hasData) {
                  allPosts = departmentSnapshot.data!.docs; // Directly use docs
                }

                // Sort posts by timestamp (newest first)
                allPosts.sort((a, b) {
                  final aTimestamp = a['timestamp'] as Timestamp?;
                  final bTimestamp = b['timestamp'] as Timestamp?;
                  return bTimestamp?.compareTo(aTimestamp ?? Timestamp.now()) ??
                      0;
                });

                if (allPosts.isEmpty) {
                  return const Center(
                      child: Text('No accepted posts available.'));
                }

                // Display the combined posts
                return ListView.builder(
                  itemCount: allPosts.length,
                  itemBuilder: (context, index) {
                    final postData =
                        allPosts[index].data() as Map<String, dynamic>;

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
      // Floating Action Button for adding a post
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_post',
        onPressed: () {
          // Use the showAddPostDialog method from CreatorFunctions
          CreatorFunctions.showAddPostDialog(context, widget.clubEmail);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Post',
      ),
    );
  }
}
