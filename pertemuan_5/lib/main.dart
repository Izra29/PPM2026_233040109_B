import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// ============================================================
//  ENTRY POINT
//  ⚠️ WidgetsFlutterBinding.ensureInitialized() WAJIB dipanggil
//     sebelum runApp() karena sqflite pakai platform channel.
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ============================================================
//  MODEL — Catatan
//
//  Perubahan dari P3:
//  • field `id` sekarang `int?` (nullable) agar SQLite bisa
//    auto-generate saat insert baru.
//  • field `id` String lama dihapus (tidak perlu lagi).
//  • tambah toMap(), fromMap(), copyWith() untuk bridge
//    antara objek Dart ↔ baris database.
// ============================================================
class Catatan {
  final int? id; // null saat belum disimpan ke DB
  final String judul;
  final String isi;
  final String kategori;
  final DateTime dibuatPada;

  Catatan({
    this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
  });

  /// Dart object → Map (untuk insert/update ke SQLite)
  Map<String, Object?> toMap() => {
    // Jangan sertakan 'id' kalau masih null
    // supaya SQLite yang generate via AUTOINCREMENT
    if (id != null) 'id': id,
    'judul': judul,
    'isi': isi,
    'kategori': kategori,
    // SQLite tidak punya tipe DateTime, simpan sebagai int
    'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
  };

  /// Map (baris DB) → Dart object
  static Catatan fromMap(Map<String, Object?> m) => Catatan(
    id: m['id'] as int?,
    judul: m['judul'] as String,
    isi: m['isi'] as String,
    kategori: m['kategori'] as String,
    dibuatPada:
    DateTime.fromMillisecondsSinceEpoch(m['dibuat_pada'] as int),
  );

  /// Helper untuk mode Edit — kembalikan salinan dengan field baru
  Catatan copyWith({String? judul, String? isi, String? kategori}) => Catatan(
    id: id,
    judul: judul ?? this.judul,
    isi: isi ?? this.isi,
    kategori: kategori ?? this.kategori,
    dibuatPada: dibuatPada,
  );
}

// ============================================================
//  DB HELPER — Repository / Singleton
//
//  Semua logika SQL dikumpulkan di sini agar widget tidak
//  tahu detail implementasi database (separation of concerns).
//
//  Pattern Singleton: hanya ada SATU instance DbHelper
//  selama app hidup → database tidak dibuka berkali-kali.
// ============================================================
class DbHelper {
  DbHelper._(); // private constructor → tidak bisa new DbHelper()
  static final DbHelper instance = DbHelper._(); // satu-satunya instance

  static const _dbName = 'catatan.db';
  static const _dbVersion = 1;
  static const _tabel = 'catatan';

  Database? _db; // cache, null sampai pertama kali diakses

  /// Getter async: buka DB sekali, lalu kembalikan cache
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    // Cari direktori default penyimpanan DB di device
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      // onCreate hanya dipanggil SEKALI saat file DB belum ada
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tabel (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            judul       TEXT    NOT NULL,
            isi         TEXT    NOT NULL,
            kategori    TEXT    NOT NULL,
            dibuat_pada INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ---------- CRUD ----------

  /// INSERT: simpan catatan baru, return id yang di-generate
  Future<int> insert(Catatan c) async {
    final db = await database;
    return db.insert(_tabel, c.toMap());
  }

  /// READ ALL: ambil semua catatan, diurut terbaru dulu
  Future<List<Catatan>> getAll() async {
    final db = await database;
    final rows = await db.query(_tabel, orderBy: 'dibuat_pada DESC');
    return rows.map(Catatan.fromMap).toList();
  }

  /// UPDATE: perbarui catatan yang sudah ada (wajib punya id)
  Future<int> update(Catatan c) async {
    assert(c.id != null, 'update() dipanggil dengan Catatan tanpa id');
    final db = await database;
    return db.update(
      _tabel,
      c.toMap(),
      where: 'id = ?', // ✅ selalu pakai ? untuk anti SQL injection
      whereArgs: [c.id],
    );
  }

  /// DELETE: hapus catatan berdasarkan id
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      _tabel,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ============================================================
//  MAIN APP — MaterialApp dengan Named Routes
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      // onGenerateRoute dipakai karena beberapa route butuh argumen
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomePage());

          case '/form':
          // arguments bisa null (mode CREATE) atau Catatan (mode EDIT)
            final initial = settings.arguments as Catatan?;
            return MaterialPageRoute(
              builder: (_) => CatatanFormPage(initial: initial),
            );

          case '/detail':
            final catatan = settings.arguments as Catatan;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(catatan: catatan),
            );
        }
        return null;
      },
    );
  }
}

