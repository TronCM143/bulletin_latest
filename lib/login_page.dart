import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'creators folder/home_page.dart';
import 'student folder/home.dart'; // Import your HomePage for students
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // For toggling password visibility

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final id = _idController.text.trim();
        final password = _passwordController.text.trim();

        // First, check in the users_students collection
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc('students')
            .collection(id)
            .doc('account_details') // Check by student ID
            .get();

        if (studentDoc.exists) {
          String storedPassword = studentDoc['password'];
          if (storedPassword == password) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHomePage(
                  schoolId: id,
                ), // Pass the school ID
              ),
            );
            return; // Exit the function if student login is successful
          } else {
            // Incorrect password for students collection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password.')),
            );
            return; // Exit if password is incorrect
          }
        }

        // If not found in users_students, check in creator collection
        // If not found in users_students, check in creator collection
        DocumentSnapshot creatorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc('creators')
            .collection(id) // Use clubEmail as the collection name
            .doc('account_details') // Check by club email
            .get();

        if (creatorDoc.exists) {
          String storedPassword = creatorDoc['password'];
          String approvalStatus = creatorDoc['approvalStatus'];
          if (storedPassword == password) {
            if (approvalStatus == 'accepted') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatorHomePage(
                    clubEmail: id, // Pass club email
                  ),
                ),
              );
              return; // Exit the function if creator login is successful
            } else {
              // Account is not accepted
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account not accepted yet.')),
              );
              return; // Exit if account is not accepted
            }
          } else {
            // Incorrect password for creator collection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password.')),
            );
            return; // Exit if password is incorrect
          }
        }

        // If neither student ID nor club email is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID not found.')),
        );
      } catch (e) {
        // Handle any errors that occur during login
        print('Error during login: $e'); // Debug log for developers
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevents layout distortion when keyboard appears
      body: Stack(
        fit: StackFit.expand, // Ensures the background covers the whole screen
        children: [
          // Background image using Network Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ndmu.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Vertically center the content
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Horizontally center the content
              children: [
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.85, // 85% width of the screen
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.30,
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.3), // Transparent background
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3), // Soft border
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Heading
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),
                              // Username/ID Input Field
                              TextFormField(
                                controller: _idController,
                                decoration: InputDecoration(
                                  hintText:
                                      'School ID', // This is the placeholder that disappears
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your Username';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              // Password Input Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText:
                                      'Password', // This is the placeholder that disappears
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 5),
                              // Remember Me and Forgot Password Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // Toggle the checkbox when the text is tapped
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) {
                                            setState(() {
                                              _rememberMe = val!;
                                            });
                                          },
                                        ),
                                        Text(
                                          'Remember Me',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              // Sign In Button
                              SizedBox(
                                width: 200, // Set your desired width here
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              // Social Media Login Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Dont Have Account?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    // You can keep or remove the SizedBox if not needed
                                    // Set your desired height if needed
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreateAccountPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors
                                              .white, // Set the text color to white
                                          fontSize:
                                              16, // Adjust font size as needed
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
