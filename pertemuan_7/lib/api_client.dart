import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'main.dart' show Catatan;

// ============================================================
//  CUSTOM EXCEPTION
//  Dibuat sendiri agar UI bisa tampilkan pesan yang spesifik
//  dari server (mis. "API key tidak valid", "validasi gagal")
//  bukan hanya stacktrace generic.
// ============================================================
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ============================================================
//  API CLIENT — Repository / Singleton
//
//  Semua logika HTTP dikumpulkan di sini agar widget tidak
//  tahu detail URL, header, atau parsing JSON.
//
//  Signature method sengaja dibuat sama dengan DbHelper (P4):
//    getAll(), insert(), update(), delete()
//  → UI di main.dart tidak perlu banyak berubah.
// ============================================================
class ApiClient {
  ApiClient._(); // private constructor
  static final ApiClient instance = ApiClient._();

  // === Konfigurasi API (dari modul, disiapkan dosen) ===
  static const String _baseUrl =
      'https://besab-production.up.railway.app/api';
  static const String _apiKey =
      '8f38b5fbf0bc437285f2c62ed6e447eab56f78c8f95239a7';
  // =====================================================

  static const _timeout = Duration(seconds: 10);

  /// Header wajib untuk semua request
  Map<String, String> get _headers => {
    'X-API-Key': _apiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ───────────────── CRUD ─────────────────

  /// GET /catatan → List<Catatan>
  Future<List<Catatan>> getAll() async {
    final res = await _send(
          () => http.get(Uri.parse('$_baseUrl/catatan'), headers: _headers),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(Catatan.fromJson).toList();
  }

  /// GET /catatan/{id} → Catatan
  Future<Catatan> getById(int id) async {
    final res = await _send(
          () => http.get(Uri.parse('$_baseUrl/catatan/$id'), headers: _headers),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Catatan.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// POST /catatan → Catatan (yang baru dibuat, sudah ada id dari server)
  Future<Catatan> insert(Catatan c) async {
    final res = await _send(
          () => http.post(
        Uri.parse('$_baseUrl/catatan'),
        headers: _headers,
        body: jsonEncode(c.toJson()),
      ),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Catatan.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// PUT /catatan/{id} → Catatan (yang sudah diupdate)
  Future<Catatan> update(Catatan c) async {
    assert(c.id != null, 'update() dipanggil dengan Catatan tanpa id');
    final res = await _send(
          () => http.put(
        Uri.parse('$_baseUrl/catatan/${c.id}'),
        headers: _headers,
        body: jsonEncode(c.toJson()),
      ),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Catatan.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// DELETE /catatan/{id}
  Future<void> delete(int id) async {
    await _send(
          () => http.delete(
        Uri.parse('$_baseUrl/catatan/$id'),
        headers: _headers,
      ),
    );
  }

  // ───────────────── Helper internal ─────────────────

  /// Kirim request, tangani 3 kelas error:
  /// 1. Tidak ada internet (SocketException)
  /// 2. Timeout (TimeoutException)
  /// 3. HTTP error 4xx/5xx (ApiException)
  Future<http.Response> _send(
      Future<http.Response> Function() req,
      ) async {
    try {
      final res = await req().timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return res;
      throw ApiException(res.statusCode, _extractMessage(res));
    } on SocketException {
      throw ApiException(0, 'Tidak ada koneksi internet.');
    } on TimeoutException {
      throw ApiException(0, 'Server tidak merespons (timeout 10 detik).');
    }
  }

  /// Coba ambil field "message" dari body JSON, fallback ke "HTTP xxx"
  String _extractMessage(http.Response res) {
    try {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      return (m['message'] as String?) ?? 'HTTP ${res.statusCode}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}