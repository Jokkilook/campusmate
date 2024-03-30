import 'package:campusmate/db_test.dart';
import 'package:campusmate/firebase_test.dart';
import 'package:campusmate/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenList(),
    );
  }
}

class ScreenList extends StatelessWidget {
  const ScreenList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FirebaseTest().initFirebase();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            /// MainScreen
            ListTile(
              title: const Text("MainScreen", style: TextStyle(fontSize: 24)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              ),
            ),

            /// LoginScreen
            ListTile(
              title: const Text("LoginScreen", style: TextStyle(fontSize: 24)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              ),
            ),

            /// DB TEST
            ListTile(
              title: const Text("DB TEST", style: TextStyle(fontSize: 24)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DBTest()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
