import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:first_flutter/models/product.dart';
import 'package:first_flutter/services/api_service.dart';
import 'package:first_flutter/repositories/product_repository.dart';
import 'package:first_flutter/viewmodels/product_viewmodel.dart';
import 'package:first_flutter/views/login_screen.dart';
import 'package:first_flutter/views/home_page.dart';
import 'package:first_flutter/views/creation_page.dart';
import 'package:first_flutter/views/listed_page.dart';
import 'package:first_flutter/main.dart';

class MockApiService extends Mock implements ApiService {}

class MockProductRepository extends Mock implements ProductRepository {}

class FakeProduct extends Fake implements Product {}

void main() {
  setUpAll(() => registerFallbackValue(FakeProduct()));

  // ---- REPOSITORY ----
  group('ProductRepository', () {
    late MockApiService api;
    late ProductRepository repo;

    setUp(() {
      api = MockApiService();
      repo = ProductRepository(apiService: api);
    });

    test('login() desa token i userData', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {
          'access_token': 'tok123',
          'user': {'id': 'u1', 'email': 'a@b.com'},
        },
      );

      await repo.login('a@b.com', 'pass');
      expect(repo.accessToken, 'tok123');
      expect(repo.userData!['email'], 'a@b.com');
    });

    test('getProducts() retorna productes', () async {
      when(() => api.getProducts()).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': 'P1',
              'description': 'D',
              'price': 10.0,
            },
          ]),
          200,
        ),
      );

      final products = await repo.getProducts();
      expect(products.length, 1);
      expect(products[0].name, 'P1');
    });

    test('getProducts() llença excepció amb error 500', () async {
      when(
        () => api.getProducts(),
      ).thenAnswer((_) async => http.Response('Error', 500));
      expect(() => repo.getProducts(), throwsA(isA<Exception>()));
    });

    test('createProduct() falla sense autenticació', () {
      final p = Product(name: 'T', description: 'D', price: 5.0);
      expect(() => repo.createProduct(p), throwsA(isA<Exception>()));
    });

    test('createProduct() success amb auth', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {
          'access_token': 'tok',
          'user': {'id': 'u1'},
        },
      );
      await repo.login('e', 'p');
      
      when(() => api.createProduct(any(), any())).thenAnswer((_) async {});
      
      final p = Product(name: 'T', description: 'D', price: 5.0);
      await repo.createProduct(p);
      verify(() => api.createProduct('tok', any())).called(1);
    });

    test('getUserProducts() success', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {
          'access_token': 'tok',
          'user': {'id': 'u1'},
        },
      );
      await repo.login('e', 'p');

      when(() => api.getUserProducts(any(), any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': 'UP',
              'description': 'UD',
              'price': 5.0,
            },
          ]),
          200,
        ),
      );

      final up = await repo.getUserProducts();
      expect(up.length, 1);
      expect(up[0].name, 'UP');
    });

    test('getUserProducts() falla sense dades d\'usuari', () async {
      expect(() => repo.getUserProducts(), throwsA(isA<Exception>()));
    });

    test('getUserProducts() falla amb error 500', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {
          'access_token': 'tok',
          'user': {'id': 'u1'},
        },
      );
      await repo.login('e', 'p');
      when(() => api.getUserProducts(any(), any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );
      expect(() => repo.getUserProducts(), throwsA(isA<Exception>()));
    });

    test('logout() neteja dades', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {
          'access_token': 'tok',
          'user': {'id': 'u1', 'email': 'e@e.com'},
        },
      );
      await repo.login('e@e.com', 'p');
      repo.logout();
      expect(repo.accessToken, isNull);
      expect(repo.userData, isNull);
    });
  });

  // ---- VIEWMODEL ----
  group('ProductViewModel', () {
    late MockProductRepository mockRepo;
    late ProductViewModel vm;

    setUp(() {
      mockRepo = MockProductRepository();
      vm = ProductViewModel(productRepository: mockRepo);
    });

    test('login() exitós carrega productes', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer((_) async => {});
      when(() => mockRepo.userData).thenReturn({'id': 'u1'});
      when(() => mockRepo.getProducts()).thenAnswer(
        (_) async => [
          Product(id: 1, name: 'P1', description: 'D', price: 10.0),
        ],
      );

      final ok = await vm.login('e@e.com', 'pass');
      expect(ok, isTrue);
      expect(vm.products.length, 1);
      expect(vm.isLoading, isFalse);
    });

    test('login() fallit mostra error', () async {
      when(
        () => mockRepo.login(any(), any()),
      ).thenThrow(Exception('bad credentials'));

      final ok = await vm.login('e@e.com', 'wrong');
      expect(ok, isFalse);
      expect(vm.errorMessage, contains('Error durant el login'));
    });

    test('fetchProducts() error case', () async {
      when(() => mockRepo.getProducts()).thenThrow(Exception('Fetch error'));
      await vm.fetchProducts();
      expect(vm.errorMessage, contains('Error recuperant productes'));
    });

    test('fetchUserProducts() success', () async {
      when(() => mockRepo.getUserProducts()).thenAnswer((_) async => [
        Product(id: 1, name: 'User P', description: 'D', price: 1.0),
      ]);
      await vm.fetchUserProducts();
      expect(vm.userProducts.length, 1);
      expect(vm.userProducts[0].name, 'User P');
    });

    test('fetchUserProducts() error', () async {
      when(() => mockRepo.getUserProducts()).thenThrow(Exception('User fetch error'));
      await vm.fetchUserProducts();
      expect(vm.errorMessage, contains('Error recuperant productes de l\'usuari'));
    });

    test('addProduct() crea i refresca', () async {
      when(() => mockRepo.userData).thenReturn({'id': 'u1'});
      when(() => mockRepo.createProduct(any())).thenAnswer((_) async {});
      when(() => mockRepo.getProducts()).thenAnswer((_) async => []);

      final ok = await vm.addProduct('Nom', 'Desc', 25.0);
      expect(ok, isTrue);
      verify(() => mockRepo.createProduct(any())).called(1);
    });

    test('addProduct() error', () async {
      when(() => mockRepo.userData).thenReturn({'id': 'u1'});
      when(() => mockRepo.createProduct(any())).thenThrow(Exception('Create error'));

      final ok = await vm.addProduct('Nom', 'Desc', 25.0);
      expect(ok, isFalse);
      expect(vm.errorMessage, contains('Error creant producte'));
    });

    test('logout() neteja tot', () async {
      when(() => mockRepo.getProducts()).thenAnswer(
        (_) async => [Product(id: 1, name: 'X', description: 'D', price: 5.0)],
      );
      await vm.fetchProducts();
      when(() => mockRepo.logout()).thenReturn(null);

      vm.logout();
      expect(vm.products, isEmpty);
      expect(vm.userProducts, isEmpty);
    });
  });

  // ---- WIDGETS ----
  group('Widgets', () {
    testWidgets('LoginScreen mostra camps i permet login', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn(null);
      when(() => mockRepo.login(any(), any())).thenAnswer((_) async => {});
      when(() => mockRepo.getProducts()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: LoginScreen(),
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      
      await tester.enterText(find.byType(TextField).first, 'e@e.com');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.login('e@e.com', 'pass')).called(1);
    });

    testWidgets('HomePage mostra dades usuari i permet logout', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn({'id': 'u1', 'email': 'e@e.com'});
      when(() => mockRepo.logout()).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const HomePage(userData: {'id': 'u1', 'email': 'e@e.com'}),
          ),
        ),
      );

      expect(find.text('Email: e@e.com'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.logout));
      verify(() => mockRepo.logout()).called(1);
    });

    testWidgets('MyHomePage permet navegar a Listed', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn({'id': 'u1', 'email': 'e@e.com'});
      when(() => mockRepo.getUserProducts()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: MyHomePage(),
          ),
        ),
      );

      // Verify we are on Home
      expect(find.text('Email: e@e.com'), findsOneWidget);

      // Tap Listed in NavigationBar
      await tester.tap(find.text('Listed'));
      await tester.pumpAndSettle();

      expect(find.byType(ListedPage), findsOneWidget);
    });

    testWidgets('CreationPage permet crear producte', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn({'id': 'u1'});
      when(() => mockRepo.createProduct(any())).thenAnswer((_) async {});
      when(() => mockRepo.getProducts()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const CreationPage(),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, 'Nom del producte'), 'Prod');
      await tester.enterText(find.widgetWithText(TextField, 'Descripció'), 'Desc');
      await tester.enterText(find.widgetWithText(TextField, 'Preu'), '10.5');
      
      await tester.tap(find.text('Crear Producte'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.createProduct(any())).called(1);
    });

    testWidgets('ListedPage mostra llista de productes', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      final products = [
        Product(id: 1, name: 'P1', description: 'D1', price: 10.0),
      ];

      when(() => mockRepo.getUserProducts()).thenAnswer((_) async => products);
      when(() => mockRepo.logout()).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const ListedPage(),
          ),
        ),
      );

      // Wait for the async fetch to complete and UI to update
      await tester.pump(); // Triggers initState
      await tester.pumpAndSettle(); // Waits for the postFrameCallback and subsequent updates

      expect(find.text('P1'), findsOneWidget);
      expect(find.text('D1'), findsOneWidget);
      
      // Test logout
      await tester.tap(find.byIcon(Icons.logout));
      verify(() => mockRepo.logout()).called(1);
    });

    testWidgets('ListedPage mostra error', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.getUserProducts()).thenThrow(Exception('Error Fetch'));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const ListedPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Error Fetch'), findsOneWidget);
    });

    testWidgets('BigCard mostra nom del producte', (tester) async {
      final p = Product(id: 1, name: 'Test', description: 'D', price: 9.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BigCard(pair: p)),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('LoginScreen mostra error quan hi ha errorMessage', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      // Simulem un error ja existent al VM
      when(() => mockRepo.userData).thenReturn(null);
      // Fem que el login falli per posar un error
      when(() => mockRepo.login(any(), any())).thenThrow(Exception('Login incorrecte'));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: LoginScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'e@e.com');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text('Login'));
      await tester.pump(); // No pumpAndSettle perquè volem veure l'estat intermig o l'error

      expect(find.textContaining('Login incorrecte'), findsOneWidget);
    });

    testWidgets('ListedPage mostra "No products found" si està buit', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.getUserProducts()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const ListedPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('MyHomePage mostra NavigationBar en pantalles petites si està loguejat', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn({'id': 'u1', 'email': 'a@b.com'});

      // Configurem una pantalla petita (ex: 400x800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: MyHomePage(),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Tornem a la mida normal per no afectar altres tests si cal
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('CreationPage mostra errors de validació', (tester) async {
      final mockRepo = MockProductRepository();
      final vm = ProductViewModel(productRepository: mockRepo);
      
      when(() => mockRepo.userData).thenReturn({'id': 'u1'});

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProductViewModel>(
            create: (_) => vm,
            child: const CreationPage(),
          ),
        ),
      );

      // Intentem enviar sense omplir res
      await tester.tap(find.text('Crear Producte'));
      await tester.pump();

      expect(find.text('Si us plau, introdueix un nom'), findsOneWidget);
      expect(find.text('Si us plau, introdueix una descripció'), findsOneWidget);
      expect(find.text('Si us plau, introdueix un preu'), findsOneWidget);
    });
  });

  group('ProductViewModel Additions', () {
    late MockProductRepository mockRepo;
    late ProductViewModel vm;

    setUp(() {
      mockRepo = MockProductRepository();
      vm = ProductViewModel(productRepository: mockRepo);
    });

    test('fetchProducts() success individual test', () async {
      final products = [Product(id: 1, name: 'P1', description: 'D', price: 10.0)];
      when(() => mockRepo.getProducts()).thenAnswer((_) async => products);

      await vm.fetchProducts();
      
      expect(vm.products, products);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('isLoading canvia durant fetchProducts', () async {
      // Per testar el canvi de isLoading, necessitem que la resposta triga una mica
      // o capturar l'estat intermig.
      when(() => mockRepo.getProducts()).thenAnswer((_) async {
        return [Product(id: 1, name: 'P', description: 'D', price: 1.0)];
      });

      final future = vm.fetchProducts();
      expect(vm.isLoading, isTrue); // Ha de ser true just després de la crida
      
      await future;
      expect(vm.isLoading, isFalse);
    });
  });
}
