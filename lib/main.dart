
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'firebase_options.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AplikasiOpname());
}

// =====================================================
// APLIKASI UTAMA
// =====================================================

class AplikasiOpname extends StatelessWidget {
  const AplikasiOpname({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DISKOMINFO OPNAME',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xfff5f7fb),
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
        ),
      ),
      home: const HalamanLogin(),
    );
  }
}

// =====================================================
// FUNGSI BANTUAN
// =====================================================

void pesan(BuildContext context, String isi) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(isi)),
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

Widget kartuMenu({
  required BuildContext context,
  required String judul,
  required String deskripsi,
  required IconData ikon,
  required Color warna,
  required VoidCallback aksi,
}) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: warna.withOpacity(0.12),
        child: Icon(ikon, color: warna, size: 27),
      ),
      title: Text(
        judul,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(deskripsi),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: aksi,
    ),
  );
}

Widget tombolUtama({
  required String teks,
  required VoidCallback? aksi,
  IconData? ikon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: aksi,
      icon: Icon(ikon ?? Icons.save),
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

      final nama = data['nama']?.toString() ?? 'Pengguna';
      final role = data['role']?.toString().toLowerCase() ?? '';

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
      } else if (role == 'petugas') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HalamanPetugas(
              nama: nama,
              email: email,
            ),
          ),
        );
      } else if (role == 'kadin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HalamanKadin(
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
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2,
                size: 85,
                color: Color(0xff1565c0),
              ),
              const SizedBox(height: 15),
              const Text(
                'DISKOMINFO OPNAME',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Sistem Informasi Stock Opname Barang',
                style: TextStyle(color: Colors.grey),
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
                        sembunyikanPassword = !sembunyikanPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),

              tombolUtama(
                teks: loading ? 'Memproses...' : 'LOGIN',
                ikon: Icons.login,
                aksi: loading ? null : login,
              ),
            ],
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Administrator Sistem Opname'),
          const SizedBox(height: 25),

          kartuMenu(
            context: context,
            judul: 'Input Barang Baru',
            deskripsi: 'Daftarkan barang dengan memindai barcode asli pada kemasan.',
            ikon: Icons.add_box,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanInputBarang(),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Data Barang dan Kode Barcode',
            deskripsi: 'Melihat, mengubah, dan menghapus data barang.',
            ikon: Icons.inventory,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanDaftarBarang(),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Persetujuan Opname',
            deskripsi: 'Menyetujui atau menolak hasil opname petugas.',
            ikon: Icons.fact_check,
            warna: Colors.orange,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanPersetujuanOpname(
                    namaAdmin: nama,
                    emailAdmin: email,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Riwayat Opname',
            deskripsi: 'Melihat seluruh riwayat pemeriksaan barang.',
            ikon: Icons.history,
            warna: Colors.purple,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanRiwayat(),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Monitoring Stok',
            deskripsi: 'Melihat kondisi stok seluruh barang.',
            ikon: Icons.analytics,
            warna: Colors.teal,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanMonitoringStok(),
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
// INPUT BARANG DAN KODE OTOMATIS
// =====================================================

class HalamanInputBarang extends StatefulWidget {
  const HalamanInputBarang({super.key});

  @override
  State<HalamanInputBarang> createState() => _HalamanInputBarangState();
}

class _HalamanInputBarangState extends State<HalamanInputBarang> {
  final kodeCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final kategoriCtrl = TextEditingController();
  final satuanCtrl = TextEditingController();
  final stokCtrl = TextEditingController();

  bool loading = false;
  bool sedangScan = false;

  // Fokus pada format barcode batang yang umum dipakai pada kemasan produk.
  final MobileScannerController scannerController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
    ],
  );

  // Membuka kamera untuk membaca barcode asli pada kemasan produk.
  Future<void> scanBarcodeProduk() async {
    if (sedangScan) return;
    setState(() => sedangScan = true);

    bool sudahTerbaca = false;

    try {
      final hasilScan = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Pindai Barcode Produk'),
            content: SizedBox(
              width: 320,
              height: 350,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) {
                    if (sudahTerbaca) return;

                    // Periksa semua hasil deteksi, bukan hanya barcode pertama.
                    for (final barcode in capture.barcodes) {
                      final nilai = barcode.rawValue?.trim();
                      if (nilai == null || nilai.isEmpty) continue;

                      sudahTerbaca = true;
                      Navigator.of(dialogContext).pop(nilai);
                      break;
                    }
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (hasilScan != null && hasilScan.isNotEmpty) {
        final ref = db.collection('barang').doc(hasilScan);
        final cek = await ref.get();

        if (!mounted) return;

        if (cek.exists) {
          pesan(context, 'Barcode $hasilScan sudah terdaftar sebagai barang.');
          return;
        }

        setState(() {
          kodeCtrl.text = hasilScan;
        });
        pesan(context, 'Barcode berhasil dibaca: $hasilScan');
      }
    } catch (e) {
      if (mounted) pesan(context, 'Gagal memindai barcode: $e');
    } finally {
      if (mounted) setState(() => sedangScan = false);
    }
  }

  Future<void> simpanBarang() async {
    final kode = kodeCtrl.text.trim();
    final nama = namaCtrl.text.trim();
    final kategori = kategoriCtrl.text.trim();
    final satuan = satuanCtrl.text.trim();
    final stok = int.tryParse(stokCtrl.text.trim());

    if (kode.isEmpty) {
      pesan(context, 'Pindai barcode produk terlebih dahulu.');
      return;
    }

    if (nama.isEmpty || kategori.isEmpty || satuan.isEmpty || stok == null || stok < 0) {
      pesan(context, 'Periksa kembali nama, kategori, satuan, dan stok awal.');
      return;
    }

    setState(() => loading = true);

    try {
      final ref = db.collection('barang').doc(kode);
      final cek = await ref.get();

      if (cek.exists) {
        pesan(context, 'Barcode ini sudah terdaftar. Gunakan data barang yang sudah ada.');
        return;
      }

      await ref.set({
        'kode_barang': kode,
        'nama_barang': nama,
        'kategori': kategori,
        'satuan': satuan,
        'stok_sistem': stok,
        'jenis_barcode': 'barcode_produk_asli',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      pesan(context, 'Barang berhasil didaftarkan menggunakan barcode asli produk.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HalamanDetailBarcode(kode: kode, nama: nama),
        ),
      );
    } catch (e) {
      if (mounted) pesan(context, 'Gagal menyimpan barang: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    kodeCtrl.dispose();
    namaCtrl.dispose();
    kategoriCtrl.dispose();
    satuanCtrl.dispose();
    stokCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Barang')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Arahkan kamera ke barcode yang tercetak pada kemasan produk. '
              'Nomor barcode akan dibaca otomatis, jadi tidak perlu diketik.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: kodeCtrl,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Nomor Barcode Produk',
              hintText: 'Belum dipindai',
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: loading || sedangScan ? null : scanBarcodeProduk,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(sedangScan ? 'Membuka kamera...' : 'Pindai Barcode Produk'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Barang',
              prefixIcon: Icon(Icons.inventory),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: kategoriCtrl,
            decoration: const InputDecoration(
              labelText: 'Kategori Barang',
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: satuanCtrl,
            decoration: const InputDecoration(
              labelText: 'Satuan',
              hintText: 'Contoh: Unit, Buah, Pcs, Botol',
              prefixIcon: Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: stokCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stok Awal',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 25),
          tombolUtama(
            teks: loading ? 'Menyimpan...' : 'Simpan Barang',
            ikon: Icons.save,
            aksi: loading || sedangScan ? null : simpanBarang,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DETAIL BARCODE PRODUK ASLI
// =====================================================

class HalamanDetailBarcode extends StatelessWidget {
  final String kode;
  final String nama;

  const HalamanDetailBarcode({
    super.key,
    required this.kode,
    required this.nama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Produk')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(22),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2, size: 55, color: Colors.blue),
                const SizedBox(height: 15),
                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Nomor barcode asli pada kemasan:'),
                const SizedBox(height: 8),
                SelectableText(
                  kode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gunakan barcode fisik pada kemasan ini saat petugas melakukan scan opname.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                tombolUtama(
                  teks: 'Selesai',
                  ikon: Icons.check,
                  aksi: () => Navigator.pop(context),
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
// DAFTAR BARANG
// =====================================================

class HalamanDaftarBarang extends StatelessWidget {
  const HalamanDaftarBarang({super.key});

  Future<void> hapusBarang(
    BuildContext context,
    String kode,
  ) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Yakin ingin menghapus barang $kode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    try {
      await db.collection('barang').doc(kode).delete();

      if (context.mounted) {
        pesan(context, 'Barang berhasil dihapus.');
      }
    } catch (e) {
      if (context.mounted) {
        pesan(context, 'Gagal menghapus: $e');
      }
    }
  }

  Future<void> editBarang(
    BuildContext context,
    String kode,
    Map<String, dynamic> data,
  ) async {
    final namaCtrl = TextEditingController(
      text: data['nama_barang']?.toString() ?? '',
    );

    final stokCtrl = TextEditingController(
      text: (data['stok_sistem'] ?? 0).toString(),
    );

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Barang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stokCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok Sistem',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasil == true) {
      final stok = int.tryParse(stokCtrl.text.trim());

      if (namaCtrl.text.trim().isEmpty || stok == null || stok < 0) {
        if (context.mounted) {
          pesan(context, 'Data tidak valid.');
        }
      } else {
        try {
          await db.collection('barang').doc(kode).update({
            'nama_barang': namaCtrl.text.trim(),
            'stok_sistem': stok,
            'updated_at': FieldValue.serverTimestamp(),
          });

          if (context.mounted) {
            pesan(context, 'Barang berhasil diperbarui.');
          }
        } catch (e) {
          if (context.mounted) {
            pesan(context, 'Gagal mengubah barang: $e');
          }
        }
      }
    }

    namaCtrl.dispose();
    stokCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Barang'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('barang').orderBy('kode_barang').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dokumen = snapshot.data!.docs;

          if (dokumen.isEmpty) {
            return const Center(
              child: Text('Belum ada data barang.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: dokumen.length,
            itemBuilder: (context, index) {
              final doc = dokumen[index];
              final data = doc.data();

              final kode = data['kode_barang']?.toString() ?? doc.id;
              final nama = data['nama_barang']?.toString() ?? '-';
              final stok = data['stok_sistem'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Kode: $kode\nStok: $stok ${data['satuan'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (pilihan) {
                      if (pilihan == 'barcode') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HalamanDetailBarcode(
                              kode: kode,
                              nama: nama,
                            ),
                          ),
                        );
                      } else if (pilihan == 'edit') {
                        editBarang(context, kode, data);
                      } else if (pilihan == 'hapus') {
                        hapusBarang(context, kode);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'barcode',
                        child: Text('Lihat Barcode'),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Barang'),
                      ),
                      PopupMenuItem(
                        value: 'hapus',
                        child: Text('Hapus Barang'),
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
// DASHBOARD PETUGAS
// =====================================================

class HalamanPetugas extends StatelessWidget {
  final String nama;
  final String email;

  const HalamanPetugas({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Petugas Stock Opname'),
          const SizedBox(height: 25),

          kartuMenu(
            context: context,
            judul: 'Scan Barcode',
            deskripsi: 'Pindai barcode barang dan masukkan stok fisik.',
            ikon: Icons.qr_code_scanner,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanScanner(
                    nama: nama,
                    email: email,
                  ),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Riwayat Opname Saya',
            deskripsi: 'Melihat hasil opname yang pernah dikirim.',
            ikon: Icons.history,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HalamanRiwayat(
                    emailPetugas: email,
                  ),
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
// SCANNER BARCODE
// =====================================================

class HalamanScanner extends StatefulWidget {
  final String nama;
  final String email;

  const HalamanScanner({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  State<HalamanScanner> createState() => _HalamanScannerState();
}

class _HalamanScannerState extends State<HalamanScanner> {
  bool sedangMemproses = false;

  // Kamera belakang dan format barcode batang produk.
  final MobileScannerController scannerController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
    ],
  );

  Future<void> prosesBarcode(String kode) async {
    if (sedangMemproses) return;

    setState(() => sedangMemproses = true);

    try {
      final hasil = await db.collection('barang').doc(kode).get();

      if (!mounted) return;

      if (!hasil.exists) {
        pesan(context, 'Barang dengan kode $kode tidak ditemukan.');
        return;
      }

      final data = hasil.data()!;
      final stokSistem = (data['stok_sistem'] as num?)?.toInt() ?? 0;

      final stokCtrl = TextEditingController();

      final stokFisik = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Input Stok Fisik'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barang: ${data['nama_barang'] ?? '-'}'),
              Text('Kode: $kode'),
              Text('Stok Sistem: $stokSistem'),
              const SizedBox(height: 15),
              TextField(
                controller: stokCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok Fisik',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final angka = int.tryParse(stokCtrl.text.trim());

                if (angka == null || angka < 0) {
                  pesan(dialogContext, 'Masukkan stok yang valid.');
                  return;
                }

                Navigator.pop(dialogContext, angka);
              },
              child: const Text('Kirim Opname'),
            ),
          ],
        ),
      );

      stokCtrl.dispose();

      if (stokFisik == null) return;

      final selisih = stokFisik - stokSistem;

      await db.collection('opname').add({
        'kode_barang': kode,
        'nama_barang': data['nama_barang'] ?? '-',
        'kategori': data['kategori'] ?? '-',
        'satuan': data['satuan'] ?? '-',
        'stok_sebelum': stokSistem,
        'stok_sistem': stokSistem,
        'stok_fisik': stokFisik,
        'selisih': selisih,
        'petugas': widget.nama,
        'email_petugas': widget.email,
        'status': 'menunggu_persetujuan',
        'approved_by': null,
        'approved_at': null,
        'catatan_admin': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        pesan(
          context,
          'Opname berhasil dikirim! Menunggu persetujuan admin.',
        );
      }
    } catch (e) {
      if (mounted) {
        pesan(context, 'Gagal memproses barcode: $e');
      }
    } finally {
      if (mounted) {
        setState(() => sedangMemproses = false);
      }
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                if (sedangMemproses) return;

                for (final barcode in capture.barcodes) {
                  final kode = barcode.rawValue?.trim();
                  if (kode == null || kode.isEmpty) continue;
                  prosesBarcode(kode);
                  break;
                }
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Arahkan kamera ke barcode barang.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (sedangMemproses)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PERSETUJUAN OPNAME OLEH ADMIN
// =====================================================

class HalamanPersetujuanOpname extends StatelessWidget {
  final String namaAdmin;
  final String emailAdmin;

  const HalamanPersetujuanOpname({
    super.key,
    required this.namaAdmin,
    required this.emailAdmin,
  });

  Future<void> setujuiOpname(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setujui Opname'),
        content: Text(
          'Setujui hasil opname barang ${data['nama_barang'] ?? '-'}? '
          'Stok master akan diperbarui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    try {
      await db.runTransaction((transaction) async {
        final opnameRef = db.collection('opname').doc(id);
        final opnameSnapshot = await transaction.get(opnameRef);

        if (!opnameSnapshot.exists) {
          throw Exception('Data opname tidak ditemukan.');
        }

        final opnameData = opnameSnapshot.data()!;

        if (opnameData['status'] != 'menunggu_persetujuan') {
          throw Exception('Data sudah diproses sebelumnya.');
        }

        final kode = opnameData['kode_barang']?.toString() ?? '';

        if (kode.isEmpty) {
          throw Exception('Kode barang tidak tersedia.');
        }

        final barangRef = db.collection('barang').doc(kode);
        final barangSnapshot = await transaction.get(barangRef);

        if (!barangSnapshot.exists) {
          throw Exception('Data barang tidak ditemukan.');
        }

        final stokFisik =
            (opnameData['stok_fisik'] as num?)?.toInt();

        if (stokFisik == null || stokFisik < 0) {
          throw Exception('Stok fisik tidak valid.');
        }

        final stokSaatPersetujuan =
            (barangSnapshot.data()?['stok_sistem'] as num?)?.toInt() ?? 0;

        transaction.update(barangRef, {
          'stok_sistem': stokFisik,
          'updated_at': FieldValue.serverTimestamp(),
          'last_approved_opname': id,
        });

        transaction.update(opnameRef, {
          'status': 'disetujui',
          'stok_sebelum_persetujuan': stokSaatPersetujuan,
          'selisih_persetujuan': stokFisik - stokSaatPersetujuan,
          'approved_by': namaAdmin,
          'approved_by_email': emailAdmin,
          'approved_at': FieldValue.serverTimestamp(),
          'catatan_admin': 'Opname disetujui.',
        });
      });

      if (context.mounted) {
        pesan(context, 'Opname berhasil disetujui dan stok diperbarui.');
      }
    } catch (e) {
      if (context.mounted) {
        pesan(context, 'Gagal menyetujui opname: $e');
      }
    }
  }

  Future<void> tolakOpname(
    BuildContext context,
    String id,
  ) async {
    final catatanCtrl = TextEditingController();

    final catatan = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Opname'),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            hintText: 'Masukkan alasan penolakan...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (catatanCtrl.text.trim().isEmpty) {
                pesan(dialogContext, 'Alasan penolakan harus diisi.');
                return;
              }

              Navigator.pop(dialogContext, catatanCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Opname'),
          ),
        ],
      ),
    );

    catatanCtrl.dispose();

    if (catatan == null || catatan.isEmpty) return;

    try {
      await db.runTransaction((transaction) async {
        final ref = db.collection('opname').doc(id);
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Data opname tidak ditemukan.');
        }

        if (snapshot.data()?['status'] != 'menunggu_persetujuan') {
          throw Exception('Data sudah diproses sebelumnya.');
        }

        transaction.update(ref, {
          'status': 'ditolak',
          'approved_by': namaAdmin,
          'approved_by_email': emailAdmin,
          'approved_at': FieldValue.serverTimestamp(),
          'catatan_admin': catatan,
        });
      });

      if (context.mounted) {
        pesan(context, 'Opname berhasil ditolak.');
      }
    } catch (e) {
      if (context.mounted) {
        pesan(context, 'Gagal menolak opname: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Opname'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('opname')
            .where('status', isEqualTo: 'menunggu_persetujuan')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dokumen = snapshot.data!.docs;

          if (dokumen.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 65,
                    color: Colors.green,
                  ),
                  SizedBox(height: 12),
                  Text('Tidak ada opname yang menunggu persetujuan.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: dokumen.length,
            itemBuilder: (context, index) {
              final doc = dokumen[index];
              final data = doc.data();

              final stokSistem =
                  (data['stok_sistem'] as num?)?.toInt() ?? 0;
              final stokFisik =
                  (data['stok_fisik'] as num?)?.toInt() ?? 0;
              final selisih = stokFisik - stokSistem;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama_barang']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text('Kode: ${data['kode_barang'] ?? '-'}'),
                      Text('Petugas: ${data['petugas'] ?? '-'}'),
                      Text('Stok Sistem: $stokSistem'),
                      Text('Stok Fisik: $stokFisik'),
                      Text(
                        'Selisih: $selisih',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selisih == 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                tolakOpname(context, doc.id);
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Tolak'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setujuiOpname(context, doc.id, data);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
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
// RIWAYAT OPNAME
// =====================================================

class HalamanRiwayat extends StatelessWidget {
  final String? emailPetugas;

  const HalamanRiwayat({
    super.key,
    this.emailPetugas,
  });

  Color warnaStatus(String status) {
    switch (status) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String namaStatus(String status) {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'menunggu_persetujuan':
        return 'Menunggu Persetujuan';
      default:
        return status.isEmpty ? 'Belum ada status' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = db.collection('opname');

    if (emailPetugas != null) {
      query = query.where(
        'email_petugas',
        isEqualTo: emailPetugas,
      );
    }

    query = query.orderBy(
      'created_at',
      descending: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          emailPetugas == null
              ? 'Seluruh Riwayat Opname'
              : 'Riwayat Opname Saya',
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dokumen = snapshot.data!.docs;

          if (dokumen.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat opname.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: dokumen.length,
            itemBuilder: (context, index) {
              final data = dokumen[index].data();

              final status =
                  data['status']?.toString() ?? '';

              final stokSistem = data['stok_sistem'] ?? 0;
              final stokFisik = data['stok_fisik'] ?? 0;
              final selisih = data['selisih'] ?? 0;

              final waktu = data['created_at'];

              String tanggal = '-';

              if (waktu is Timestamp) {
                tanggal = waktu.toDate().toLocal().toString();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 13),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama_barang']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text('Kode: ${data['kode_barang'] ?? '-'}'),
                      Text('Petugas: ${data['petugas'] ?? '-'}'),
                      Text('Tanggal: $tanggal'),
                      Text('Stok Sistem: $stokSistem'),
                      Text('Stok Fisik: $stokFisik'),
                      Text('Selisih: $selisih'),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: warnaStatus(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          namaStatus(status),
                          style: TextStyle(
                            color: warnaStatus(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (data['approved_by'] != null) ...[
                        const SizedBox(height: 10),
                        Text('Diproses oleh: ${data['approved_by']}'),
                      ],

                      if (data['catatan_admin'] != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Catatan: ${data['catatan_admin']}',
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
// DASHBOARD KADIN
// =====================================================

class HalamanKadin extends StatelessWidget {
  final String nama;
  final String email;

  const HalamanKadin({
    super.key,
    required this.nama,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kadin'),
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Monitoring Stock Opname'),
          const SizedBox(height: 25),

          kartuMenu(
            context: context,
            judul: 'Monitoring Stok Barang',
            deskripsi: 'Melihat stok sistem seluruh barang.',
            ikon: Icons.analytics,
            warna: Colors.blue,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanMonitoringStok(),
                ),
              );
            },
          ),

          kartuMenu(
            context: context,
            judul: 'Riwayat Opname',
            deskripsi: 'Melihat seluruh hasil opname dan statusnya.',
            ikon: Icons.history,
            warna: Colors.green,
            aksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanRiwayat(),
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
// MONITORING STOK
// =====================================================

class HalamanMonitoringStok extends StatelessWidget {
  const HalamanMonitoringStok({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Stok Barang'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('barang').orderBy('kode_barang').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dokumen = snapshot.data!.docs;

          if (dokumen.isEmpty) {
            return const Center(
              child: Text('Belum ada data barang.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: dokumen.length,
            itemBuilder: (context, index) {
              final data = dokumen[index].data();

              final stok =
                  (data['stok_sistem'] as num?)?.toInt() ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.12),
                    child: const Icon(
                      Icons.inventory,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    data['nama_barang']?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Kode: ${data['kode_barang'] ?? '-'}\n'
                    'Kategori: ${data['kategori'] ?? '-'}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$stok',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        data['satuan']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11),
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
