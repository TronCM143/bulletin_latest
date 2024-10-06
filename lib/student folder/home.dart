import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'functions.dart'; // Ensure this import is correct

class StudentHomePage extends StatefulWidget {
  final String schoolId; // School ID to identify the student
  final String studentDepartment; // Added department parameter

  const StudentHomePage({
    super.key,
    required this.schoolId,
    required this.studentDepartment, // Use the passed department here
  });

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String name = 'Loading...';
  String department = 'Loading...';
  String email = 'Loading...';
  String? profileImageURL;

  @override
  void initState() {
    super.initState();
    _fetchStudentInfo();
  }

  Future<void> _fetchStudentInfo() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users_students')
          .doc(widget.schoolId)
          .get();

      if (studentDoc.exists) {
        setState(() {
          name = studentDoc.data()?['name'] ?? 'N/A';
          department = studentDoc.data()?['department'] ??
              widget.studentDepartment; // Directly use the passed department
          email = studentDoc.data()?['email'] ?? 'N/A';
        });
        _loadProfileImage();
      }
    } catch (e) {
      print('Error loading student info: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users_students')
          .doc(widget.schoolId)
          .get();

      if (studentDoc.exists) {
        String? imageUrl = studentDoc.data()?['profileImageURL'];
        if (isValidImageUrl(imageUrl)) {
          setState(() {
            profileImageURL = imageUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  bool isValidImageUrl(String? url) {
    return url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  Stream<QuerySnapshot> getDepartmentStream([String? department]) {
    return FirebaseFirestore.instance
        .collection(department!) // Use the department name directly
        .where('status', isEqualTo: 'Accepted')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(department),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 20,
              backgroundImage:
                  profileImageURL != null && profileImageURL!.isNotEmpty
                      ? NetworkImage(profileImageURL!)
                      : null,
              child: profileImageURL == null || profileImageURL!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white,
                    )
                  : null,
            ),
            onPressed: () {
              if (email.isNotEmpty) {
                StudentFunctions.showProfileDialog(
                    context, name, department, email);
              }
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (department != 'Loading...' && department.isNotEmpty)
                  ? getDepartmentStream(department) // Ensure valid department
                  : null,
              builder: (context, departmentSnapshot) {
                if (departmentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> allPosts = [];
                if (departmentSnapshot.hasData) {
                  allPosts = departmentSnapshot.data!.docs; // Directly use docs
                }
                if (departmentSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${departmentSnapshot.error}'));
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
    );
  }
}
