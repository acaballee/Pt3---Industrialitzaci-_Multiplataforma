import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';

class ListedPage extends StatefulWidget {
  const ListedPage({super.key});

  @override
  State<ListedPage> createState() => _ListedPageState();
}

class _ListedPageState extends State<ListedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductViewModel>(context, listen: false).fetchUserProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ProductViewModel>().logout();
            },
          ),
        ],
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (viewModel.userProducts.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return ListView.builder(
            itemCount: viewModel.userProducts.length,
            itemBuilder: (context, index) {
              final product = viewModel.userProducts[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('${product.price} €'),
              );
            },
          );
        },
      ),
    );
  }
}
