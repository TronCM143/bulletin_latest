import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatefulWidget {
  final String creatorId;

  const ProfileAvatar({Key? key, required this.creatorId}) : super(key: key);

  @override
  _ProfileAvatarState createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileImageUrl();
  }

  Future<void> _fetchProfileImageUrl() async {
    try {
      final creatorDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.creatorId)
          .get();

      if (creatorDoc.exists) {
        setState(() {
          profileImageUrl = creatorDoc.data()?['profileImageURL'];
        });
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20, // Adjust the size as needed
      backgroundImage: profileImageUrl != null
          ? NetworkImage(profileImageUrl!)
          : null, // Use a placeholder image if URL is null
      child: profileImageUrl == null
          ? const Icon(
              Icons.group,
              size: 24,
              color: Colors.white,
            )
          : null,
    );
  }
}
