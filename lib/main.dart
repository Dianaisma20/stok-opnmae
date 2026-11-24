import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_pkg;

import 'firebase_options.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AplikasiInventaris());
}

// =====================================================
// APLIKASI
// =====================================================

class AplikasiInventaris extends StatelessWidget {
  const AplikasiInventaris({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DISKOMINFO INVENTARIS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1565c0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff1565c0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffdbe2ea)),
          ),
        ),
      ),
      home: const HalamanLogin(),
    );
  }
}

// =====================================================
// HELPER
// =====================================================

void pesan(BuildContext context, String isi) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(isi),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void logout(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const HalamanLogin(),
    ),
    (route) => false,
  );
}

String tanggalSekarang() {
  final now = DateTime.now();

  return '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';
}

String waktuSekarang() {
  final now = DateTime.now();

  return '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
}

Widget tombolUtama({
  required String teks,
  required VoidCallback? aksi,
  IconData ikon = Icons.save,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: aksi,
      icon: Icon(ikon),
      label: Text(teks),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff1565c0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Widget kartuMenu({
  required String judul,
  required String deskripsi,
  required IconData ikon,
  required Color warna,
  required VoidCallback aksi,
}) {
  return Card(
    elevation: 1,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: warna.withOpacity(0.12),
        child: Icon(
          ikon,
          color: warna,
          size: 27,
        ),
      ),
      title: Text(
        judul,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(deskripsi),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: aksi,
    ),
  );
}

Widget kartuStatistik({
  required String judul,
  required String nilai,
  required IconData ikon,
  required Color warna,
}) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: warna.withOpacity(0.12),
            child: Icon(
              ikon,
              color: warna,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  nilai,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> catatAudit({
  required String aksi,
  required String kodeAset,
  required String namaAset,
  required String pengguna,
  String keterangan = '',
}) async {
  await db.collection('audit_trail').add({
    'aksi': aksi,
    'kode_aset': kodeAset,
    'nama_aset': namaAset,
    'pengguna': pengguna,
    'keterangan': keterangan,
    'waktu': FieldValue.serverTimestamp(),
  });
}

// =====================================================
// LOGIN
// =====================================================

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;
  bool sembunyikanPassword = true;

  Future<void> login() async {
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      pesan(context, 'Email dan password harus diisi.');
      return;
    }

    setState(() => loading = true);

    try {
      final hasil = await db
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (hasil.docs.isEmpty) {
        pesan(context, 'Email atau password salah.');
        return;
      }

      final data = hasil.docs.first.data();

      final nama =
          data['nama']?.toString() ?? 'Pengguna';

      final role =
          data['role']?.toString().toLowerCase() ?? '';

      if (!mounted) return;

      if (role == 'admin' || role == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HalamanAdmin(
              nama: nama,
              email: email,
            ),
          ),
        );
      } else if (role == 'pegawai' || role == 'petugas') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HalamanPegawai(
              nama: nama,
              email: email,
            ),
          ),
        );
      } else if (role == 'pimpinan' || role == 'kadin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HalamanPimpinan(
              nama: nama,
              email: email,
            ),
          ),
        );
      } else {
        pesan(context, 'Role akun tidak dikenali.');
      }
    } catch (e) {
      pesan(context, 'Login gagal: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2,
                  size: 85,
                  color: Color(0xff1565c0),
                ),

                const SizedBox(height: 15),

                const Text(
                  'DISKOMINFO INVENTARIS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Sistem Informasi Inventarisasi Aset',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: passwordCtrl,
                  obscureText: sembunyikanPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        sembunyikanPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          sembunyikanPassword =
                              !sembunyikanPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                tombolUtama(
                  teks: loading
                      ? 'Memproses...'
                      : 'LOGIN',
                  ikon: Icons.login,
                  aksi: loading ? null : login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// DASHBOARD ADMIN
// =====================================================

class HalamanAdmin extends StatelessWidget {
  final String nama;
  final String email;

  const HalamanAdmin({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Selamat datang, $nama',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Administrator Sistem Inventaris',
          ),

          const SizedBox(height: 20),

          const DashboardStatistik(),

          const SizedBox(height: 20),

          kartuMenu(
            judul: 'Data Aset',
            deskripsi:
                'Melihat, mencari, menambah, dan mengoreksi aset.',
            ikon: Icons.inventory_2,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanDaftarAset(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Tambah Aset',
            deskripsi:
                'Mendaftarkan aset baru dengan kode aset otomatis.',
            ikon: Icons.add_box,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanTambahAset(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Impor Data Excel',
            deskripsi:
                'Memasukkan banyak data aset dari file CSV/Excel.',
            ikon: Icons.upload_file,
            warna: Colors.orange,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanImporData(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Inventarisasi',
            deskripsi:
                'Membuat dan memantau sesi inventarisasi aset.',
            ikon: Icons.fact_check,
            warna: Colors.purple,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanInventarisasiAdmin(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Mutasi Aset',
            deskripsi:
                'Memindahkan aset dan melihat riwayat perpindahan.',
            ikon: Icons.compare_arrows,
            warna: Colors.teal,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanMutasiAset(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Usulan Penghapusan',
            deskripsi:
                'Melihat aset yang diusulkan untuk dihapus.',
            ikon: Icons.delete_sweep,
            warna: Colors.red,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanPenghapusan(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Audit Trail',
            deskripsi:
                'Melihat seluruh aktivitas perubahan data.',
            ikon: Icons.history,
            warna: Colors.indigo,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanAuditTrail(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Ekspor Data',
            deskripsi:
                'Mengekspor daftar aset dan hasil inventarisasi.',
            ikon: Icons.download,
            warna: Colors.deepOrange,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanEksporData(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD STATISTIK
// =====================================================

class DashboardStatistik extends StatelessWidget {
  const DashboardStatistik({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('barang').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snapshot.data!.docs;

        int baik = 0;
        int rusakRingan = 0;
        int rusakBerat = 0;

        for (final doc in data) {
          final kondisi =
              doc.data()['kondisi']?.toString();

          if (kondisi == 'Baik') {
            baik++;
          } else if (kondisi == 'Rusak Ringan') {
            rusakRingan++;
          } else if (kondisi == 'Rusak Berat') {
            rusakBerat++;
          }
        }

        return Column(
          children: [
            kartuStatistik(
              judul: 'Total Aset',
              nilai: data.length.toString(),
              ikon: Icons.inventory_2,
              warna: Colors.blue,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: kartuStatistik(
                    judul: 'Baik',
                    nilai: baik.toString(),
                    ikon: Icons.check_circle,
                    warna: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: kartuStatistik(
                    judul: 'Rusak',
                    nilai:
                        (rusakRingan + rusakBerat).toString(),
                    ikon: Icons.warning,
                    warna: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// =====================================================
// DASHBOARD PEGAWAI
// =====================================================

class HalamanPegawai extends StatelessWidget {
  final String nama;
  final String email;

  const HalamanPegawai({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pegawai'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Selamat datang, $nama',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Pengelolaan dan pemeriksaan aset',
          ),

          const SizedBox(height: 25),

          kartuMenu(
            judul: 'Lihat Data Aset',
            deskripsi:
                'Cari dan lihat informasi aset yang tersedia.',
            ikon: Icons.search,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanDaftarAset(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Tambah Aset',
            deskripsi:
                'Tambah aset baru menggunakan kode aset otomatis.',
            ikon: Icons.add_box,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanTambahAset(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Inventarisasi',
            deskripsi:
                'Melakukan pemeriksaan fisik berdasarkan kode aset.',
            ikon: Icons.fact_check,
            warna: Colors.orange,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanInventarisasiPegawai(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Pindahkan Aset',
            deskripsi:
                'Memindahkan aset ke lokasi lain.',
            ikon: Icons.compare_arrows,
            warna: Colors.teal,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanMutasiAset(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Usulkan Penghapusan',
            deskripsi:
                'Mengusulkan aset yang rusak berat atau tidak layak.',
            ikon: Icons.delete_outline,
            warna: Colors.red,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanFormPenghapusan(
                    pengguna: nama,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Riwayat Inventarisasi',
            deskripsi:
                'Melihat hasil pemeriksaan inventarisasi.',
            ikon: Icons.history,
            warna: Colors.purple,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanHasilInventarisasi(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD PIMPINAN
// =====================================================

class HalamanPimpinan extends StatelessWidget {
  final String nama;
  final String email;

  const HalamanPimpinan({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pimpinan'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Selamat datang, $nama',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Persetujuan dan laporan inventarisasi',
          ),

          const SizedBox(height: 25),

          kartuMenu(
            judul: 'Persetujuan Inventarisasi',
            deskripsi:
                'Menyetujui atau menolak hasil inventarisasi.',
            ikon: Icons.fact_check,
            warna: Colors.orange,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const HalamanPersetujuanInventarisasi(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Persetujuan Penghapusan',
            deskripsi:
                'Menyetujui atau menolak usulan penghapusan aset.',
            ikon: Icons.delete_sweep,
            warna: Colors.red,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanPersetujuanPenghapusan(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Berita Acara',
            deskripsi:
                'Melihat berita acara yang dibuat otomatis sistem.',
            ikon: Icons.description,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanBeritaAcara(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Hasil dan Selisih',
            deskripsi:
                'Melihat hasil pemeriksaan dan selisih inventarisasi.',
            ikon: Icons.analytics,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanHasilInventarisasi(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Laporan Resmi',
            deskripsi:
                'Rekap aset berdasarkan lokasi, kategori, dan kondisi.',
            ikon: Icons.assessment,
            warna: Colors.purple,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanLaporan(),
                ),
              );
            },
          ),

          kartuMenu(
            judul: 'Audit Trail',
            deskripsi:
                'Melihat jejak aktivitas pengguna.',
            ikon: Icons.history,
            warna: Colors.indigo,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanAuditTrail(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// TAMBAH ASET
// =====================================================

class HalamanTambahAset extends StatefulWidget {
  final String pengguna;

  const HalamanTambahAset({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanTambahAset> createState() =>
      _HalamanTambahAsetState();
}

class _HalamanTambahAsetState
    extends State<HalamanTambahAset> {
  final namaCtrl = TextEditingController();
  final kategoriCtrl = TextEditingController();
  final lokasiCtrl = TextEditingController();
  final merkCtrl = TextEditingController();
  final tipeCtrl = TextEditingController();
  final tahunCtrl = TextEditingController();
  final keteranganCtrl = TextEditingController();

  String kondisi = 'Baik';
  String kodeAset = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    generateKodeAset();
  }

  Future<void> generateKodeAset() async {
    try {
      final snapshot =
          await db.collection('barang').get();

      int terbesar = 0;

      for (final doc in snapshot.docs) {
        final kode =
            doc.data()['kode_aset']?.toString() ?? '';

        final match =
            RegExp(r'AST-(\d+)').firstMatch(kode);

        if (match != null) {
          final nomor = int.tryParse(
                match.group(1) ?? '',
              ) ??
              0;

          if (nomor > terbesar) {
            terbesar = nomor;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        kodeAset =
            'AST-${(terbesar + 1).toString().padLeft(6, '0')}';
      });
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal membuat kode aset: $e',
        );
      }
    }
  }

  Future<void> simpanAset() async {
    if (namaCtrl.text.trim().isEmpty ||
        kategoriCtrl.text.trim().isEmpty ||
        lokasiCtrl.text.trim().isEmpty) {
      pesan(
        context,
        'Nama, kategori, dan lokasi wajib diisi.',
      );
      return;
    }

    if (kodeAset.isEmpty) {
      pesan(context, 'Kode aset belum tersedia.');
      return;
    }

    setState(() => loading = true);

    try {
      await db.collection('barang').doc(kodeAset).set({
        'kode_aset': kodeAset,
        'nama_barang': namaCtrl.text.trim(),
        'kategori': kategoriCtrl.text.trim(),
        'lokasi': lokasiCtrl.text.trim(),
        'merk': merkCtrl.text.trim(),
        'tipe': tipeCtrl.text.trim(),
        'tahun_perolehan': tahunCtrl.text.trim(),
        'kondisi': kondisi,
        'status_aset': 'aktif',
        'keterangan': keteranganCtrl.text.trim(),
        'created_by': widget.pengguna,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await catatAudit(
        aksi: 'MENAMBAH ASET',
        kodeAset: kodeAset,
        namaAset: namaCtrl.text.trim(),
        pengguna: widget.pengguna,
        keterangan: 'Aset baru ditambahkan.',
      );

      if (!mounted) return;

      pesan(
        context,
        'Aset $kodeAset berhasil disimpan.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        pesan(context, 'Gagal menyimpan aset: $e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    kategoriCtrl.dispose();
    lokasiCtrl.dispose();
    merkCtrl.dispose();
    tipeCtrl.dispose();
    tahunCtrl.dispose();
    keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Aset'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kode Aset Otomatis',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kodeAset.isEmpty
                      ? 'Membuat kode...'
                      : kodeAset,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kode ini menjadi identitas aset di dalam sistem.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Aset',
              prefixIcon: Icon(Icons.inventory_2),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: kategoriCtrl,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: lokasiCtrl,
            decoration: const InputDecoration(
              labelText: 'Lokasi',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: merkCtrl,
            decoration: const InputDecoration(
              labelText: 'Merek',
              prefixIcon: Icon(Icons.branding_watermark),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: tipeCtrl,
            decoration: const InputDecoration(
              labelText: 'Tipe / Model',
              prefixIcon: Icon(Icons.devices),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: tahunCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tahun Perolehan',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: kondisi,
            decoration: const InputDecoration(
              labelText: 'Kondisi',
              prefixIcon: Icon(Icons.health_and_safety),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Baik',
                child: Text('Baik'),
              ),
              DropdownMenuItem(
                value: 'Rusak Ringan',
                child: Text('Rusak Ringan'),
              ),
              DropdownMenuItem(
                value: 'Rusak Berat',
                child: Text('Rusak Berat'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                kondisi = value ?? 'Baik';
              });
            },
          ),

          const SizedBox(height: 15),

          TextField(
            controller: keteranganCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              prefixIcon: Icon(Icons.notes),
            ),
          ),

          const SizedBox(height: 25),

          tombolUtama(
            teks: loading
                ? 'Menyimpan...'
                : 'Simpan Aset',
            ikon: Icons.save,
            aksi: loading ? null : simpanAset,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DAFTAR ASET
// =====================================================

class HalamanDaftarAset extends StatefulWidget {
  const HalamanDaftarAset({super.key});

  @override
  State<HalamanDaftarAset> createState() =>
      _HalamanDaftarAsetState();
}

class _HalamanDaftarAsetState
    extends State<HalamanDaftarAset> {
  String pencarian = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Aset'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: const InputDecoration(
                hintText:
                    'Cari kode, nama, kategori, atau lokasi...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  pencarian = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child:
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('barang')
                  .orderBy('kode_aset')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat data aset:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                final hasil = docs.where((doc) {
                  final data = doc.data();

                  final teks = [
                    data['kode_aset'],
                    data['nama_barang'],
                    data['kategori'],
                    data['lokasi'],
                    data['merk'],
                  ]
                      .map((e) => e?.toString() ?? '')
                      .join(' ')
                      .toLowerCase();

                  return teks.contains(pencarian);
                }).toList();

                if (hasil.isEmpty) {
                  return const Center(
                    child: Text(
                      'Data aset tidak ditemukan.',
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: hasil.length,
                  itemBuilder: (context, index) {
                    final doc = hasil[index];
                    final data = doc.data();

                    final kode =
                        data['kode_aset']?.toString() ?? doc.id;

                    final nama =
                        data['nama_barang']?.toString() ?? '-';

                    final lokasi =
                        data['lokasi']?.toString() ?? '-';

                    final kondisi =
                        data['kondisi']?.toString() ?? '-';

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            kode
                                .replaceAll('AST-', '')
                                .substring(
                                  0,
                                  kode
                                          .replaceAll(
                                            'AST-',
                                            '',
                                          )
                                          .length >
                                      2
                                  ? 2
                                  : kode
                                      .replaceAll(
                                        'AST-',
                                        '',
                                      )
                                      .length,
                                ),
                          ),
                        ),
                        title: Text(
                          nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$kode\n$lokasi • $kondisi',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HalamanDetailAset(
                                kodeAset: kode,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DETAIL ASET
// =====================================================

class HalamanDetailAset extends StatelessWidget {
  final String kodeAset;

  const HalamanDetailAset({
    super.key,
    required this.kodeAset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aset'),
      ),
      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future:
            db.collection('barang').doc(kodeAset).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('Aset tidak ditemukan.'),
            );
          }

          final data = snapshot.data!.data()!;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 60,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['nama_barang']?.toString() ??
                          '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      kodeAset,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              detailItem(
                'Kategori',
                data['kategori'],
              ),

              detailItem(
                'Lokasi',
                data['lokasi'],
              ),

              detailItem(
                'Merek',
                data['merk'],
              ),

              detailItem(
                'Tipe / Model',
                data['tipe'],
              ),

              detailItem(
                'Tahun Perolehan',
                data['tahun_perolehan'],
              ),

              detailItem(
                'Kondisi',
                data['kondisi'],
              ),

              detailItem(
                'Status Aset',
                data['status_aset'],
              ),

              detailItem(
                'Keterangan',
                data['keterangan'],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget detailItem(String judul, dynamic nilai) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          judul,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            nilai?.toString().isEmpty == true
                ? '-'
                : nilai?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MUTASI ASET
// =====================================================

class HalamanMutasiAset extends StatefulWidget {
  final String pengguna;

  const HalamanMutasiAset({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanMutasiAset> createState() =>
      _HalamanMutasiAsetState();
}

class _HalamanMutasiAsetState
    extends State<HalamanMutasiAset> {
  final kodeCtrl = TextEditingController();
  final tujuanCtrl = TextEditingController();
  final alasanCtrl = TextEditingController();

  bool loading = false;

  Future<void> pindahkan() async {
    final kode = kodeCtrl.text.trim();
    final tujuan = tujuanCtrl.text.trim();
    final alasan = alasanCtrl.text.trim();

    if (kode.isEmpty || tujuan.isEmpty) {
      pesan(
        context,
        'Kode aset dan lokasi tujuan wajib diisi.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final ref =
          db.collection('barang').doc(kode);

      final aset = await ref.get();

      if (!aset.exists) {
        pesan(context, 'Aset tidak ditemukan.');
        return;
      }

      final data = aset.data()!;
      final lokasiLama =
          data['lokasi']?.toString() ?? '-';

      await ref.update({
        'lokasi': tujuan,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await db.collection('mutasi_aset').add({
        'kode_aset': kode,
        'nama_aset':
            data['nama_barang']?.toString() ?? '-',
        'lokasi_lama': lokasiLama,
        'lokasi_baru': tujuan,
        'alasan': alasan,
        'pengguna': widget.pengguna,
        'waktu': FieldValue.serverTimestamp(),
      });

      await catatAudit(
        aksi: 'MEMINDAHKAN ASET',
        kodeAset: kode,
        namaAset:
            data['nama_barang']?.toString() ?? '-',
        pengguna: widget.pengguna,
        keterangan:
            'Dari $lokasiLama ke $tujuan.',
      );

      if (!mounted) return;

      pesan(
        context,
        'Aset berhasil dipindahkan.',
      );

      kodeCtrl.clear();
      tujuanCtrl.clear();
      alasanCtrl.clear();
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal memindahkan aset: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    kodeCtrl.dispose();
    tujuanCtrl.dispose();
    alasanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindahkan Aset'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Masukkan kode aset dan lokasi tujuan.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: kodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Kode Aset',
              hintText: 'Contoh: AST-000001',
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: tujuanCtrl,
            decoration: const InputDecoration(
              labelText: 'Lokasi Tujuan',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: alasanCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan Pemindahan',
              prefixIcon: Icon(Icons.notes),
            ),
          ),

          const SizedBox(height: 25),

          tombolUtama(
            teks: loading
                ? 'Menyimpan...'
                : 'Simpan Pemindahan',
            ikon: Icons.compare_arrows,
            aksi: loading ? null : pindahkan,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// IMPOR DATA EXCEL
// =====================================================

class HalamanImporData extends StatefulWidget {
  final String pengguna;

  const HalamanImporData({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanImporData> createState() =>
      _HalamanImporDataState();
}

class _HalamanImporDataState
    extends State<HalamanImporData> {
  bool loading = false;

  String _ambilTeksSpan(excel_pkg.TextSpan span) {
    final buffer = StringBuffer();

    if (span.text != null) {
      buffer.write(span.text);
    }

    if (span.children != null) {
      for (final child in span.children!) {
        buffer.write(_ambilTeksSpan(child));
      }
    }

    return buffer.toString();
  }

  String nilaiCell(dynamic cell) {
    if (cell == null || cell.value == null) {
      return '';
    }

    final value = cell.value;

    if (value is excel_pkg.TextCellValue) {
      return _ambilTeksSpan(value.value).trim();
    }

    if (value is excel_pkg.IntCellValue) {
      return value.value.toString();
    }

    if (value is excel_pkg.DoubleCellValue) {
      return value.value.toString();
    }

    if (value is excel_pkg.BoolCellValue) {
      return value.value.toString();
    }

    if (value is excel_pkg.DateCellValue) {
      return value.asDateTimeLocal().toString();
    }

    if (value is excel_pkg.DateTimeCellValue) {
      return value.asDateTimeLocal().toString();
    }

    if (value is excel_pkg.TimeCellValue) {
      return value.toString();
    }

    if (value is excel_pkg.FormulaCellValue) {
      return value.toString();
    }

    return value.toString().trim();
  }

  Future<void> pilihFile() async {
    try {
      final hasil = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
        allowMultiple: false,
      );

      if (hasil == null || hasil.files.isEmpty) {
        return;
      }

      final file = hasil.files.single;

      if (file.bytes == null) {
        if (mounted) {
          pesan(
            context,
            'File Excel tidak dapat dibaca oleh aplikasi.',
          );
        }
        return;
      }

      setState(() => loading = true);

      await prosesExcel(file.bytes!);

      if (mounted) {
        pesan(
          context,
          'Data Excel berhasil diimpor ke database.',
        );
      }
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal mengimpor Excel: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> prosesExcel(List<int> bytes) async {
    final excel = excel_pkg.Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('File Excel tidak memiliki sheet.');
    }

    final namaSheet = excel.tables.keys.first;
    final sheet = excel.tables[namaSheet];

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Sheet Excel tidak memiliki data.');
    }

    final headerRow = sheet.rows.first;
    final header = headerRow.map(nilaiCell).toList();

    const headerWajib = [
      'No',
      'Kode Aset',
      'Register Aset',
      'Nama Aset',
      'Kategori',
      'Merek',
      'Model',
      'Serial Number',
      'Tahun Perolehan',
      'Kondisi',
      'Nomor BAST',
      'Tanggal BAST',
      'Lokasi',
      'Koordinat',
      'Status',
      'Keterangan',
    ];

    if (header.length < headerWajib.length) {
      throw Exception(
        'Format kolom Excel tidak sesuai. Gunakan file Master Aset.',
      );
    }

    for (int i = 0; i < headerWajib.length; i++) {
      if (header[i].trim() != headerWajib[i]) {
        throw Exception(
          'Kolom ke-${i + 1} harus "${headerWajib[i]}". '
          'Kolom yang ditemukan: "${header[i]}".',
        );
      }
    }

    int berhasil = 0;
    int dilewati = 0;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      String ambil(int index) {
        if (index < 0 || index >= row.length) {
          return '';
        }
        return nilaiCell(row[index]);
      }

      final no = ambil(0);
      final kodeAset = ambil(1);
      final registerAset = ambil(2);
      final namaAset = ambil(3);
      final kategori = ambil(4);
      final merek = ambil(5);
      final model = ambil(6);
      final serialNumber = ambil(7);
      final tahunPerolehan = ambil(8);
      final kondisi = ambil(9);
      final nomorBast = ambil(10);
      final tanggalBast = ambil(11);
      final lokasi = ambil(12);
      final koordinat = ambil(13);
      final status = ambil(14);
      final keterangan = ambil(15);

      if (kodeAset.isEmpty && namaAset.isEmpty) {
        dilewati++;
        continue;
      }

      if (kodeAset.isEmpty) {
        dilewati++;
        continue;
      }

      await db.collection('barang').doc(kodeAset).set({
        'no': no,
        'kode_aset': kodeAset,
        'register_aset': registerAset,
        'nama_barang': namaAset,
        'kategori': kategori,
        'merk': merek,
        'tipe': model,
        'serial_number': serialNumber,
        'tahun_perolehan': tahunPerolehan,
        'kondisi': kondisi.isEmpty ? 'Baik' : kondisi,
        'nomor_bast': nomorBast,
        'tanggal_bast': tanggalBast,
        'lokasi': lokasi,
        'koordinat': koordinat,
        'status_aset': status.isEmpty ? 'Aktif' : status,
        'keterangan': keterangan,
        'updated_at': FieldValue.serverTimestamp(),
        'imported_by': widget.pengguna,
      });

      berhasil++;
    }

    await catatAudit(
      aksi: 'IMPOR DATA EXCEL',
      kodeAset: '-',
      namaAset: '-',
      pengguna: widget.pengguna,
      keterangan:
          '$berhasil data aset berhasil diimpor. $dilewati data dilewati.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impor Data Aset'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.table_view,
                  color: Colors.orange,
                ),
                SizedBox(height: 10),
                Text(
                  'Format Excel yang digunakan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No | Kode Aset | Register Aset | Nama Aset | '
                  'Kategori | Merek | Model | Serial Number | '
                  'Tahun Perolehan | Kondisi | Nomor BAST | '
                  'Tanggal BAST | Lokasi | Koordinat | Status | Keterangan',
                ),
                SizedBox(height: 10),
                Text(
                  'Pilih file Master Aset (.xlsx). Semua baris data akan '
                  'dimasukkan ke collection barang di Firestore.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          tombolUtama(
            teks: loading ? 'Mengimpor Excel...' : 'Pilih File Excel',
            ikon: Icons.upload_file,
            aksi: loading ? null : pilihFile,
          ),
          const SizedBox(height: 20),
          const Text(
            'Catatan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jangan mengubah nama 16 kolom pada baris pertama Excel. '
            'Isi data pada baris di bawahnya, lalu impor file tersebut.',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INVENTARISASI ADMIN
// =====================================================

class HalamanInventarisasiAdmin extends StatefulWidget {
  final String pengguna;

  const HalamanInventarisasiAdmin({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanInventarisasiAdmin> createState() =>
      _HalamanInventarisasiAdminState();
}

class _HalamanInventarisasiAdminState
    extends State<HalamanInventarisasiAdmin> {
  final namaCtrl = TextEditingController();
  final lokasiCtrl = TextEditingController();

  bool loading = false;

  Future<void> buatSesi() async {
    if (namaCtrl.text.trim().isEmpty ||
        lokasiCtrl.text.trim().isEmpty) {
      pesan(
        context,
        'Nama sesi dan lokasi wajib diisi.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await db.collection('inventarisasi').add({
        'nama_sesi': namaCtrl.text.trim(),
        'lokasi': lokasiCtrl.text.trim(),
        'tanggal': tanggalSekarang(),
        'dibuat_oleh': widget.pengguna,
        'status': 'berlangsung',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      pesan(
        context,
        'Sesi inventarisasi berhasil dibuat.',
      );

      namaCtrl.clear();
      lokasiCtrl.clear();
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal membuat sesi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    lokasiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventarisasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Buat Sesi Inventarisasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Inventarisasi',
              prefixIcon: Icon(Icons.assignment),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: lokasiCtrl,
            decoration: const InputDecoration(
              labelText: 'Lokasi',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 20),

          tombolUtama(
            teks: loading
                ? 'Membuat...'
                : 'Buat Sesi',
            ikon: Icons.add,
            aksi: loading ? null : buatSesi,
          ),

          const SizedBox(height: 30),

          const Text(
            'Sesi Inventarisasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('inventarisasi')
                .orderBy(
                  'created_at',
                  descending: true,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Belum ada sesi inventarisasi.',
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.fact_check,
                        ),
                      ),
                      title: Text(
                        data['nama_sesi']
                                ?.toString() ??
                            '-',
                      ),
                      subtitle: Text(
                        '${data['lokasi'] ?? '-'}\n'
                        '${data['tanggal'] ?? '-'}\n'
                        'Status: ${data['status'] ?? '-'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INVENTARISASI PEGAWAI
// =====================================================

class HalamanInventarisasiPegawai
    extends StatefulWidget {
  final String pengguna;

  const HalamanInventarisasiPegawai({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanInventarisasiPegawai> createState() =>
      _HalamanInventarisasiPegawaiState();
}

class _HalamanInventarisasiPegawaiState
    extends State<HalamanInventarisasiPegawai> {
  final kodeCtrl = TextEditingController();
  final lokasiAktualCtrl =
      TextEditingController();
  final catatanCtrl =
      TextEditingController();

  String kondisiAktual = 'Baik';
  String hasil = 'Sesuai';
  bool loading = false;

  Future<void> simpanTemuan() async {
    final kode = kodeCtrl.text.trim();

    if (kode.isEmpty ||
        lokasiAktualCtrl.text.trim().isEmpty) {
      pesan(
        context,
        'Kode aset dan lokasi aktual wajib diisi.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final aset =
          await db.collection('barang').doc(kode).get();

      if (!aset.exists) {
        pesan(
          context,
          'Kode aset tidak ditemukan.',
        );
        return;
      }

      final data = aset.data()!;

      await db.collection('temuan_inventarisasi').add({
        'kode_aset': kode,
        'nama_aset':
            data['nama_barang']?.toString() ?? '-',
        'lokasi_sistem':
            data['lokasi']?.toString() ?? '-',
        'lokasi_aktual':
            lokasiAktualCtrl.text.trim(),
        'kondisi_sistem':
            data['kondisi']?.toString() ?? '-',
        'kondisi_aktual': kondisiAktual,
        'hasil': hasil,
        'catatan': catatanCtrl.text.trim(),
        'petugas': widget.pengguna,
        'tanggal': tanggalSekarang(),
        'created_at':
            FieldValue.serverTimestamp(),
      });

      await catatAudit(
        aksi: 'CEK FISIK ASET',
        kodeAset: kode,
        namaAset:
            data['nama_barang']?.toString() ?? '-',
        pengguna: widget.pengguna,
        keterangan:
            'Hasil pemeriksaan: $hasil.',
      );

      if (!mounted) return;

      pesan(
        context,
        'Hasil pemeriksaan berhasil disimpan.',
      );

      kodeCtrl.clear();
      lokasiAktualCtrl.clear();
      catatanCtrl.clear();
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal menyimpan hasil: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    kodeCtrl.dispose();
    lokasiAktualCtrl.dispose();
    catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Fisik Aset'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Masukkan kode aset secara manual. '
              'Tidak menggunakan scanner barcode.',
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: kodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Kode Aset',
              hintText: 'Contoh AST-000001',
              prefixIcon: Icon(Icons.inventory),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: lokasiAktualCtrl,
            decoration: const InputDecoration(
              labelText: 'Lokasi Aktual',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: kondisiAktual,
            decoration: const InputDecoration(
              labelText: 'Kondisi Fisik',
              prefixIcon:
                  Icon(Icons.health_and_safety),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Baik',
                child: Text('Baik'),
              ),
              DropdownMenuItem(
                value: 'Rusak Ringan',
                child: Text('Rusak Ringan'),
              ),
              DropdownMenuItem(
                value: 'Rusak Berat',
                child: Text('Rusak Berat'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                kondisiAktual =
                    value ?? 'Baik';
              });
            },
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: hasil,
            decoration: const InputDecoration(
              labelText: 'Hasil Pemeriksaan',
              prefixIcon:
                  Icon(Icons.fact_check),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Sesuai',
                child: Text('Sesuai'),
              ),
              DropdownMenuItem(
                value: 'Selisih',
                child: Text('Selisih'),
              ),
              DropdownMenuItem(
                value: 'Tidak Ditemukan',
                child: Text('Tidak Ditemukan'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                hasil =
                    value ?? 'Sesuai';
              });
            },
          ),

          const SizedBox(height: 15),

          TextField(
            controller: catatanCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan Temuan',
              prefixIcon: Icon(Icons.notes),
            ),
          ),

          const SizedBox(height: 25),

          tombolUtama(
            teks: loading
                ? 'Menyimpan...'
                : 'Simpan Hasil Pemeriksaan',
            ikon: Icons.save,
            aksi:
                loading ? null : simpanTemuan,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HASIL INVENTARISASI
// =====================================================

class HalamanHasilInventarisasi
    extends StatelessWidget {
  const HalamanHasilInventarisasi({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hasil Inventarisasi',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('temuan_inventarisasi')
            .orderBy(
              'created_at',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat hasil:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada hasil inventarisasi.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data();

              final hasil =
                  data['hasil']?.toString() ??
                      '-';

              Color warna = Colors.green;

              if (hasil == 'Selisih') {
                warna = Colors.orange;
              } else if (hasil ==
                  'Tidak Ditemukan') {
                warna = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        warna.withOpacity(0.12),
                    child: Icon(
                      hasil == 'Sesuai'
                          ? Icons.check
                          : Icons.warning,
                      color: warna,
                    ),
                  ),
                  title: Text(
                    data['nama_aset']
                            ?.toString() ??
                        '-',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${data['kode_aset'] ?? '-'}\n'
                    'Lokasi: ${data['lokasi_aktual'] ?? '-'}\n'
                    'Hasil: $hasil',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// PERSUTUJUAN INVENTARISASI
// =====================================================

class HalamanPersetujuanInventarisasi
    extends StatelessWidget {
  const HalamanPersetujuanInventarisasi({
    super.key,
  });

  Future<void> setujui(
    BuildContext context,
    String id,
  ) async {
    try {
      await db
          .collection('inventarisasi')
          .doc(id)
          .update({
        'status': 'disetujui',
        'disetujui_pada':
            FieldValue.serverTimestamp(),
      });

      await db.collection('berita_acara').add({
        'nomor':
            'BA-INV-${DateTime.now().millisecondsSinceEpoch}',
        'inventarisasi_id': id,
        'tanggal': tanggalSekarang(),
        'status': 'final',
        'dibuat_otomatis': true,
        'created_at':
            FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        pesan(
          context,
          'Inventarisasi disetujui dan berita acara dibuat.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        pesan(
          context,
          'Gagal menyetujui: $e',
        );
      }
    }
  }

  Future<void> tolak(
    BuildContext context,
    String id,
  ) async {
    final alasanCtrl =
        TextEditingController();

    final alasan =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Alasan Penolakan',
          ),
          content: TextField(
            controller: alasanCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(
              hintText:
                  'Masukkan alasan penolakan',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  alasanCtrl.text.trim(),
                );
              },
              child:
                  const Text('Tolak'),
            ),
          ],
        );
      },
    );

    alasanCtrl.dispose();

    if (alasan == null ||
        alasan.isEmpty) {
      return;
    }

    await db
        .collection('inventarisasi')
        .doc(id)
        .update({
      'status': 'ditolak',
      'alasan_penolakan': alasan,
      'ditolak_pada':
          FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      pesan(
        context,
        'Inventarisasi ditolak.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Persetujuan Inventarisasi'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('inventarisasi')
            .orderBy(
              'created_at',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada inventarisasi.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final doc = docs[index];
              final data =
                  doc.data();

              final status =
                  data['status']
                          ?.toString() ??
                      '-';

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        data['nama_sesi']
                                ?.toString() ??
                            '-',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Lokasi: ${data['lokasi'] ?? '-'}',
                      ),
                      Text(
                        'Tanggal: ${data['tanggal'] ?? '-'}',
                      ),
                      Text(
                        'Status: $status',
                      ),

                      if (status ==
                          'berlangsung') ...[
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  ElevatedButton(
                                onPressed:
                                    () =>
                                        setujui(
                                  context,
                                  doc.id,
                                ),
                                child:
                                    const Text(
                                  'Setujui',
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  OutlinedButton(
                                onPressed:
                                    () =>
                                        tolak(
                                  context,
                                  doc.id,
                                ),
                                child:
                                    const Text(
                                  'Tolak',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// PENGHAPUSAN
// =====================================================

class HalamanFormPenghapusan
    extends StatefulWidget {
  final String pengguna;

  const HalamanFormPenghapusan({
    super.key,
    required this.pengguna,
  });

  @override
  State<HalamanFormPenghapusan> createState() =>
      _HalamanFormPenghapusanState();
}

class _HalamanFormPenghapusanState
    extends State<HalamanFormPenghapusan> {
  final kodeCtrl =
      TextEditingController();
  final alasanCtrl =
      TextEditingController();

  bool loading = false;

  Future<void> ajukan() async {
    final kode =
        kodeCtrl.text.trim();

    final alasan =
        alasanCtrl.text.trim();

    if (kode.isEmpty ||
        alasan.isEmpty) {
      pesan(
        context,
        'Kode aset dan alasan wajib diisi.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final aset = await db
          .collection('barang')
          .doc(kode)
          .get();

      if (!aset.exists) {
        pesan(
          context,
          'Aset tidak ditemukan.',
        );
        return;
      }

      final data =
          aset.data()!;

      await db
          .collection('penghapusan_aset')
          .add({
        'kode_aset': kode,
        'nama_aset':
            data['nama_barang'] ??
                '-',
        'alasan': alasan,
        'pengusul':
            widget.pengguna,
        'status':
            'diajukan',
        'created_at':
            FieldValue.serverTimestamp(),
      });

      await db
          .collection('barang')
          .doc(kode)
          .update({
        'status_aset':
            'diusulkan dihapus',
        'updated_at':
            FieldValue.serverTimestamp(),
      });

      await catatAudit(
        aksi:
            'MENGUSULKAN PENGHAPUSAN',
        kodeAset: kode,
        namaAset:
            data['nama_barang']
                    ?.toString() ??
                '-',
        pengguna:
            widget.pengguna,
        keterangan:
            alasan,
      );

      if (!mounted) return;

      pesan(
        context,
        'Usulan penghapusan berhasil dikirim.',
      );

      kodeCtrl.clear();
      alasanCtrl.clear();
    } catch (e) {
      if (mounted) {
        pesan(
          context,
          'Gagal mengajukan: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(
          () => loading = false,
        );
      }
    }
  }

  @override
  void dispose() {
    kodeCtrl.dispose();
    alasanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Usulan Penghapusan'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(18),
        children: [
          TextField(
            controller: kodeCtrl,
            decoration:
                const InputDecoration(
              labelText:
                  'Kode Aset',
              prefixIcon:
                  Icon(Icons.inventory),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          TextField(
            controller:
                alasanCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(
              labelText:
                  'Alasan Penghapusan',
              prefixIcon:
                  Icon(Icons.notes),
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          tombolUtama(
            teks: loading
                ? 'Mengirim...'
                : 'Ajukan Penghapusan',
            ikon: Icons.send,
            aksi: loading
                ? null
                : ajukan,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// LIST PENGHAPUSAN ADMIN
// =====================================================

class HalamanPenghapusan
    extends StatelessWidget {
  const HalamanPenghapusan({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Usulan Penghapusan'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection(
              'penghapusan_aset',
            )
            .orderBy(
              'created_at',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada usulan penghapusan.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final data =
                  docs[index].data();

              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.delete_outline,
                    ),
                  ),
                  title: Text(
                    data['nama_aset']
                            ?.toString() ??
                        '-',
                  ),
                  subtitle:
                      Text(
                    '${data['kode_aset'] ?? '-'}\n'
                    'Status: ${data['status'] ?? '-'}\n'
                    'Alasan: ${data['alasan'] ?? '-'}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// PERSETUJUAN PENGHAPUSAN
// =====================================================

class HalamanPersetujuanPenghapusan
    extends StatelessWidget {
  const HalamanPersetujuanPenghapusan({
    super.key,
  });

  Future<void> keputusan(
    BuildContext context,
    String id,
    String kode,
    String status,
    String alasan,
  ) async {
    try {
      await db
          .collection(
            'penghapusan_aset',
          )
          .doc(id)
          .update({
        'status': status,
        'alasan_penolakan':
            alasan,
        'diputuskan_pada':
            FieldValue.serverTimestamp(),
      });

      if (status == 'disetujui') {
        await db
            .collection('barang')
            .doc(kode)
            .update({
          'status_aset':
              'dihapus',
          'updated_at':
              FieldValue.serverTimestamp(),
        });
      } else {
        await db
            .collection('barang')
            .doc(kode)
            .update({
          'status_aset':
              'aktif',
          'updated_at':
              FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        pesan(
          context,
          status == 'disetujui'
              ? 'Penghapusan disetujui.'
              : 'Penghapusan ditolak.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        pesan(
          context,
          'Gagal memproses: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Persetujuan Penghapusan',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection(
              'penghapusan_aset',
            )
            .where(
              'status',
              isEqualTo: 'diajukan',
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada usulan yang menunggu persetujuan.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final doc =
                  docs[index];

              final data =
                  doc.data();

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        data['nama_aset']
                                ?.toString() ??
                            '-',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Kode: ${data['kode_aset'] ?? '-'}',
                      ),
                      Text(
                        'Alasan: ${data['alasan'] ?? '-'}',
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                ElevatedButton(
                              onPressed:
                                  () =>
                                      keputusan(
                                context,
                                doc.id,
                                data['kode_aset']
                                        ?.toString() ??
                                    '',
                                'disetujui',
                                '',
                              ),
                              child:
                                  const Text(
                                'Setujui',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child:
                                OutlinedButton(
                              onPressed:
                                  () async {
                                final ctrl =
                                    TextEditingController();

                                final alasan =
                                    await showDialog<
                                        String>(
                                  context:
                                      context,
                                  builder:
                                      (context) {
                                    return AlertDialog(
                                      title:
                                          const Text(
                                        'Alasan Penolakan',
                                      ),
                                      content:
                                          TextField(
                                        controller:
                                            ctrl,
                                        maxLines:
                                            3,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(
                                            context,
                                          ),
                                          child:
                                              const Text(
                                            'Batal',
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(
                                            context,
                                            ctrl.text.trim(),
                                          ),
                                          child:
                                              const Text(
                                            'Tolak',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                ctrl.dispose();

                                if (alasan !=
                                        null &&
                                    alasan
                                        .isNotEmpty) {
                                  await keputusan(
                                    context,
                                    doc.id,
                                    data['kode_aset']
                                            ?.toString() ??
                                        '',
                                    'ditolak',
                                    alasan,
                                  );
                                }
                              },
                              child:
                                  const Text(
                                'Tolak',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// BERITA ACARA
// =====================================================

class HalamanBeritaAcara
    extends StatelessWidget {
  const HalamanBeritaAcara({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Berita Acara'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection(
              'berita_acara',
            )
            .orderBy(
              'created_at',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada berita acara.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final data =
                  docs[index].data();

              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.description,
                    ),
                  ),
                  title: Text(
                    data['nomor']
                            ?.toString() ??
                        '-',
                  ),
                  subtitle:
                      Text(
                    'Tanggal: ${data['tanggal'] ?? '-'}\n'
                    'Status: ${data['status'] ?? '-'}',
                  ),
                  trailing:
                      const Icon(
                    Icons.visibility,
                  ),
                  onTap: () {
                    showDialog(
                      context:
                          context,
                      builder:
                          (context) {
                        return AlertDialog(
                          title:
                              const Text(
                            'Berita Acara',
                          ),
                          content:
                              Text(
                            'Nomor: ${data['nomor'] ?? '-'}\n\n'
                            'Tanggal: ${data['tanggal'] ?? '-'}\n\n'
                            'Berita acara dibuat otomatis setelah hasil inventarisasi disetujui.',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () =>
                                      Navigator.pop(
                                context,
                              ),
                              child:
                                  const Text(
                                'Tutup',
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// AUDIT TRAIL
// =====================================================

class HalamanAuditTrail
    extends StatelessWidget {
  const HalamanAuditTrail({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Audit Trail'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection(
              'audit_trail',
            )
            .orderBy(
              'waktu',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada aktivitas.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final data =
                  docs[index].data();

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child:
                        Icon(Icons.history),
                  ),
                  title: Text(
                    data['aksi']
                            ?.toString() ??
                        '-',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      Text(
                    'Pengguna: ${data['pengguna'] ?? '-'}\n'
                    'Kode: ${data['kode_aset'] ?? '-'}\n'
                    '${data['keterangan'] ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// EKSPOR DATA
// =====================================================

class HalamanEksporData
    extends StatelessWidget {
  const HalamanEksporData({
    super.key,
  });

  Future<void> eksporAset(
      BuildContext context) async {
    try {
      final snapshot =
          await db.collection('barang').get();

      final buffer =
          StringBuffer();

      buffer.writeln(
        'kode_aset,nama_barang,kategori,lokasi,merk,tipe,tahun_perolehan,kondisi,status_aset,keterangan',
      );

      for (final doc
          in snapshot.docs) {
        final d = doc.data();

        buffer.writeln(
          [
            d['kode_aset'],
            d['nama_barang'],
            d['kategori'],
            d['lokasi'],
            d['merk'],
            d['tipe'],
            d['tahun_perolehan'],
            d['kondisi'],
            d['status_aset'],
            d['keterangan'],
          ]
              .map(
                (e) => '"${e ?? ''}"',
              )
              .join(','),
        );
      }

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/data_aset_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      await file.writeAsString(
        '\uFEFF${buffer.toString()}',
        encoding: utf8,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Data Aset Inventaris',
      );

      if (context.mounted) {
        pesan(
          context,
          'Data aset berhasil diekspor.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        pesan(
          context,
          'Gagal mengekspor: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Ekspor Data'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(18),
        children: [
          kartuMenu(
            judul:
                'Ekspor Daftar Aset',
            deskripsi:
                'Mengekspor seluruh data aset ke CSV yang dapat dibuka di Excel.',
            ikon:
                Icons.inventory_2,
            warna:
                Colors.blue,
            aksi: () =>
                eksporAset(context),
          ),

          kartuMenu(
            judul:
                'Hasil Inventarisasi',
            deskripsi:
                'Melihat hasil pemeriksaan aset dan selisih.',
            ikon:
                Icons.fact_check,
            warna:
                Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const HalamanHasilInventarisasi(),
                ),
              );
            },
          ),

          kartuMenu(
            judul:
                'Laporan Resmi',
            deskripsi:
                'Melihat rekap aset berdasarkan lokasi, kategori, dan kondisi.',
            ikon:
                Icons.assessment,
            warna:
                Colors.purple,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const HalamanLaporan(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// LAPORAN
// =====================================================

class HalamanLaporan
    extends StatelessWidget {
  const HalamanLaporan({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Laporan Resmi'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('barang')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          int baik = 0;
          int ringan = 0;
          int berat = 0;

          final lokasi =
              <String, int>{};

          final kategori =
              <String, int>{};

          for (final doc in docs) {
            final d =
                doc.data();

            final kondisi =
                d['kondisi']
                        ?.toString() ??
                    '-';

            if (kondisi ==
                'Baik') {
              baik++;
            } else if (kondisi ==
                'Rusak Ringan') {
              ringan++;
            } else if (kondisi ==
                'Rusak Berat') {
              berat++;
            }

            final lok =
                d['lokasi']
                        ?.toString() ??
                    '-';

            final kat =
                d['kategori']
                        ?.toString() ??
                    '-';

            lokasi[lok] =
                (lokasi[lok] ??
                        0) +
                    1;

            kategori[kat] =
                (kategori[kat] ??
                        0) +
                    1;
          }

          return ListView(
            padding:
                const EdgeInsets.all(
              18,
            ),
            children: [
              const Text(
                'Rekap Aset',
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              kartuStatistik(
                judul:
                    'Total Aset',
                nilai:
                    docs.length.toString(),
                ikon:
                    Icons.inventory_2,
                warna:
                    Colors.blue,
              ),

              const SizedBox(
                height: 10,
              ),

              kartuStatistik(
                judul:
                    'Aset Kondisi Baik',
                nilai:
                    baik.toString(),
                ikon:
                    Icons.check_circle,
                warna:
                    Colors.green,
              ),

              const SizedBox(
                height: 10,
              ),

              kartuStatistik(
                judul:
                    'Rusak Ringan',
                nilai:
                    ringan.toString(),
                ikon:
                    Icons.warning,
                warna:
                    Colors.orange,
              ),

              const SizedBox(
                height: 10,
              ),

              kartuStatistik(
                judul:
                    'Rusak Berat',
                nilai:
                    berat.toString(),
                ikon:
                    Icons.dangerous,
                warna:
                    Colors.red,
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'Aset Berdasarkan Lokasi',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              ...lokasi.entries.map(
                (entry) =>
                    Card(
                  child:
                      ListTile(
                    leading:
                        const Icon(
                      Icons.location_on,
                    ),
                    title:
                        Text(
                      entry.key,
                    ),
                    trailing:
                        Text(
                      entry.value
                          .toString(),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Aset Berdasarkan Kategori',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              ...kategori.entries.map(
                (entry) =>
                    Card(
                  child:
                      ListTile(
                    leading:
                        const Icon(
                      Icons.category,
                    ),
                    title:
                        Text(
                      entry.key,
                    ),
                    trailing:
                        Text(
                      entry.value
                          .toString(),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}