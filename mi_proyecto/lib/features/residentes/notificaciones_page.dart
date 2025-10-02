import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});
  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  late Future<List<Notificacion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchNotificaciones();
  }

  Future<List<Notificacion>> _fetchNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token guardado.');

    final uri = Uri.parse('$kBaseUrl/notificaciones/');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Notificacion.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener notificaciones (${res.statusCode})');
    }
  }

  Future<void> _marcarLeida(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token.');

    final uri = Uri.parse('$kBaseUrl/notificaciones/$id/marcar_leida/');
    final res = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw Exception('Error al marcar leída (${res.statusCode})');
    }
    setState(() {
      _future = _fetchNotificaciones(); // 🔄 refresca lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: FutureBuilder<List<Notificacion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay notificaciones.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _fetchNotificaciones();
              });
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                final icon = switch (n.poligono.toLowerCase()) {
                  'finanza' => Icons.account_balance_wallet_outlined,
                  'seguridad' => Icons.shield_outlined,
                  'reserva' => Icons.event_available_outlined,
                  _ => Icons.notifications_outlined,
                };
                return Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(n.titulo),
                    subtitle: Text(n.descripcion),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (!n.leido)
                          FilledButton(
                            onPressed: () => _marcarLeida(n.id),
                            child: const Text('Marcar leído'),
                          ),
                        OutlinedButton(
                          onPressed: () => _ver(n),
                          child: const Text('Ver'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _ver(Notificacion n) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(n.titulo),
          content: Text('${n.descripcion}\n\n${_fmt(n.creadoEn)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final d = '${dt.day}/${dt.month}';
    final h = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }
}

// ===== Modelo Notificacion =====
class Notificacion {
  final int id;
  final String titulo;
  final String descripcion;
  final String poligono;
  final bool leido;
  final DateTime creadoEn;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.poligono,
    required this.leido,
    required this.creadoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      poligono: json['poligono'],
      leido: json['leido'],
      creadoEn: DateTime.parse(json['creado_en']),
    );
  }
}
