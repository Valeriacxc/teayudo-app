import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/contact.dart';
import '../data/contacts_provider.dart';
import '../widgets/heart_with_patch_image.dart';

class ContactEditScreen extends StatefulWidget {
  final Contact contact;
  const ContactEditScreen({super.key, required this.contact});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _notesCtrl;
  bool _isEmergency = true;

  final RegExp _intlPhoneRegex = RegExp(r'^\+[0-9]{7,15}$');

  String normalizeIfClPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('56')) return '+$digits';
    if (digits.length == 9 && digits.startsWith('9')) return '+56$digits';
    if (digits.length == 8) return '+562$digits';
    return input;
  }

  String? validateIntlPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa un número';
    if (!_intlPhoneRegex.hasMatch(value.trim())) {
      return 'Usa formato internacional, ej: +56912345678';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phoneIntl);
    _labelCtrl = TextEditingController(text: c.label ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
    _isEmergency = c.isEmergency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cp = context.read<ContactsProvider>();
    final c = widget.contact
      ..name = _nameCtrl.text.trim()
      ..phoneIntl = _phoneCtrl.text.trim()
      ..label = _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim()
      ..notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()
      ..isEmergency = _isEmergency;

    await cp.update(c);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacto actualizado')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: const Text('¿Seguro que quieres eliminar este contacto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ContactsProvider>().remove(widget.contact.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            HeartWithPatchImage(size: 26),
            SizedBox(width: 8),
            Text('Editar contacto'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Ajusta los datos de este contacto de confianza.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        // 👇 aquí también solo “Teléfono”
                        labelText: 'Teléfono',
                        hintText: '+56912345678',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                      ],
                      onChanged: (raw) {
                        if (raw.isNotEmpty && !raw.startsWith('+')) {
                          final normalized = normalizeIfClPhone(raw);
                          if (normalized != raw) {
                            _phoneCtrl.value = TextEditingValue(
                              text: normalized,
                              selection: TextSelection.collapsed(
                                offset: normalized.length,
                              ),
                            );
                          }
                        }
                      },
                      validator: validateIntlPhone,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Etiqueta (opcional)',
                        hintText: 'Ej: Mamá, Psicólogo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _isEmergency,
                          onChanged: (v) =>
                              setState(() => _isEmergency = v ?? true),
                        ),
                        const Expanded(
                          child: Text(
                            'Marcar como contacto de emergencia',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const HeartWithPatchImage(size: 22),
                        label: const Text('Guardar cambios'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}







