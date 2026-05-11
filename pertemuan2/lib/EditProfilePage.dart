// lib/EditProfilePage.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_model.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _educationController;
  late TextEditingController _locationController;
  late TextEditingController _contactController;
  late TextEditingController _skillsController;

  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _bioController = TextEditingController(text: p.bio);
    _educationController = TextEditingController(text: p.education);
    _locationController = TextEditingController(text: p.location);
    _contactController = TextEditingController(text: p.contact);
    _skillsController = TextEditingController(text: p.skills.join(', '));
    _profileImageBytes = p.profileImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      // Baca sebagai bytes (Uint8List) — tidak butuh permission storage
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = ProfileModel(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        education: _educationController.text.trim(),
        location: _locationController.text.trim(),
        contact: _contactController.text.trim(),
        skills: _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        profileImageBytes: _profileImageBytes,
        experiences: widget.profile.experiences,
      );
      Navigator.pop(context, updatedProfile);
    }
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        _profileImageBytes != null
            ? CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(_profileImageBytes!),
        )
            : const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF6C63FF),
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6C63FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profil',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Simpan'),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text('Foto Profil',
                        style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    _buildAvatar(),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 5),
                          Text('Ganti Foto dari Galeri',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              const Text('Informasi Profil',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap *',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _bioController,
                label: 'Bio / Tentang',
                prefixIcon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _educationController,
                label: 'Pendidikan',
                prefixIcon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _locationController,
                label: 'Lokasi',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _contactController,
                label: 'Kontak (Email)',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _skillsController,
                label: 'Skills (pisahkan dengan koma)',
                prefixIcon: Icons.star_outline,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3A6B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}