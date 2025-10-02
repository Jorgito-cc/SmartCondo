import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class VisitantesPage extends StatefulWidget {
  const VisitantesPage({super.key});
  @override
  State<VisitantesPage> createState() => _VisitantesPageState();
}

class _VisitantesPageState extends State<VisitantesPage> {
  final _q = TextEditingController();
  late Future<List<Visita>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchVisitas();
  }

  Future<List<Visita>> _fetchVisitas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception("No hay token.");

    final uri = Uri.parse("$kBaseUrl/visitas/");
    final res = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Visita.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar visitas (${res.statusCode})");
    }
  }

  Future<void> _registrarSalida(Visita v) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception("No hay token.");

    final uri = Uri.parse("$kBaseUrl/visitas/${v.id}/");
    final now = DateTime.now().toUtc().toIso8601String();
    final res = await http.patch(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"fecha_hora_salida": now}),
    );

    if (res.statusCode == 200) {
      setState(() {
        _future = _fetchVisitas();
      });
    } else {
      throw Exception("Error al registrar salida (${res.statusCode})");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Visitantes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _q,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre o unidad',
                suffixIcon: _q.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _q.clear();
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Visita>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }
                var visitas = snap.data ?? [];
                if (_q.text.isNotEmpty) {
                  visitas = visitas
                      .where(
                        (v) =>
                            v.nombre.toLowerCase().contains(
                              _q.text.toLowerCase(),
                            ) ||
                            v.unidad.contains(_q.text),
                      )
                      .toList();
                }
                if (visitas.isEmpty) {
                  return const Center(child: Text("No hay visitantes."));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _fetchVisitas());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: visitas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final v = visitas[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(v.nombre),
                          subtitle: Text(
                            '${v.unidad}\nIngreso: ${_fmt(v.llegada)}'
                            '${v.salida != null ? '\nSalida: ${_fmt(v.salida!)}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: v.salida == null
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.logout, size: 16),
                                  label: const Text('Registrar salida'),
                                  onPressed: () => _registrarSalida(v),
                                )
                              : const Chip(label: Text('Finalizado')),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // aquí puedes navegar al formulario de nuevo ingreso
          // await Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitanteFormPage()));
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo ingreso'),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }
}

// ===== Modelo Visita =====
class Visita {
  final int id;
  final String nombre;
  final String unidad;
  final DateTime llegada;
  final DateTime? salida;

  Visita({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.llegada,
    this.salida,
  });

  factory Visita.fromJson(Map<String, dynamic> j) {
    return Visita(
      id: j['id'],
      nombre: j['nombre'],
      unidad: j['unidad'] is Map
          ? j['unidad']['numero'] ?? ''
          : j['unidad'].toString(),
      llegada: DateTime.parse(j['fecha_hora_llegada']),
      salida: j['fecha_hora_salida'] != null
          ? DateTime.parse(j['fecha_hora_salida'])
          : null,
    );
  }
}
