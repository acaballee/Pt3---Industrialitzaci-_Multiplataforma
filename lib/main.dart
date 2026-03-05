import 'package:first_flutter/views/home_page.dart';
import 'package:first_flutter/views/listed_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
import 'repositories/product_repository.dart';
import 'services/api_service.dart';
import 'viewmodels/product_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/creation_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (context) => ApiService()),
        Provider<ProductRepository>(
          create: (context) => ProductRepository(apiService: context.read()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductViewModel(productRepository: context.read()),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProductViewModel>(context);
    final isLogin = viewModel.currentUser == null;

    final navCount = isLogin ? 1 : 3;
    final safeIndex = selectedIndex >= navCount ? 0 : selectedIndex;

    Widget page;
    switch (safeIndex) {
      case 0:
        page = isLogin
            ? LoginScreen()
            : HomePage(userData: viewModel.currentUser);
      case 1:
        page = ListedPage();
      case 2:
        page = CreationPage();
      default:
        throw UnimplementedError('no widget for $safeIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          return Scaffold(
            body: Row(children: [MainArea(page: page)]),
            bottomNavigationBar: NavigationBar(
              destinations: [
                NavigationDestination(
                  icon: Icon(isLogin ? Icons.login : Icons.home),
                  label: isLogin ? 'Login' : 'Home',
                ),
                if (!isLogin)
                  const NavigationDestination(
                    icon: Icon(Icons.list_alt),
                    label: 'Listed',
                  ),
                if (!isLogin)
                  const NavigationDestination(
                    icon: Icon(Icons.add),
                    label: 'Creation',
                  ),
              ],
              selectedIndex: safeIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 800,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(isLogin ? Icons.login : Icons.home),
                        label: Text(isLogin ? 'Login' : 'Home'),
                      ),
                      if (!isLogin)
                        const NavigationRailDestination(
                          icon: Icon(Icons.list_alt),
                          label: Text('Listed'),
                        ),
                      if (!isLogin)
                        const NavigationRailDestination(
                          icon: Icon(Icons.add),
                          label: Text('Creation'),
                        ),
                    ],
                    selectedIndex: safeIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                MainArea(page: page),
              ],
            ),
          );
        }
      },
    );
  }
}

class MainArea extends StatelessWidget {
  const MainArea({super.key, required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: page,
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final Product pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      shadows: [
        Shadow(color: theme.colorScheme.primaryContainer, blurRadius: 10),
      ],
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.name, style: style),
      ),
    );
  }
}
