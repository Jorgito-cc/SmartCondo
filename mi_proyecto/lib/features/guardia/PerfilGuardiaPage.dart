import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ↙️ ajusta esta ruta a donde esté tu login
import '../auth/login_page.dart';
// (opcionales) accesos rápidos
import '../guardia/qr_access_page.dart';
import '../guardia/alertas_page.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class PerfilGuardiaPage extends StatefulWidget {
  const PerfilGuardiaPage({super.key});
  @override
  State<PerfilGuardiaPage> createState() => _PerfilGuardiaPageState();
}

class _PerfilGuardiaPageState extends State<PerfilGuardiaPage> {
  late Future<_AppUser> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchProfile();
  }

  Future<_AppUser> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null)
      throw Exception('No hay token. Inicia sesión nuevamente.');

    final res = await http.get(
      Uri.parse('$kBaseUrl/usuarios/me/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 401)
      throw Exception('Sesión expirada (401). Inicia sesión otra vez.');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Error ${res.statusCode}';
      try {
        final err = jsonDecode(res.body);
        msg = (err['detail'] ?? err['message'] ?? msg).toString();
      } catch (_) {}
      throw Exception(msg);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _AppUser.fromJson(json);
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchProfile());
    await _future;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('role_name');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil (Guardia)'),
        backgroundColor: cs.primary, // pequeño toque de estilo propio
        foregroundColor: cs.onPrimary,
      ),
      body: FutureBuilder<_AppUser>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 36),
                    const SizedBox(height: 8),
                    Text(snap.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final u = snap.data!;
          final fullName =
              (('${u.firstName ?? ''} ${u.lastName ?? ''}').trim()).isEmpty
              ? (u.username ?? '')
              : ('${u.firstName ?? ''} ${u.lastName ?? ''}').trim();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: (u.urlImg != null && u.urlImg!.isNotEmpty)
                        ? NetworkImage(u.urlImg!)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: (u.urlImg == null || u.urlImg!.isEmpty)
                        ? const Icon(
                            Icons.security,
                            size: 48,
                          ) // ícono distinto para guardia
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_moon_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      u.rolNombre ?? 'GUARDIA',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Usuario'),
                  subtitle: Text(u.username ?? '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Correo'),
                  subtitle: Text(u.email ?? '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Teléfono'),
                  subtitle: Text(
                    (u.telefono ?? '').isEmpty ? '-' : u.telefono!,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Estado'),
                  subtitle: Text(u.estado ?? '-'),
                ),
                if (u.ci != null)
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: const Text('CI'),
                    subtitle: Text(u.ci.toString()),
                  ),

                const SizedBox(height: 12),

                // Accesos rápidos (opcionales)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.qr_code_scanner,
                      label: 'Escanear QR',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QrScanPage()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.notifications_active_outlined,
                      label: 'Alertas',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificacionesPage(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Tarjetitas de acción rápida (estilo simple)
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: w,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ———— mismo modelo que usaste en PerfilPage ————
class _AppUser {
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? telefono;
  final String? estado;
  final String? urlImg;
  final dynamic ci;
  final String? rolNombre;

  _AppUser({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.telefono,
    this.estado,
    this.urlImg,
    this.ci,
    this.rolNombre,
  });

  factory _AppUser.fromJson(Map<String, dynamic> j) {
    String? rol;
    final roles = j['roles'];
    if (roles is List && roles.isNotEmpty) {
      final r0 = roles.first;
      if (r0 is Map && r0['nombre'] is String) {
        rol = r0['nombre'] as String;
      }
    }

    return _AppUser(
      id: j['id'] as int?,
      username: j['username'] as String?,
      email: j['email'] as String?,
      firstName: j['first_name'] as String?,
      lastName: j['last_name'] as String?,
      telefono: j['telefono'] as String?,
      estado: j['estado'] as String?,
      urlImg: j['url_img'] as String?,
      ci: j['ci'],
      rolNombre: rol,
    );
  }
}
