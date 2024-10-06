import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_post.dart'; // Ensure this is the correct path for AddPostDialog
import 'profile.dart'; // Ensure this is the correct path for ProfileDialog
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatorFunctions {
  static void fetchCreatorInfo(String clubEmail,
      Function(String, String, String) onUpdate, BuildContext context) {
    FirebaseFirestore.instance
        .collection('creator')
        .doc(clubEmail)
        .snapshots()
        .listen((creatorSnapshot) {
      if (creatorSnapshot.exists && creatorSnapshot.data() != null) {
        final creatorData = creatorSnapshot.data() as Map<String, dynamic>;
        onUpdate(
          creatorData['clubName'] ?? 'N/A',
          creatorData['department'] ?? 'N/A',
          creatorData['email'] ?? 'N/A',
        );
      } else {
        onUpdate('N/A', 'N/A', 'N/A');
      }
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch creator info: $error')),
      );
      onUpdate('Error', 'Error', 'Error');
    });
  }

  static void showAddPostDialog(BuildContext context, String clubEmail) {
    showDialog(
      context: context,
      builder: (context) => AddPostDialog(clubEmail: clubEmail),
    );
  }

  static void showProfileDialog(
      BuildContext context, String clubName, String department, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return ProfileDialog(
          clubName: clubName,
          department: department,
          email: email,
        );
      },
    );
  }
}

// Method to pick an image from gallery or camera
Future<void> pickImage(ImageSource source, Function(File) setProfileImage,
    Function(String) setProfileImageURL, String email) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setProfileImage(File(pickedFile.path));

    // Upload the image to Firebase Storage and save the reference in Firestore
    await uploadImageToFirebase(pickedFile.path, setProfileImageURL, email);
  }
}

// Upload the picked image to Firebase Storage
Future<void> uploadImageToFirebase(
    String filePath, Function(String) setProfileImageURL, String email) async {
  try {
    // Create a unique file name for the image based on timestamp
    String fileName =
        'profile_images/${email}_${DateTime.now().millisecondsSinceEpoch}.png';

    // Reference to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    // Upload the file to Firebase Storage
    final uploadTask = storageRef.putFile(File(filePath));
    final snapshot = await uploadTask.whenComplete(() => null);

    // Get the download URL of the uploaded image
    final downloadURL = await snapshot.ref.getDownloadURL();

    // Save the download URL in Firestore under the creator's email
    await saveImageURLToFirestore(downloadURL, email);
    setProfileImageURL(downloadURL); // Set the URL to display the image
  } catch (e) {
    print('Error uploading image: $e');
  }
}

// Save the image URL to Firestore under the creator's document
Future<void> saveImageURLToFirestore(String downloadURL, String email) async {
  try {
    // Reference to the 'creators' collection in Firestore
    final creatorDocRef =
        FirebaseFirestore.instance.collection('creator').doc(email);

    // Update the document with the image URL
    await creatorDocRef.set({
      'profileImageURL': downloadURL,
    }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
  } catch (e) {
    print('Error saving image URL to Firestore: $e');
  }
}

// Load the profile image from Firestore
Future<void> loadProfileImage(
    String email, Function(String?) setProfileImageURL) async {
  try {
    // Get the document from Firestore
    final creatorDoc =
        await FirebaseFirestore.instance.collection('creator').doc(email).get();

    if (creatorDoc.exists) {
      // Check if 'profileImageURL' field exists
      if (creatorDoc.data() != null &&
          creatorDoc.data()!.containsKey('profileImageURL')) {
        // Set the profile image URL if it exists in Firestore
        setProfileImageURL(creatorDoc.data()!['profileImageURL']);
      }
    }
  } catch (e) {
    print('Error loading profile image: $e');
  }
}
