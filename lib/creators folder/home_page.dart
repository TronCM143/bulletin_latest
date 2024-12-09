import 'package:bulletin/creators%20folder/creator_post_tab.dart';
import 'package:bulletin/profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_post.dart';
import 'functions.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CreatorHomePage extends StatefulWidget {
  final String clubId; // Club email to identify the creator

  const CreatorHomePage({super.key, required this.clubId});

  @override
  _CreatorHomePageState createState() => _CreatorHomePageState();
}

class _CreatorHomePageState extends State<CreatorHomePage> {
  // State variables to store creator's information
  String clubName = 'Loading...';
  String department = 'Loading...';
  String email = 'Loading...';

  String? profileImageURL; // Variable to hold the profile image URL
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use the fetchCreatorInfo method from CreatorFunctions
    CreatorFunctions.fetchCreatorInfo(widget.clubId, (name, dept, em, clubId) {
      setState(() {
        clubName = name;
        department = dept; // Store the department
        email = em;
        clubId = widget.clubId;
      });
      _loadProfileImage(); // Load the profile image after fetching info
    }, context);
  }

  // Method to load the profile image URL from Firestore
  Future<void> _loadProfileImage() async {
    try {
      // Get the document from Firestore
      final creatorDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.clubId) // Fetch using clubId
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  // Define the method to get the stream for the creator's department
  Stream<List<DocumentSnapshot>> getDepartmentStream(String department) async* {
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('Posts')
        .where('department', isEqualTo: department)
        .get();

    List<DocumentSnapshot> filteredPosts = [];

    for (var postDoc in postsSnapshot.docs) {
      final approvalsSnapshot =
          await postDoc.reference.collection('approvals').get();
      if (approvalsSnapshot.docs.isNotEmpty) {
        bool allAccepted =
            approvalsSnapshot.docs.every((doc) => doc['status'] == 'accepted');
        if (allAccepted) {
          filteredPosts.add(postDoc);
        }
      }
    }

    yield filteredPosts;
  }

  // Method to refresh the posts list
  Future<void> _refreshPosts() async {
    setState(() {});
  }

  void _showImagesPreview(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black, // Background color for the screen
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
                color: Colors.transparent, // Transparent background
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
        backgroundColor: Color.fromARGB(255, 120, 219, 123),
        title: Text(
          department,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Additional icon on the left
          IconButton(
            icon: const Icon(
              Icons.notifications_rounded, // Replace with your desired icon
              color: Colors.white,
            ),
            onPressed: () {
              // Add your desired functionality here
            },
            tooltip: 'Settings',
          ),
          // Profile icon with CircleAvatar
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
                  context, clubName, department, email, widget.clubId);
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
              Colors.green.withOpacity(0.35), // Green shade overlay
              BlendMode.dstATop, // Apply color filter over the image
            ),
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            buildHomeTab(), // Home tab content
            buildUserPostsTab(), // User's posts tab content
          ],
        ),
      ),
      // Floating Action Button for adding a post
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          left: 30,
          right: 30,
          bottom: 5,
        ), // Move it up and apply left/right margins
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5), // Padding for better spacing
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home icon (unchanged)
            IconButton(
              icon: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                _onItemTapped(0);
              },
            ),
            // Spacer for the FloatingActionButton
            const SizedBox(
                width: 40), // Adjust the space for the floating button

            // User's Posts (right-side tab)
            IconButton(
              icon: Icon(
                Icons.account_circle,
                color: _selectedIndex == 1 ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                _onItemTapped(1);
              },
            ),
          ],
        ),
      ),
      // Add the floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AddPostDialog directly
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddPostDialog(
                  clubId: widget.clubId,
                  clubEmail: email,
                  clubName: clubName,
                  clubDepartment: department); // Pass the club email
            },
          );
        },
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add), // Icon for adding posts
      ),
      // Position the floating action button in the center of the bottomNavigationBar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshPosts, // Call the refresh method
      child: StreamBuilder<List<DocumentSnapshot>>(
        stream: getDepartmentStream(department),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          List<DocumentSnapshot> posts = snapshot.data!;
          posts.sort((a, b) {
            final aTimestamp = a['timestamp'] as Timestamp?;
            final bTimestamp = b['timestamp'] as Timestamp?;
            return bTimestamp?.compareTo(aTimestamp ?? Timestamp.now()) ?? 0;
          });

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var postData = posts[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(creatorId: postData['club_Id']),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clubName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                    postData['timestamp']
                                        .toDate()), // Post timestamp
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
                          height: 100, // Adjust height as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (postData['imageUrls'] as List).length,
                            itemBuilder: (context, imageIndex) {
                              return GestureDetector(
                                onTap: () {
                                  _showImagesPreview(
                                    context,
                                    List<String>.from(postData['imageUrls']),
                                    imageIndex,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.network(
                                    postData['imageUrls'][imageIndex],
                                    width: 100, // Image width
                                    height: 100, // Image height
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
    );
  }

  Widget buildUserPostsTab() {
    return UserPostsScreen(clubId: widget.clubId);
  }
}
