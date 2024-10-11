import 'package:bulletin/student%20folder/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentHomePage extends StatefulWidget {
  final String schoolId; // Id of the student

  const StudentHomePage({super.key, required this.schoolId});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  // State variables to store student's information
  String firstName = 'Loading...';
  String lastName = 'Loading...';
  String department = 'Loading...';
  String schoolId = 'Loading...';
  String email = 'Loading...';
  String? profileImageURL; // Variable to hold the profile image URL

  @override
  void initState() {
    super.initState();
    // Fetch student information from Firestore
    StudentFunctions.fetchStudentInfo(widget.schoolId,
        (fName, lName, ema, dept, id) {
      setState(() {
        firstName = fName;
        lastName = lName;
        email = ema;
        department = dept;
        schoolId = id;
      });
      _loadProfileImage();
    }, context);
  }

  // Method to load the profile image URL from Firestore
  Future<void> _loadProfileImage() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users_students') // Ensure correct collection name
          .doc(schoolId) // Use the student's ID as the document ID
          .get();

      if (studentDoc.exists) {
        if (studentDoc.data() != null &&
            studentDoc.data()!.containsKey('profileImageURL')) {
          String? imageUrl = studentDoc.data()!['profileImageURL'];
          if (isValidImageUrl(imageUrl)) {
            setState(() {
              profileImageURL = imageUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home Page'),
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
              StudentFunctions.showProfileDialog(
                  context, firstName, lastName, email, department, schoolId);
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAcceptedPosts(department),
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
                                  ? DateFormat('hh:mm a MMM dd yyyy').format(
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
