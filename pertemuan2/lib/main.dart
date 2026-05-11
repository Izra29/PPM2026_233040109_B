// lib/main.dart
import 'package:flutter/material.dart';
import 'profile_model.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profil Saya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          primary: const Color(0xFF6C63FF),
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        profile: ProfileModel(
          name: 'Nauval Azis',
          bio: 'Belajar Flutter!',
          education: 'Teknik Informatika - Semester 6',
          location: 'Bandung, Jawa Barat',
          contact: 'aziznauval042@gmail.com',
          skills: ['Flutter', 'Dart', 'Java', 'Python', 'Git'],
          profileImageBytes: null,
          experiences: [],
        ),
      ),
    );
  }
}