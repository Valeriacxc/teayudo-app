// lib/screens/name_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';               // 👈 NUEVO
import '../data/user_prefs.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl.text = UserPrefs.name ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _ctrl.text.trim();

    // 🔹 Sigue usando tu helper
    await UserPrefs.setName(name);

    // 🔹 Y además sincronizamos explícitamente las dos cajas de Hive
    final settingsBox = Hive.box('settings');
    final appBox = Hive.box('app');
    await settingsBox.put('user_name', name);
    await appBox.put('userName', name);

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu nombre'),
        centerTitle: true,
      ),
      // 👇 Para que el contenido se mueva con el teclado
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              // 👇 Esto evita el “bottom overflowed by XX pixels”
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo te llamas?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Escribe tu nombre';
                      }
                      if (v.trim().length < 2) return 'Muy corto';
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Guardar y continuar'),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



