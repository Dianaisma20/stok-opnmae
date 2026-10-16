import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// Import file konfigurasi firebase kamu di sini jika ada:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Aktifkan jika menggunakan flutterfire configure
  );
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HalamanLogin(),
    ),
  );
}

// ========================================================
// 🔐 INTERFACE 1: HALAMAN LOGIN (FIRESTORE)
// ========================================================

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _sedangMemuat = false;

  Future<void> aksiLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email & Password wajib diisi!")),
      );
      return;
    }

    setState(() => _sedangMemuat = true);

    try {
      // Mengambil data user langsung dari koleksi Firestore "users"
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final dataUser = querySnapshot.docs.first.data();
        final String roleUser = dataUser['role'] ?? '';
        final String namaUser = dataUser['nama'] ?? 'Pengguna';

        if (!mounted) return;

        if (roleUser == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardAdmin(nama: namaUser),
            ),
          );
        } else if (roleUser == 'petugas') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardPetugas(nama: namaUser),
            ),
          );
        } else if (roleUser == 'kadin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardKadin(nama: namaUser),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role pengguna tidak dikenali!")),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau password salah!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal terhubung ke Firestore: $e")),
      );
    } finally {
      if (mounted) setState(() => _sedangMemuat = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.domain, size: 80, color: Colors.blue),
              const SizedBox(height: 10),
              const Text(
                "DISKOMINFO OPNAME",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Sistem Validasi Stok Barang Aset Daerah",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Alamat Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Kata Sandi",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sedangMemuat ? null : aksiLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _sedangMemuat
                      ? const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "MASUK APLIKASI",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 🛡️ INTERFACE 2: DASHBOARD ADMIN
// ========================================================

class HalamanDashboardAdmin extends StatelessWidget {
  final String nama;
  const HalamanDashboardAdmin({super.key, required this.nama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HalamanLogin()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selamat Datang, $nama",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Hak Akses: Pengelola Master Data"),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  Card(
                    color: Colors.amber.shade100,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Menu Input Barang Baru")),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_box, size: 50, color: Colors.amber),
                          SizedBox(height: 10),
                          Text("Input Barang Baru", textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.amber.shade100,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Menu Kelola Stok Awal")),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: 50, color: Colors.amber),
                          SizedBox(height: 10),
                          Text("Kelola Stok Awal", textAlign: TextAlign.center),
                        ],
                      ),
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
}

// ========================================================
// 📦 INTERFACE 3: DASHBOARD PETUGAS GUDANG (FIRESTORE)
// ========================================================

class HalamanDashboardPetugas extends StatefulWidget {
  final String nama;
  const HalamanDashboardPetugas({super.key, required this.nama});

  @override
  State<HalamanDashboardPetugas> createState() =>
      _HalamanDashboardPetugasState();
}

class _HalamanDashboardPetugasState extends State<HalamanDashboardPetugas> {
  final MobileScannerController kameraController = MobileScannerController();
  bool _sedangMemproses = false;

  Future<void> prosesCariBarang(String kode) async {
    if (_sedangMemproses) return;

    setState(() => _sedangMemproses = true);
    await kameraController.stop();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('barang')
          .doc(kode)
          .get();

      if (docSnapshot.exists) {
        final dataBarang = docSnapshot.data()!;
        dataBarang['kode_barang'] = kode;

        if (!mounted) return;
        bukaDialogInputFisik(dataBarang);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Barang dengan kode $kode tidak terdaftar!")),
        );
        await kameraController.start();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data dari Firestore: $e")),
      );
      await kameraController.start();
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  void bukaDialogInputFisik(Map<String, dynamic> barang) {
    final TextEditingController inputFisikController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(barang['nama_barang'] ?? "Barang"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kode Barang: ${barang['kode_barang']}"),
              const SizedBox(height: 8),
              Text("Stok Buku Sistem: ${barang['stok_sistem']}"),
              const SizedBox(height: 15),
              TextField(
                controller: inputFisikController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Jumlah Nyata di Lapangan",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                kameraController.start();
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = inputFisikController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jumlah fisik wajib diisi!")),
                  );
                  return;
                }

                final int? stokFisik = int.tryParse(text);
                if (stokFisik == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jumlah stok harus berupa angka!")),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                simpanKeDatabase(
                  barang['kode_barang'],
                  int.parse(barang['stok_sistem'].toString()),
                  stokFisik,
                );
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> simpanKeDatabase(String kode, int stokSis, int stokFis) async {
    try {
      await FirebaseFirestore.instance.collection('opname').add({
        'kode_barang': kode,
        'stok_sistem': stokSis,
        'stok_fisik': stokFis,
        'petugas': widget.nama,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hasil opname berhasil disimpan ke Firestore!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data opname: $e")),
      );
    } finally {
      await kameraController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Petugas Gudang (Scanner)"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              kameraController.stop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HalamanLogin()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: kameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? kode = barcodes.first.rawValue;
                if (kode != null && kode.isNotEmpty) {
                  prosesCariBarang(kode);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Petugas: ${widget.nama}\nArahkan kamera ke Barcode / QR Code",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_sedangMemproses)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    kameraController.dispose();
    super.dispose();
  }
}

// ========================================================
// 💼 INTERFACE 4: DASHBOARD KEPALA DINAS
// ========================================================

class HalamanDashboardKadin extends StatelessWidget {
  final String nama;
  const HalamanDashboardKadin({super.key, required this.nama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Kadin"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HalamanLogin()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Yth. $nama",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 5),
            const Text("Jabatan: Kepala Dinas Kominfo"),
            const SizedBox(height: 30),
            const Card(
              color: Colors.purple,
              child: ListTile(
                leading: Icon(Icons.assessment, color: Colors.white, size: 40),
                title: Text(
                  "Status Keberadaan Barang Gudang",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Semua data opname terekam realtime di Firestore.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.purple),
                title: const Text("Monitoring Stok Barang"),
                subtitle: const Text("Melihat hasil pemeriksaan stok barang."),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Menu monitoring stok")),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.purple),
                title: const Text("Riwayat Opname"),
                subtitle: const Text("Melihat riwayat pemeriksaan barang."),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Menu riwayat opname")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}