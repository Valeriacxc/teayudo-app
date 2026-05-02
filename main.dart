// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

//  localizaciones para DateRangePicker y demás widgets
import 'package:flutter_localizations/flutter_localizations.dart';

// Tema
import 'theme/theme_notifier.dart';

// Model & Provider de Contactos
import 'data/models/contact.dart';
import 'data/contacts_provider.dart';

//  migración temporal de SharedPreferences → Hive
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/crisis_screen.dart';
import 'screens/register_screen.dart';
import 'screens/routines_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_box_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/name_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Hive init + adapters
  await Hive.initFlutter();

  // Registra el adapter del modelo Contact (usa el mismo typeId que en Contact)
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(ContactAdapter());
  }

  // 2) Abre boxes
  await Hive.openBox('entries');
  await Hive.openBox('routines');
  final contactsBox = await Hive.openBox<Contact>('contacts'); // TIPADO
  await Hive.openBox('helpbox');
  await Hive.openBox('app');
  await Hive.openBox('settings');

  // 3) Migración (opcional)
  await _migrateFromSharedPrefsIfAny(contactsBox);

  // 4) Decide ruta inicial
  final appBox = Hive.box('app');
  final settingsBox = Hive.box('settings');
  final bool seenWelcome =
      appBox.get('seen_welcome', defaultValue: false) as bool;
  final String? savedName = (settingsBox.get('user_name') as String?)?.trim();

  final String startRoute = !seenWelcome
      ? '/welcome'
      : (savedName == null || savedName.isEmpty)
          ? '/name'
          : '/home';

  // 5) Arranca Providers (tema + contactos)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ContactsProvider(contactsBox)),
      ],
      child: TeAyudoApp(initialRoute: startRoute),
    ),
  );
}

class TeAyudoApp extends StatelessWidget {
  final String initialRoute;
  const TeAyudoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (_, notifier, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TeAyudo',

          //  necesario para que el DateRangePicker y otros
          // widgets de Material 
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', ''), // Español
            Locale('en', ''), // Inglés (por si acaso)
          ],

          themeMode: notifier.mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF14B8A6),
            scaffoldBackgroundColor: Colors.white,
            splashFactory: InkRipple.splashFactory,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF14B8A6),
          ),
          routes: {
            '/welcome': (_) => const WelcomeScreen(),
            '/name': (_) => const NameScreen(),
            '/home': (_) => const HomeScreen(),
            '/crisis': (_) => const CrisisScreen(),
            '/register': (_) => const RegisterScreen(),
            '/routines': (_) => const RoutinesScreen(),
            '/contacts': (_) => const ContactsScreen(),
            '/history': (_) => const HistoryScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/helpbox': (_) => const HelpBoxScreen(),
            '/tips': (_) => const TipsScreen(),
          },
          initialRoute: initialRoute,
        );
      },
    );
  }
}

/// ------------------------------------------------------
/// MIGRACIÓN OPCIONAL SharedPreferences → Hive
/// ------------------------------------------------------
Future<void> _migrateFromSharedPrefsIfAny(Box<Contact> contactsBox) async {
  final entriesBox = Hive.box('entries');
  final routinesBox = Hive.box('routines');

  // Si ya hay datos en Hive, no migrar
  if (entriesBox.isNotEmpty || routinesBox.isNotEmpty || contactsBox.isNotEmpty) {
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    // entries
    final rawEntries = prefs.getString('entries');
    if (rawEntries != null) {
      final list = (jsonDecode(rawEntries) as List).cast<dynamic>();
      for (final item in list) {
        entriesBox.add(Map<String, dynamic>.from(item as Map));
      }
    }

    // routines
    final rawRoutines = prefs.getString('routines');
    if (rawRoutines != null) {
      final list = (jsonDecode(rawRoutines) as List).cast<dynamic>();
      for (final item in list) {
        routinesBox.add(Map<String, dynamic>.from(item as Map));
      }
    }

    // contacts (antes eran Map<String, String>) -> Contact tipado
    final rawContacts = prefs.getString('contacts');
    if (rawContacts != null) {
      final list = (jsonDecode(rawContacts) as List).cast<dynamic>();

      int i = 0;
      for (final item in list) {
        final map = Map<String, String>.from((item as Map).cast<String, String>());
        final name = (map['name'] ?? map['nombre'] ?? 'Contacto').trim();
        final phone = (map['phone'] ?? map['telefono'] ?? '').trim();
        final label = (map['label'] ?? '').trim();

        final id = '${DateTime.now().microsecondsSinceEpoch}_${i++}';

        final contact = Contact(
          id: id,
          name: name.isEmpty ? 'Contacto' : name,
          phoneIntl: phone,
          label: label.isEmpty ? null : label,
          isEmergency: true,
        );
        await contactsBox.put(contact.id, contact);
      }
    }
  } catch (e) {
    debugPrint('Migración SharedPreferences → Hive falló: $e');
  }
}





















