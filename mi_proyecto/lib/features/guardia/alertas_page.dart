import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});
  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  late Future<List<Alerta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAlertas();
  }

  Future<List<Alerta>> _fetchAlertas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) throw Exception("No hay token.");

    final uri = Uri.parse("$kBaseUrl/detecciones/");
    final res = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Alerta.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar alertas (${res.statusCode})");
    }
  }

  Future<void> _confirmar(Alerta a, String estado) async {
    // Esto es un ejemplo: depende de si quieres PATCH en tu back
    // Aquí solo actualizamos en memoria para UI
    setState(() {
      a.estado = estado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Alertas en tiempo real")),
      body: FutureBuilder<List<Alerta>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("No hay alertas registradas."));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _fetchAlertas());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = items[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: cs.primary,
                    ),
                    title: Text(
                      "${a.incidenciaLabel} (${(a.confianza * 100).toStringAsFixed(1)}%)",
                    ),
                    subtitle: Text(
                      "${a.zona} • ${_fmt(a.fecha)} • Riesgo: ${a.nivelRiesgoLabel}",
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _confirmar(a, "DESCARTADA"),
                          child: const Text("Descartar"),
                        ),
                        ElevatedButton(
                          onPressed: () => _confirmar(a, "CONFIRMADA"),
                          child: const Text("Confirmar"),
                        ),
                      ],
                    ),
                    onTap: () => _detalle(context, a),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _detalle(BuildContext context, Alerta a) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Incidencia: ${a.incidenciaLabel}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 160,
                color: Colors.black12,
                child: const Center(child: Icon(Icons.image, size: 48)),
              ),
              const SizedBox(height: 12),
              Text(
                "Zona: ${a.zona}\nÁrea: ${a.areacomun}\n"
                "Hora: ${_fmt(a.fecha)}\n"
                "Confianza: ${(a.confianza * 100).toStringAsFixed(1)}%\n"
                "Riesgo: ${a.nivelRiesgoLabel}\n"
                "Estado: ${a.estado}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }
}

// ===== Modelo Alerta (DetecciónIA) =====
class Alerta {
  final int id;
  final String zona;
  final String areacomun;
  final String incidenciaLabel;
  final String nivelRiesgoLabel;
  final double confianza;
  final DateTime fecha;
  String estado; // UI local: NUEVA, CONFIRMADA, DESCARTADA

  Alerta({
    required this.id,
    required this.zona,
    required this.areacomun,
    required this.incidenciaLabel,
    required this.nivelRiesgoLabel,
    required this.confianza,
    required this.fecha,
    this.estado = "NUEVA",
  });

  factory Alerta.fromJson(Map<String, dynamic> j) {
    return Alerta(
      id: j['id'],
      zona: j['zona'] ?? '',
      areacomun: j['areacomun'] ?? '',
      incidenciaLabel: j['incidencia_label'] ?? j['incidencia'],
      nivelRiesgoLabel: j['nivel_riesgo_label'] ?? j['nivel_riesgo'],
      confianza: (j['confianza'] as num).toDouble(),
      fecha: DateTime.parse(j['fechaHora']),
    );
  }
}
