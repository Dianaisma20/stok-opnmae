import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HalamanLogin(),
    ),
  );
}

// ========================================================
// 🌐 KONFIGURASI API
// ========================================================

// IP laptop yang menjalankan server Node.js.
// Pastikan IP ini sama dengan IP laptop/server kamu.
const String URL_BASE_API = "localhost:8000";

// ========================================================
// 🔐 INTERFACE 1: HALAMAN LOGIN
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

  // ======================================================
  // PROSES LOGIN
  // ======================================================

  Future<void> aksiLogin() async {
    if (_emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email & Password wajib diisi!"),
        ),
      );
      return;
    }

    setState(() {
      _sedangMemuat = true;
    });

    final url = Uri.parse(
      'http://$URL_BASE_API/api/login',
    );

    try {
      final respon = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": _emailCtrl.text.trim(),
          "password": _passCtrl.text,
        }),
      );

      final hasil = jsonDecode(respon.body);

      if (respon.statusCode == 200) {
        final dataUser = hasil['data'];

        final String roleUser = dataUser['role'];
        final String namaUser = dataUser['nama'];

        // =================================================
        // NAVIGASI BERDASARKAN ROLE
        // =================================================

        if (!mounted) return;

        if (roleUser == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardAdmin(
                nama: namaUser,
              ),
            ),
          );
        } else if (roleUser == 'petugas') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardPetugas(
                nama: namaUser,
              ),
            ),
          );
        } else if (roleUser == 'kadin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HalamanDashboardKadin(
                nama: namaUser,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Role pengguna tidak dikenali!"),
            ),
          );
        }
      } else {
        final String pesan =
            hasil['message'] ?? "Login gagal! Periksa kembali akun Anda.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal terhubung ke server Backend Node.js!",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ======================================================
  // TAMPILAN LOGIN
  // ======================================================

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
              const Icon(
                Icons.domain,
                size: 80,
                color: Colors.blue,
              ),

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
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // EMAIL
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

              // PASSWORD
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

              // TOMBOL LOGIN
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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

  const HalamanDashboardAdmin({
    super.key,
    required this.nama,
  });

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
                MaterialPageRoute(
                  builder: (_) => const HalamanLogin(),
                ),
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Hak Akses: Pengelola Master Data",
            ),

            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  // INPUT BARANG
                  Card(
                    color: Colors.amber.shade100,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Menu Input Barang Baru",
                            ),
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_box,
                            size: 50,
                            color: Colors.amber,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Input Barang Baru",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // KELOLA STOK
                  Card(
                    color: Colors.amber.shade100,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Menu Kelola Stok Awal",
                            ),
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 50,
                            color: Colors.amber,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Kelola Stok Awal",
                            textAlign: TextAlign.center,
                          ),
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
// 📦 INTERFACE 3: DASHBOARD PETUGAS GUDANG
// ========================================================

class HalamanDashboardPetugas extends StatefulWidget {
  final String nama;

  const HalamanDashboardPetugas({
    super.key,
    required this.nama,
  });

  @override
  State<HalamanDashboardPetugas> createState() =>
      _HalamanDashboardPetugasState();
}

