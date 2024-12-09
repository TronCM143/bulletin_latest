import 'package:bulletin/creators%20folder/create_account.dart';
import 'package:bulletin/student%20folder/create_account.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/ALL.png'),
                                fit: BoxFit.cover)),
                      ), // i want to put an image here
                    ),
                  ],
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Student account creation page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentCreateAccount(),
                        ),
                      );
                    },
                    child: Text('Student'),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.black,
            height: 1,
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/OSAD.png'),
                          fit: BoxFit.cover)),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorCreateAccount(),
                        ),
                      );
                    },
                    child: Text('Creator'),
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
