// lib/edit_experience_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_model.dart';

class EditExperiencePage extends StatefulWidget {
  const EditExperiencePage({super.key});

  @override
  State<EditExperiencePage> createState() => _EditExperiencePageState();
}

class _EditExperiencePageState extends State<EditExperiencePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  Uint8List? _imageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _saveExperience() {
    if (_formKey.currentState!.validate()) {
      final exp = Experience(
        imageBytes: _imageBytes,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );
      Navigator.pop(context, exp);
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEDF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
        ),
        child: _imageBytes != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ketuk untuk pilih gambar',
              style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'dari galeri perangkat kamu',
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
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
        title: const Text('Upload Pengalaman',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _saveExperience,
            icon: const Icon(Icons.save, size: 18),
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
              _buildImagePicker(),
              const SizedBox(height: 20),

              const Text('Informasi Pengalaman',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _titleController,
                label: 'Judul *',
                prefixIcon: Icons.title,
                validator: (v) => v == null || v.isEmpty
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _descController,
                label: 'Deskripsi',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveExperience,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Simpan Pengalaman',
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