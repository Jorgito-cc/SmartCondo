import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../guardia/dashboard_guardia.dart';
import '../residentes/dashboard_residente.dart';
import '../mantenimiento/dashboard_personal.dart';

const String kBaseUrl = 'https://backend-condominio-production.up.railway.app/api';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    final username = userCtrl.text.trim();
    final password = passCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      _toast('Ingresa usuario y contraseña'); return;
    }
    setState(() => _loading = true);

    try {
      // 1) Login
      final res = await http.post(
        Uri.parse('$kBaseUrl/login/'),
        headers: const {'Content-Type': 'application/json','Accept':'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        String msg = 'Credenciales inválidas';
        try { final err = jsonDecode(res.body); msg = (err['detail'] ?? err['message'] ?? msg).toString(); } catch (_) {}
        _toast(msg); return;
      }
      final data = jsonDecode(res.body);

      // 2) Token
      final token = data['token'] ?? data['access'] ?? data['access_token'];
      if (token == null) { _toast('El backend no devolvió token'); return; }

      // 3) Intentar leer rol del propio login (por si viene)
      String? roleName = _extractRoleName(data);

      // 4) Si no vino el rol, buscar perfil en endpoints comunes
      if (roleName == null) {
        roleName = await _fetchRoleWithToken(token);
      }
      if (roleName == null) { _toast('No se pudo determinar el rol del usuario'); return; }

      // 5) Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token.toString());
      await prefs.setString('role_name', roleName.toString());
      await prefs.setString('username', username);

      // 6) Navegar por rol
      switch (roleName.toUpperCase()) {
        case 'GUARDIA':
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardGuardia()));
          break;
        case 'PERSONAL':
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPersonal()));
          break;
        case 'PROPIETARIO':
        case 'RESIDENTE':
        case 'INQUILINO':
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardResidente()));
          break;
        default:
          _toast('Rol no soportado: $roleName');
      }
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------- helpers --------

  /// Intenta sacar el nombre de rol de distintas formas de payload
  String? _extractRoleName(Map<String, dynamic> data) {
    // nombre directo
    String? name = data['user']?['rol']?['nombre']
        ?? data['user']?['role']?['nombre']
        ?? data['rol']?['nombre']
        ?? data['role_name'];
    if (name is String && name.isNotEmpty) return name;

    // array de roles (como tu ejemplo)
    final roles = data['user']?['roles'] ?? data['roles'];
    if (roles is List && roles.isNotEmpty && roles.first is Map) {
      final r0 = roles.first as Map;
      if (r0['nombre'] is String && (r0['nombre'] as String).isNotEmpty) return r0['nombre'];
      if (r0['id'] is int) return _mapRoleIdToName(r0['id'] as int);
    }

    // objeto rol con id
    final int? id = data['user']?['rol']?['id']
        ?? data['rol']?['id']
        ?? data['role']?['id'];
    if (id != null) return _mapRoleIdToName(id);

    return null;
  }

  /// Hace GET a endpoints típicos de perfil hasta encontrar roles
  Future<String?> _fetchRoleWithToken(String token) async {
    final headers = {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
    final candidates = <String>[
      '$kBaseUrl/usuarios/me/',
      '$kBaseUrl/users/me/',
      '$kBaseUrl/me/',
      '$kBaseUrl/auth/me/',
      '$kBaseUrl/profile/',
    ];

    for (final url in candidates) {
      try {
        final r = await http.get(Uri.parse(url), headers: headers);
        if (r.statusCode >= 200 && r.statusCode < 300) {
          final profile = jsonDecode(r.body);
          final name = _extractRoleName(profile);
          if (name != null) return name;
        }
      } catch (_) { /* sigue probando */ }
    }
    return null;
  }

  String? _mapRoleIdToName(int id) {
    switch (id) {
      case 3: return 'GUARDIA';
      case 2: return 'PERSONAL';
      case 4: return 'PROPIETARIO';
      default: return null;
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.apartment, size: 48, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              const Text('INICIAR SESIÓN', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person_outline)),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Iniciar Sesión'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
