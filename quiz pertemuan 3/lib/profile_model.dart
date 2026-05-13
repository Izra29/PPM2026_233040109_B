// lib/profile_model.dart
import 'dart:typed_data';

class Experience {
  Uint8List? imageBytes;
  String title;
  String description;

  Experience({
    this.imageBytes,
    required this.title,
    required this.description,
  });
}

class ProfileModel {
  String name;
  String bio;
  String education;
  String location;
  String contact;
  List<String> skills;
  Uint8List? profileImageBytes;
  List<Experience> experiences;

  ProfileModel({
    required this.name,
    required this.bio,
    required this.education,
    required this.location,
    required this.contact,
    required this.skills,
    this.profileImageBytes,
    required this.experiences,
  });
}