import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const HomePage({super.key, required this.userData});
  @override
  Widget build(BuildContext context) {
    final email = userData?['email'] ?? 'Desconegut';
    final id = userData?['id'] ?? '---';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ProductViewModel>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Usuari Autenticat!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Email: $email", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("UUID: $id", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
