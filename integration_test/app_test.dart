import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:first_flutter/main.dart';
import 'package:first_flutter/services/api_service.dart';
import 'package:first_flutter/repositories/product_repository.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  testWidgets('Cicle complet: Login -> Listed(Buit) -> Creació -> Listed(Ple)', (
    WidgetTester tester,
  ) async {
    // 1. Configuració de mocks amb estat dinàmic
    var userProductsList = <Map<String, dynamic>>[];

    when(() => mockApiService.login(any(), any())).thenAnswer(
      (_) async => {
        'access_token': 'fake_token',
        'user': {'id': 'user123', 'email': 'test@example.com'},
      },
    );

    when(
      () => mockApiService.getProducts(),
    ).thenAnswer((_) async => http.Response('[]', 200));

    when(
      () => mockApiService.getUserProducts(any(), any()),
    ).thenAnswer((_) async => http.Response(jsonEncode(userProductsList), 200));

    when(() => mockApiService.createProduct(any(), any())).thenAnswer((
      invocation,
    ) async {
      final productData =
          invocation.positionalArguments[1] as Map<String, dynamic>;
      userProductsList.add({
        'id': 1,
        'title': productData['title'],
        'description': productData['description'],
        'price': productData['price'],
        'user_id': 'user123',
      });
    });

    // 2. Llançar aplicació
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => mockApiService),
          Provider<ProductRepository>(
            create: (context) => ProductRepository(apiService: context.read()),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // --- FASE 1: LOGIN ---
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'test@example.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    // --- FASE 2: VERIFICACIÓ HOME I NAVEGACIÓ A LISTED ---
    expect(find.text('Email: test@example.com'), findsOneWidget);

    // Anem a la pantalla Listed per veure que està buida
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('No products found'), findsOneWidget);

    // --- FASE 3: NAVEGACIÓ A CREACIÓ ---
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // --- FASE 4: CREACIÓ DE PRODUCTE ---
    await tester.enterText(
      find.byKey(const Key('productNameField')),
      'Producte Test',
    );
    await tester.enterText(
      find.byKey(const Key('productDescriptionField')),
      'Descripció profunda',
    );
    await tester.enterText(find.byKey(const Key('productPriceField')), '49.99');
    await tester.tap(find.byKey(const Key('createProductButton')));
    await tester.pumpAndSettle();
    expect(find.text('Producte creat correctament'), findsOneWidget);

    // --- FASE 5: TORNAR A LISTED I VERIFICAR PERSISTÈNCIA SIMULADA ---
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Ara hauria d'aparèixer el producte creat perquè el mock ha actualitzat el seu estat
    expect(find.text('Producte Test'), findsOneWidget);
    expect(find.text('Descripció profunda'), findsOneWidget);
    expect(find.text('49.99 €'), findsOneWidget);

    // --- FASE 6: VERIFICACIÓ DE LLAMADES ---
    verify(
      () => mockApiService.login('test@example.com', 'password'),
    ).called(1);
    verify(() => mockApiService.createProduct('fake_token', any())).called(1);
  });
}
