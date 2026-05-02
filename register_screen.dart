import 'package:flutter/material.dart';
import '../data/store.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _emotion = 'Tranquila/o';
  final notesCtrl = TextEditingController();

  final emotes = const [
    'Tranquila/o',
    'Ansiosa/o',
    'Tensa/o',
    'Asustada/o',
    'Triste',
    'Irritada/o',
    'Cansada/o',
    'Desesperada/o',
    'Aburrida/o',
    'Motivada/o',
    'Agradecida/o',
    'Calmada/o',
  ];

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar cómo me siento'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPad = MediaQuery.of(context).viewInsets.bottom + 20;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 18, 18, bottomPad),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecciona emoción',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: emotes
                            .map(
                              (e) => ChoiceChip(
                                label: Text(e),
                                selected: _emotion == e,
                                onSelected: (_) =>
                                    setState(() => _emotion = e),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Describe un poco (opcional)',
                          hintText: '¿Qué pasó? ¿Qué te ayudaría ahora?',
                          filled: true,
                          fillColor: cs.surface,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Expanded(child: SizedBox.shrink()),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Guardar registro'),
                          onPressed: () async {
                            await Store.addEntry(
                              emotion: _emotion,
                              action: 'registro',
                              notes: notesCtrl.text,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Guardado ✅'),
                              ),
                            );
                            notesCtrl.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




