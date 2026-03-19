# Documentació Tècnica: Projecte Flutter + Supabase

> 👨‍💻 **Alumne:** Alex Caballé Arasa  
> 🎓 **Cicle:** Ampliació de desenvolupament d'aplicacions multiplataforma  
> 📅 **Data:** 5 / març / 2026  
> 👨‍🏫 **Tutor:** Daniel Jesús Garcia  
> 🔗 **Defensa Tècnica:** [Enllaç a Google Drive](https://drive.google.com/drive/folders/1u9DX9nurdtvsNsfVP5rNgfNMzo0jfAbt?usp=sharing)

## 1. Arquitectura de l'Aplicació
Aquest projecte utilitza el framework **Flutter** per al desenvolupament _cross-platform_ (Web i Android) des d'una única base de codi. Per al backend i persistència de dades fa servir el BaaS, **Supabase**, utilitzat directament a través de trucades REST.

- **Patró d'Arquitectura i Gestió d'Estat**: L'aplicació segueix el patró MVVM (Model-View-ViewModel) i utilitza la llibreria `provider` de Flutter com a mètode d'injecció de dependències i per a l'actualització reactiva de l'estat a la interfície d'usuari (`ChangeNotifier`).
- **Capa de Serveis API (`ApiService`)**: Classe encarregada d'interactuar estretament amb l'API Rest de Supabase per executar els mètodes relacionats amb Autenticació (obtenció del JWT _token_ en el _login_) i amb les operacions _CRUD_ del recurs `products` injectant els headers adequats i la validació de sessió.
- **Repositori (`ProductRepository`)**: Gestiona la instància d'`ApiService` de manera asíncrona, proporcionant emmagatzematge efímer a les credencials (`access_token`, `userData`) i formatant les excepcions, convertint les respostes HTTP en entitats o _Models_ (`Product`).
- **ViewModel (`ProductViewModel`)**: Executa directament cada cas d'ús i es notifica a l'UI.
- **Vistes (`UI`)**: Componentes i Widgets amb funcions i dissenys modularitzats (`LoginScreen`, `HomePage`, `CreationPage`, `ListedPage`), reaccionant de forma instantània a les validacions aportades a través de les notificacions d'estat del Provider.

## 2. Estratègia de Test
El projecte conté una suite de proves per garantir la consistència i comportament de la plataforma. La creació de _mocks_ s'arriba mitjançant `mocktail` que injecta comportaments esperats per parts aïllades simulant els temps i estats.

**Mètodes de les Proves Implementades:**
- **Proves Unitàries i de Widget (`test/app_test.dart`)**: Estan englobades dins una mateixa bateria. Verifiquen individualment els mètodes en les capes de Repo i ViewModel, així com validen la reescriptura, presència o alteració de botons i quadres de text depenent dels seus estats interns. Simulacions complides com a excepció 500 des del backend i visualitzacions d'avisos "No products found" a la vista de _Listed_ sense interacció extra.
- **Proves d'Integració End-to-End (`integration_test/app_test.dart`)**: Test objectiu (e2e). Un tester emulat llança l'Aplicació total completant un cicle total sencer des del registre i credencials fins a observar el comportament del producte de forma dinàmica després d'un `mockApiService` adaptant l'afegit nou interactuant en un cicle de botons sencer.
- **Llibreries per a testeig**: `flutter_test`, `integration_test` i `mocktail`.

**Comandes per executar els tests localment:**
```bash
# Executar provesitàries (Unitat i Widget test)
flutter test test/app_test.dart

# Executar l'arbre d'integració de proves
flutter test integration_test/app_test.dart

# Comanda conjunta per realitzar l'anàlisi de coverage i extraure resultats amb extensió .info
flutter test --coverage

# Utilitat 'lcov' per l'exportació lcov.info -> fitxers HTML visuals en el servidor (en local has de tenir preinstal·lat utilitats lcov i genhtml)
genhtml coverage/lcov.info --output-directory coverage/html
```

## 3. Sistema de CI/CD (Integració i Desplegament Continus)
Hi ha un sistema automatitzat creat mitjançant **GitHub Actions** (`.github/workflows/pipeline.yml`), estructurat en diversos _jobs_ que rebran detonadors sota mètodes `push` o `pull_request` enfocats cap a repositoris principals com `main` o `master`.

- **Job 1: `qa` (Quality Assurance)**
  Aixeca l'entorn (`ubuntu-latest`), inicialitza el repositori en els serveis en núvol al costat d'una configuració estàbil de Flutter que es dediquen a obtenir paquets i seguidament genera el mateix codi test de línia `flutter test --coverage`. Una vegada creat instal·la `lcov` processant-lo i extreu la coberta per projectar-la per pas informatiu `GitHub Job Summary`.
  **Artifact Final Generat:** `coverage-report` (Informe per avaluar de forma dinàmica les proporcions i línies correctament garantides per les proves des d'una pàgina web en directori `html/`).

- **Job 2: `deploy-web` (Desplegament Web)**
  Filtra i només s'executarà el flux quan hi hagi un `push` cap a les branques en producció (`main`, `master`) superant satisfactòriament i obligatòriament el node de `qa`. Construeix un bundle `web` amb capacitats natives mitjançant `flutter build web` i envia el codi empaquetat a través de `FirebaseExtended/action-hosting-deploy` cap al directori en viu en compte de Firebase definit a nom de *'secondfluterpt3'*.

- **Job 3: `build-android` (Compilació APK Android)**
  Sota la validació necessària del flux en *release main* i amb les aprovacions des de `qa` de tests en passat; Inicialitza plataformes i java necessari. Empra el procediment de desxifrat i configuració del clauer en Base64 present des del `keystore.jks` passant credencials secrets com Android Alias o Android Password mitjançant GitHub Secrets assignats per a certificar i llançar prèviament el build del release final en format aplicatiu Android.
  **Artifact Final Generat:** `release-apk` (Compilatiu preparat del `.apk` extret del producte final, per fer baixar i testar fàcilment el conjunt).

## 4. Accés a Aplicacions Desplegades (Versions en PRODUCCIÓ)

Per interaccionar amb l'ecosistema sense utilitzar modes de desenvolupament hi ha aquestes versions pre-creades:

- **APP Web**: S'allotja al servei i CDN integrat de *Firebase Hosting*. Amb cada nova actualització en `main` s'envia a producció el bundle i aquest directori resta exposat globalment al link assignat:
  Accés Web: [**https://secondfluterpt3.web.app/**](https://secondfluterpt3.web.app/) o pel domini Firebase [**https://secondfluterpt3.firebaseapp.com/**](https://secondfluterpt3.firebaseapp.com/).

- **APP Android (.apk)**: Es tracta d'un instal·lador pel nostre telèfon des del mòdul GitHub. Per fer recíproc aquest element el procediment a aconseguir passa per:
  1. Anar a la pestanya de repositori "**Actions**" de GitHub.
  2. Cercar la darrera execució i el **Workflow correcte (verd)** referent a la pipeline.
  3. Desplaçar-se cap a baix apartat inferior i click sobre l'apartat anomenat "**Artifacts**".
  4. Clic ràpid a «`release-apk`» per obtenir un *.zip*. Descomprimir i procedir l'enllaç resultant amb el nostre dispositiu via memòria USB i obrir l'arxiu `.apk` per fer la instal·lació. (Pot ser previ activar l'opció Origens desconeguts en sistema Android).
