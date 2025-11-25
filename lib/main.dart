import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kantin Poliwangi',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final CollectionReference _menuRef =
  FirebaseFirestore.instance.collection('menus');
  final CollectionReference _orderRef =
  FirebaseFirestore.instance.collection('orders');

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(price);
  }

  void _showOrderDialog(String menuName, int price) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pesan $menuName'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Pemesan',
            hintText: 'Contoh: Budi (TI - 2 A)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final customerName = nameController.text.trim();
              if (customerName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong')),
                );
                return;
              }

              try {
                await _orderRef.add({
                  'menu_item': menuName,
                  'price': price,
                  'customer_name': customerName,
                  'status': 'Menunggu',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesanan berhasil dikirim!')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengirim pesanan: $e')),
                );
              }
            },
            child: const Text('Pesan Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E - Canteen Poliwangi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _menuRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan koneksi.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Menu belum tersedia.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] as String?) ?? 'Tidak Diketahui';
              final priceNum = (data['price'] as num?)?.toInt() ?? 0;
              final isAvailable = (data['isAvailable'] as bool?) ?? false;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(formatRupiah(priceNum)),
                  trailing: ElevatedButton(
                    onPressed: isAvailable ? () => _showOrderDialog(name, priceNum) : null,
                    child: Text(isAvailable ? 'Pesan' : 'Habis'),
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
