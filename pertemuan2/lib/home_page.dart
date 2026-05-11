// lib/home_page.dart
import 'package:flutter/material.dart';
import 'profile_model.dart';
import 'EditProfilePage.dart';
import 'edit_experience_page.dart';

class HomePage extends StatefulWidget {
  final ProfileModel profile;

  const HomePage({super.key, required this.profile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ProfileModel profile;

  @override
  void initState() {
    super.initState();
    profile = widget.profile;
  }

  void _goToEditProfile() async {
    final updatedProfile = await Navigator.push<ProfileModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(profile: profile),
      ),
    );
    if (updatedProfile != null) {
      setState(() {
        profile = updatedProfile;
      });
    }
  }

  void _goToEditExperience() async {
    final result = await Navigator.push<Experience>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditExperiencePage(),
      ),
    );
    if (result != null) {
      setState(() {
        profile.experiences.add(result);
      });
    }
  }

  Widget _buildAvatar() {
    if (profile.profileImageBytes != null) {
      return CircleAvatar(
        radius: 45,
        backgroundImage: MemoryImage(profile.profileImageBytes!),
      );
    }
    return const CircleAvatar(
      radius: 45,
      backgroundColor: Color(0xFF6C63FF),
      child: Icon(Icons.person, size: 45, color: Colors.white),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Skills',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: profile.skills
                .map((skill) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(skill, style: const TextStyle(fontSize: 12)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.collections_bookmark,
                    color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Pengalaman',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${profile.experiences.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (profile.experiences.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Belum ada pengalaman.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ...profile.experiences.map((exp) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: exp.imageBytes != null
                      ? Image.memory(
                    exp.imageBytes!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(exp.description,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Profil Saya',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6C63FF)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu Utama',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('Widget Gallery'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload Pengalaman'),
              onTap: () {
                Navigator.pop(context);
                _goToEditExperience();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  Text(profile.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(profile.education,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('12', 'Post'),
                      _buildStat('128', 'Teman'),
                      _buildStat('1.2K', 'Like'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.info_outline,
              iconColor: Colors.blue,
              title: 'Tentang',
              subtitle: profile.bio,
            ),
            _buildInfoRow(
              icon: Icons.school_outlined,
              iconColor: Colors.teal,
              title: 'Pendidikan',
              subtitle: profile.education,
            ),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              iconColor: Colors.red,
              title: 'Lokasi',
              subtitle: profile.location,
            ),
            _buildInfoRow(
              icon: Icons.email_outlined,
              iconColor: Colors.blue.shade700,
              title: 'Kontak',
              subtitle: profile.contact,
            ),
            _buildSkillsSection(),
            _buildExperienceSection(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _goToEditProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}