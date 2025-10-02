import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});
  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  late Future<List<Mantenimiento>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchMantenimientos();
  }

  Future<List<Mantenimiento>> _fetchMantenimientos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token.');

    final uri = Uri.parse('$kBaseUrl/mantenimientos/');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Mantenimiento.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar (${res.statusCode})');
    }
  }

  Future<void> _marcarCompletada(Mantenimiento m) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token.');

    final uri = Uri.parse('$kBaseUrl/mantenimientos/${m.id}/');
    final res = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': 'COMPLETADA'}),
    );

    if (res.statusCode == 200) {
      setState(() => _future = _fetchMantenimientos());
    } else {
      throw Exception('Error al actualizar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis tareas de mantenimiento')),
      body: FutureBuilder<List<Mantenimiento>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No tienes tareas asignadas.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _fetchMantenimientos());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = items[i];
                final chipColor = switch (t.estado) {
                  'PENDIENTE' => Colors.orange,
                  'EN PROCESO' => Colors.blue,
                  'COMPLETADA' => Colors.green,
                  _ => Colors.grey,
                };
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: chipColor.withOpacity(.15),
                      child: Icon(Icons.build, color: chipColor),
                    ),
                    title: Text(t.titulo),
                    subtitle:
                        Text('${t.ubicacion} • Prioridad ${t.prioridad}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text(t.estado),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          _fmt(t.asignada),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () {
                      if (t.estado != 'COMPLETADA') {
                        _marcarCompletada(t);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ===== Modelo Mantenimiento =====
class Mantenimiento {
  final int id;
  final String titulo;
  final String ubicacion;
  final String prioridad;
  final String descripcion;
  final String estado; // debes agregar este campo en el backend
  final DateTime asignada;

  Mantenimiento({
    required this.id,
    required this.titulo,
    required this.ubicacion,
    required this.prioridad,
    required this.descripcion,
    required this.estado,
    required this.asignada,
  });

  factory Mantenimiento.fromJson(Map<String, dynamic> j) {
    return Mantenimiento(
      id: j['id'],
      titulo: j['titulo'],
      ubicacion: j['ubicacion'],
      prioridad: j['prioridad'],
      descripcion: j['descripcion'] ?? '',
      estado: j['estado'] ?? 'PENDIENTE', // si no existe, default
      asignada: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
