import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/contacts_provider.dart';
import '../data/models/contact.dart';
import '../widgets/heart_with_patch_image.dart';
import 'contacts_edit_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  static const int _maxContacts = 10;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  // ---------- Helpers de teléfono ----------
  final RegExp _intlPhoneRegex = RegExp(r'^\+[0-9]{7,15}$');

  String normalizeIfClPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('56')) return '+$digits';
    if (digits.length == 9 && digits.startsWith('9')) return '+56$digits';
    if (digits.length == 8) return '+562$digits';
    return input; // no cambiamos si no estamos seguros
  }

  String? validateIntlPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un número';
    }
    final v = value.trim();
    if (!_intlPhoneRegex.hasMatch(v)) {
      return 'Usa formato internacional, ej: +56912345678';
    }
    return null;
  }

  Future<void> _call(String intlNumber) async {
    final uri = Uri.parse('tel:$intlNumber');
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el marcador')),
      );
      return;
    }
    await launchUrl(uri);
  }

  Future<void> _add() async {
    final cp = context.read<ContactsProvider>();
    if (cp.emergencies.length >= _maxContacts) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo $_maxContacts contactos')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      await cp.add(
        name: _nameCtrl.text.trim(),
        phoneIntl: _phoneCtrl.text.trim(),
        label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        isEmergency: true,
      );
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _labelCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacto guardado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactsProvider>();
    final list = cp.emergencies; // solo contactos marcados como emergencia
    final canAdd = list.length < _maxContacts;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Colores que respetan el tema
    final Color scaffoldBg = theme.scaffoldBackgroundColor;
    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF222222);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF4A5A68);
    final Color tileColor = isDark
        ? scheme.surfaceVariant.withOpacity(0.6)
        : const Color(0xFFE3F3FB);

    // Nombre de usuario guardado en el box "app" (si existe)
    String userName = '';
    try {
      final appBox = Hive.box('app');
      final value = appBox.get('userName');
      if (value is String) {
        userName = value;
      }
    } catch (_) {}

    final titleText =
        userName.isNotEmpty ? 'Contactos de $userName' : 'Contactos de confianza';

    return Scaffold(
      backgroundColor: scaffoldBg,
      resizeToAvoidBottomInset: true, // 👈 para evitar overflow con teclado
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeartWithPatchImage(size: 24),
            const SizedBox(width: 8),
            Text(
              titleText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            // 👇 esto agrega espacio extra según el teclado
            bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contactos de confianza',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName.isNotEmpty
                    ? 'En una crisis, puedes llamar rápido a estas personas que elegiste, $userName.'
                    : 'En una crisis, puedes llamar rápido a estas personas que elegiste.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),

              // --------- FORM ----------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '+56912345678',
                        helperText:
                            'Para números extranjeros, incluye el + y código de país',
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
                                  offset: normalized.length),
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
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: canAdd ? _add : null,
                        icon: const HeartWithPatchImage(size: 20),
                        label: Text(
                          canAdd
                              ? 'Agregar contacto'
                              : 'Máximo $_maxContacts contactos alcanzado',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF78C1E0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tus contactos de emergencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --------- LISTA ----------
              list.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no tienes contactos',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true, // 👈 importante dentro del ScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // 👈 el scroll lo maneja SingleChildScrollView
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final Contact c = list[i];
                        return ListTile(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContactEditScreen(contact: c),
                              ),
                            );
                          },
                          tileColor: tileColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            Icons.person_outline,
                            color: primaryTextColor,
                          ),
                          title: Text(
                            c.name,
                            style: TextStyle(color: primaryTextColor),
                          ),
                          subtitle: Text(
                            '${c.label?.isNotEmpty == true ? '${c.label} • ' : ''}${c.phoneIntl}',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Llamar',
                                icon: Icon(
                                  Icons.call,
                                  color: primaryTextColor,
                                ),
                                onPressed: () => _call(c.phoneIntl),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: primaryTextColor,
                                ),
                                onPressed: () => context
                                    .read<ContactsProvider>()
                                    .remove(c.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 6),
              Text(
                'Nota: WOM puede cobrar llamadas internacionales. '
                'Usa siempre formato con + y código de país.',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}












