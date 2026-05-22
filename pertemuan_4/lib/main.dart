import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// MODEL DATA (Dengan ID untuk fitur Edit)
// ==========================================
class Catatan {
  final String id;
  final String judul;
  final String isi;
  final String kategori;
  final DateTime dibuatPada;

  Catatan({
    required this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
  });
}

// ==========================================
// MAIN APPLICATION
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Navigasi fleksibel untuk Tambah & Edit
        if (settings.name == '/form') {
          final catatanLama = settings.arguments as Catatan?;
          return MaterialPageRoute(
            builder: (_) => TambahCatatanPage(catatan: catatanLama),
          );
        }
        if (settings.name == '/detail') {
          final catatan = settings.arguments as Catatan;
          return MaterialPageRoute(
            builder: (_) => DetailCatatanPage(catatan: catatan),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}

// ==========================================
// HOME PAGE
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Catatan> _catatan = [
    Catatan(
      id: '1',
      judul: 'Belajar Flutter',
      isi: 'Mempelajari Stateful Widget, Form, dan Navigation.',
      kategori: 'Kuliah',
      dibuatPada: DateTime.now(),
    ),
  ];

  // Fungsi untuk buka form (bisa tambah atau edit)
  Future<void> _navigasiForm({Catatan? dataLama}) async {
    final hasil = await Navigator.pushNamed(context, '/form', arguments: dataLama);

    if (hasil is Catatan) {
      setState(() {
        if (dataLama == null) {
          _catatan.add(hasil); // Tambah baru
        } else {
          // Update data yang sudah ada berdasarkan ID
          final index = _catatan.indexWhere((c) => c.id == hasil.id);
          if (index != -1) _catatan[index] = hasil;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Mahasiswa'), centerTitle: true),
      body: _catatan.isEmpty
          ? const Center(child: Text('Belum ada catatan'))
          : ListView.builder(
        itemCount: _catatan.length,
        itemBuilder: (context, i) {
          final c = _catatan[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(c.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.kategori),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                // Jika kembali dari detail, ada kemungkinan data di-update di sana
                final update = await Navigator.pushNamed(context, '/detail', arguments: c);
                if (update is Catatan) {
                  setState(() {
                    final index = _catatan.indexWhere((element) => element.id == update.id);
                    _catatan[index] = update;
                  });
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigasiForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// TAMBAH / EDIT CATATAN PAGE (Reuse)
// ==========================================
class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatan;
  const TambahCatatanPage({super.key, this.catatan});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulCtrl;
  late TextEditingController _isiCtrl;
  late String _kategori;
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    // Jika widget.catatan tidak null, berarti mode EDIT (isi data lama)
    _judulCtrl = TextEditingController(text: widget.catatan?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.catatan?.isi ?? '');
    _kategori = widget.catatan?.kategori ?? 'Kuliah';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final hasil = Catatan(
      // Jika edit pakai ID lama, jika baru buat ID dari timestamp
      id: widget.catatan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _kategori,
      dibuatPada: widget.catatan?.dibuatPada ?? DateTime.now(),
    );

    Navigator.pop(context, hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.catatan == null ? 'Tambah Catatan' : 'Edit Catatan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: _kategoriOpsi.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Isi', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _simpan, child: const Text('Simpan Catatan')),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DETAIL CATATAN PAGE
// ==========================================
class DetailCatatanPage extends StatelessWidget {
  final Catatan catatan;
  const DetailCatatanPage({super.key, required this.catatan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        actions: [
          // Tombol Edit di Detail (Tugas Mandiri)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final hasilEdit = await Navigator.pushNamed(
                  context,
                  '/form',
                  arguments: catatan
              );
              // Jika data diedit, kirim data baru saat pop kembali ke Home
              if (hasilEdit != null) {
                Navigator.pop(context, hasilEdit);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catatan.judul, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Chip(label: Text(catatan.kategori), backgroundColor: Colors.indigo.withOpacity(0.1)),
            const Divider(height: 32),
            Text(catatan.isi, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 