// ============================================================
//  HOME PAGE
//
//  Perubahan dari P3:
//  • List _catatan (memori) → diganti Future<List<Catatan>>
//    yang mengambil data dari SQLite.
//  • ListView langsung → FutureBuilder dengan 3 state:
//    loading / error / data.
//  • Refresh dilakukan dengan memanggil _muatUlang() yang
//    mengganti future → FutureBuilder otomatis rebuild.
//  • Hapus item menggunakan dialog konfirmasi (AlertDialog).
// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Pegang Future di field State, BUKAN buat baru di dalam builder
  // (kalau baru di builder → query dijalankan setiap rebuild → loop)
  late Future<List<Catatan>> _futureCatatan;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  /// Ganti _futureCatatan dengan query baru → FutureBuilder rebuild
  void _muatUlang() {
    setState(() {
      _futureCatatan = DbHelper.instance.getAll();
    });
  }

  /// Buka form (tambah atau edit), lalu muat ulang setelah kembali.
  /// Pola "refresh on return" lebih robust karena DB = single source of truth.
  Future<void> _bukaForm({Catatan? initial}) async {
    await Navigator.pushNamed(context, '/form', arguments: initial);
    _muatUlang();
  }

  /// Dialog konfirmasi sebelum hapus (aksi destruktif)
  Future<void> _konfirmasiHapus(Catatan c) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${c.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await DbHelper.instance.delete(c.id!);
      if (!mounted) return;
      _muatUlang();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${c.judul}" dihapus')),
      );
    }
  }

  /// Widget satu item catatan di ListView
  Widget _itemCatatan(Catatan c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(c.judul,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(c.kategori),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _bukaForm(initial: c),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              color: Colors.red,
              onPressed: () => _konfirmasiHapus(c),
            ),
          ],
        ),
        onTap: () async {
          // Buka detail, lalu refresh (mungkin ada edit dari detail)
          await Navigator.pushNamed(context, '/detail', arguments: c);
          _muatUlang();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Mahasiswa'),
        centerTitle: true,
        actions: [
          // Tombol refresh manual (berguna saat debugging)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _muatUlang,
          ),
        ],
      ),

      // ── FutureBuilder: tampilkan loading / error / data ──
      body: FutureBuilder<List<Catatan>>(
        future: _futureCatatan,
        builder: (context, snapshot) {
          // State 1: masih loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // State 2: terjadi error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Terjadi error:\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _muatUlang,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          // State 3: data berhasil dimuat
          final data = snapshot.data ?? const [];

          // Kalau kosong → tampilkan empty state
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada catatan.',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap tombol + untuk menambah catatan baru.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Ada data → tampilkan list
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) => _itemCatatan(data[i]),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

// ============================================================
//  CATATAN FORM PAGE — satu form untuk CREATE dan EDIT
//
//  Perubahan dari P3 (TambahCatatanPage):
//  • Rename → CatatanFormPage, parameter `catatan` → `initial`
//  • Mode ditentukan dari `initial`:
//      null     → CREATE → DbHelper.insert()
//      Catatan  → EDIT   → DbHelper.update()
//  • Simpan langsung ke DB (bukan pop(context, catatan))
//  • Tambah state _menyimpan untuk disable tombol saat loading
//  • Wrap dengan try/catch untuk handle error DB
// ============================================================
class CatatanFormPage extends StatefulWidget {
  final Catatan? initial;
  const CatatanFormPage({super.key, this.initial});

  @override
  State<CatatanFormPage> createState() => _CatatanFormPageState();
}

class _CatatanFormPageState extends State<CatatanFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _isiCtrl;
  late String _kategori;
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  bool get _isEdit => widget.initial != null; // helper mode
  bool _menyimpan = false; // untuk disable tombol saat proses simpan

  @override
  void initState() {
    super.initState();
    // Pre-fill field kalau mode EDIT, kosong kalau CREATE
    _judulCtrl = TextEditingController(text: widget.initial?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.initial?.isi ?? '');
    _kategori = widget.initial?.kategori ?? 'Kuliah';
  }

  @override
  void dispose() {
    // Penting: bebaskan controller agar tidak memory leak
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    // Hentikan kalau validasi gagal
    if (!_formKey.currentState!.validate()) return;

    setState(() => _menyimpan = true);

    try {
      if (_isEdit) {
        // Mode EDIT: copyWith nilai baru, lalu update ke DB
        final updated = widget.initial!.copyWith(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
        );
        await DbHelper.instance.update(updated);
      } else {
        // Mode CREATE: buat objek baru (id null → DB yang generate)
        final baru = Catatan(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
          dibuatPada: DateTime.now(),
        );
        await DbHelper.instance.insert(baru);
      }

      // Cek mounted setelah await (widget mungkin sudah di-dispose)
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Catatan diperbarui ✓' : 'Catatan ditambahkan ✓'),
      ));
      Navigator.pop(context); // kembali ke Home (Home akan _muatUlang)
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false); // aktifkan tombol lagi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul AppBar berbeda sesuai mode
        title: Text(_isEdit ? 'Edit Catatan' : 'Tambah Catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Field Judul
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                if (v.trim().length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),

            // Field Isi
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            // Tombol Simpan — tampilkan loading indicator saat proses
            FilledButton.icon(
              onPressed: _menyimpan ? null : _simpan,
              icon: _menyimpan
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save),
              label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Catatan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  DETAIL CATATAN PAGE
//
//  Perubahan dari P3:
//  • Tombol Edit di AppBar membuka /form dengan objek catatan
//    sebagai argumen (mode EDIT).
//  • Setelah edit selesai, Detail langsung pop supaya Home
//    bisa _muatUlang() dan menampilkan data terbaru.
//    (Objek `catatan` di sini adalah snapshot lama — kalau
//     tidak ditutup, user akan lihat data stale.)
// ============================================================
class DetailCatatanPage extends StatelessWidget {
  final Catatan catatan;
  const DetailCatatanPage({super.key, required this.catatan});

  String _formatTanggal(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              // Buka form mode EDIT
              await Navigator.pushNamed(context, '/form', arguments: catatan);
              // Setelah edit selesai, tutup Detail juga supaya
              // Home langsung refresh dan user tidak melihat data lama
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Text(
              catatan.judul,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Baris info: kategori chip + tanggal
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(catatan.kategori),
                  backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
                ),
                Text(
                  _formatTanggal(catatan.dibuatPada),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 32),

            // Isi catatan
            Text(
              catatan.isi,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}