import 'package:bulletin/calendar_of_events.dart';
import 'package:bulletin/student%20folder/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../profile_avatar.dart'; // Import the new calendar page

class StudentHomePage extends StatefulWidget {
  final String schoolId;

  const StudentHomePage({super.key, required this.schoolId});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  // State variables to store student's information
  String firstName = 'Loading...';
  String lastName = 'Loading...';
  String department = 'Loading...';
  String club = 'Loading...';
  String college = 'Loading...';
  String schoolId = 'Loading...';
  String email = 'Loading...';
  String? profileImageURL; // Variable to hold the profile image URL

  @override
  void initState() {
    super.initState();
    // Fetch student information from Firestore
    StudentFunctions.fetchStudentInfo(widget.schoolId,
        (fName, lName, ema, dept, id, clu, col) {
      setState(() {
        firstName = fName;
        lastName = lName;
        email = ema;
        department = dept;
        schoolId = id;
        club = clu;
        college = col;
      });
      _loadProfileImage();
    }, context);
  }

  Future<void> _loadProfileImage() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(schoolId)
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

  bool isValidImageUrl(String? url) {
    return url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  Future<void> _refreshPosts() async {
    setState(() {
      // Refetch accepted posts on refresh
    });
  }

  void _showImagesPreview(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: PhotoViewGallery.builder(
              itemCount: imageUrls.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrls[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              pageController: PageController(initialPage: initialIndex),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Bulletin Board',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarPage()),
              );
            },
            tooltip: 'Calendar',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 20,
              backgroundImage:
                  profileImageURL != null && profileImageURL!.isNotEmpty
                      ? NetworkImage(profileImageURL!)
                      : null,
              child: profileImageURL == null || profileImageURL!.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.white)
                  : null,
            ),
            onPressed: () {
              StudentFunctions.showProfileDialog(context, firstName, lastName,
                  email, college, department, club, schoolId);
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo_ndmu.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.green.withOpacity(0.15), // Green shade overlay
              BlendMode.dstATop, // Apply color filter over the image
            ),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: getAcceptedPostsStream(college, department, club),
            builder: (context, snapshot) {
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
                          Row(
                            children: [
                              ProfileAvatar(creatorId: postData['creatorId']),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postData['creatorName'] ?? 'Unknown Club',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    postData['timestamp'] != null
                                        ? DateFormat('hh:mm a EEE. MMM dd yyyy')
                                            .format((postData['timestamp']
                                                    as Timestamp)
                                                .toDate())
                                        : 'N/A',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(postData['title'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(postData['content'] ?? 'N/A',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          if (postData['imageUrls'] != null &&
                              (postData['imageUrls'] as List).isNotEmpty)
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    (postData['imageUrls'] as List).length,
                                itemBuilder: (context, imageIndex) {
                                  return GestureDetector(
                                    onTap: () {
                                      _showImagesPreview(
                                          context,
                                          (postData['imageUrls'] as List)
                                              .map((e) => e.toString())
                                              .toList(),
                                          imageIndex);
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Image.network(
                                        (postData['imageUrls']
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getAcceptedPostsStream(
      String college, String department, String club) async* {
    List<Map<String, dynamic>> acceptedPosts = [];
    Set<String> seenPostIds = {}; // Set to track seen post IDs

    // Helper function to fetch and process posts based on conditions
    Future<void> fetchAndProcessPosts(
        String postType, String field, String value) async {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .where('postType', isEqualTo: postType)
          .where(field, isEqualTo: value)
          .get();

      for (var postDoc in postsSnapshot.docs) {
        final approvalsSnapshot =
            await postDoc.reference.collection('approvals').get();

        if (approvalsSnapshot.docs.isNotEmpty) {
          bool allAccepted = approvalsSnapshot.docs
              .every((doc) => doc['status'] == 'accepted');

          if (allAccepted && !seenPostIds.contains(postDoc.id)) {
            seenPostIds.add(postDoc.id);
            acceptedPosts.add(postDoc.data());
          }
        }
      }
    }

    try {
      // Fetch posts based on the specified conditions
      await fetchAndProcessPosts('Collegiate', 'college', college);
      await fetchAndProcessPosts('Departmental', 'department', department);
      await fetchAndProcessPosts('Club', 'club', club);
      await fetchAndProcessPosts('University', 'college', 'Non Academic');

      // Sort acceptedPosts by timestamp in descending order (latest posts first)
      acceptedPosts.sort((a, b) {
        Timestamp timestampA = a['timestamp'];
        Timestamp timestampB = b['timestamp'];
        return timestampB.compareTo(timestampA);
      });

      // Yield the list of accepted posts
      yield acceptedPosts;
    } catch (e) {
      print('Error fetching posts: $e');
      yield acceptedPosts; // Return empty list in case of error
    }
  }
}