class _HalamanDashboardPetugasState
    extends State<HalamanDashboardPetugas> {

  final MobileScannerController kameraController =
      MobileScannerController();

  bool _sedangMemproses = false;

  // ======================================================
  // MENCARI BARANG BERDASARKAN BARCODE / QR
  // ======================================================

  Future<void> prosesCariBarang(String kode) async {
    if (_sedangMemproses) return;

    setState(() {
      _sedangMemproses = true;
    });

    await kameraController.stop();

    final url = Uri.parse(
      'http://$URL_BASE_API/api/barang/cari?kode=$kode',
    );

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        final hasil = jsonDecode(respon.body);

        final dataBarang = hasil['data'];

        if (!mounted) return;

        bukaDialogInputFisik(dataBarang);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Barang dengan kode $kode tidak terdaftar!",
            ),
          ),
        );

        await kameraController.start();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Koneksi bermasalah ke server Node.js.",
          ),
        ),
      );

      await kameraController.start();
    } finally {
      if (mounted) {
        setState(() {
          _sedangMemproses = false;
        });
      }
    }
  }

  // ======================================================
  // DIALOG INPUT STOK FISIK
  // ======================================================

  void bukaDialogInputFisik(
    Map<String, dynamic> barang,
  ) {
    final TextEditingController inputFisikController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            barang['nama_barang'] ?? "Barang",
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kode Barang: ${barang['kode_barang']}",
              ),

              const SizedBox(height: 8),

              Text(
                "Stok Buku Sistem: ${barang['stok_sistem']}",
              ),

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
            // BATAL
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                kameraController.start();
              },
              child: const Text("Batal"),
            ),

            // SIMPAN
            ElevatedButton(
              onPressed: () {
                if (inputFisikController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Jumlah fisik wajib diisi!",
                      ),
                    ),
                  );
                  return;
                }

                final int? stokFisik = int.tryParse(
                  inputFisikController.text.trim(),
                );

                if (stokFisik == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Jumlah stok harus berupa angka!",
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                simpanKeDatabase(
                  barang['kode_barang'],
                  int.parse(
                    barang['stok_sistem'].toString(),
                  ),
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

  // ======================================================
  // SIMPAN HASIL OPNAME
  // ======================================================

  Future<void> simpanKeDatabase(
    String kode,
    int stokSis,
    int stokFis,
  ) async {
    final url = Uri.parse(
      'http://$URL_BASE_API/api/opname/simpan',
    );

    try {
      final respon = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "kode_barang": kode,
          "stok_sistem": stokSis,
          "stok_fisik": stokFis,
          "petugas": widget.nama,
        }),
      );

      if (respon.statusCode == 200 ||
          respon.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Hasil opname berhasil disimpan ke MySQL!",
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Data opname gagal disimpan.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal mengirim data ke server.",
          ),
        ),
      );
    } finally {
      await kameraController.start();
    }
  }

  // ======================================================
  // TAMPILAN DASHBOARD PETUGAS
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Petugas Gudang (Scanner)",
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              kameraController.stop();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanLogin(),
                ),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          // =================================================
          // KAMERA BARCODE / QR CODE
          // =================================================

          MobileScanner(
            controller: kameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                final String? kode =
                    barcodes.first.rawValue;

                if (kode != null && kode.isNotEmpty) {
                  prosesCariBarang(kode);
                }
              }
            },
          ),

          // =================================================
          // KOTAK SCANNER
          // =================================================

          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          // =================================================
          // INFORMASI PETUGAS
          // =================================================

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

          // =================================================
          // LOADING
          // =================================================

          if (_sedangMemproses)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
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

  const HalamanDashboardKadin({
    super.key,
    required this.nama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monitoring Kadin",
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanLogin(),
                ),
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
            // NAMA KADIN
            Text(
              "Yth. ${nama}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Jabatan: Kepala Dinas Kominfo",
            ),

            const SizedBox(height: 30),

            // STATUS BARANG
            Card(
              color: Colors.purple,
              child: const ListTile(
                leading: Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 40,
                ),
                title: Text(
                  "Status Keberadaan Barang Gudang",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Semua data opname terekam realtime di database Node.js.",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // MENU MONITORING
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.inventory_2,
                  color: Colors.purple,
                ),
                title: const Text(
                  "Monitoring Stok Barang",
                ),
                subtitle: const Text(
                  "Melihat hasil pemeriksaan stok barang.",
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Menu monitoring stok",
                      ),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.purple,
                ),
                title: const Text(
                  "Riwayat Opname",
                ),
                subtitle: const Text(
                  "Melihat riwayat pemeriksaan barang.",
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Menu riwayat opname",
                      ),
                    ),
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