import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'https://backend-condominio-production.up.railway.app/api';

class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});
  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  // UI
  DateTime _fecha = DateTime.now();
  String? _hora;
  AreaComun? _areaSel;

  final _horarios = const [
    '08:00-09:00',
    '09:00-10:00',
    '10:00-11:00',
    '18:00-19:00',
    '19:00-20:00',
  ];

  // Data
  bool _loading = false;
  int? _miUsuarioId;
  List<AreaComun> _areas = [];
  List<_Reserva> _misReservas = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await _fetchMe();
      await Future.wait([_fetchAreas(), _fetchMisReservas()]);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchMe() async {
    final token = await _getToken();
    if (token == null) throw Exception('Sin token. Inicia sesión.');

    final res = await http.get(
      Uri.parse('$kBaseUrl/usuarios/me/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Sesión expirada (401).');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error perfil: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    _miUsuarioId = j['id'] as int?;
  }

  Future<void> _fetchAreas() async {
    final token = await _getToken();
    if (token == null) throw Exception('Sin token. Inicia sesión.');

    // si quieres solo disponibles: final uri = Uri.parse('$kBaseUrl/areas-comunes/?estado=disponible');
    final uri = Uri.parse('$kBaseUrl/areas-comunes/');
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 401) throw Exception('Sesión expirada (401).');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error áreas: ${res.statusCode}');
    }

    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    setState(() {
      _areas = list.map((j) => AreaComun.fromJson(j)).toList();
    });
  }

  Future<void> _fetchMisReservas() async {
    if (_miUsuarioId == null) return;
    final token = await _getToken();
    if (token == null) throw Exception('Sin token. Inicia sesión.');

    final uri =
        Uri.parse('$kBaseUrl/reservas/?usuario=$_miUsuarioId&ordering=-fecha_inicio');
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 401) throw Exception('Sesión expirada (401).');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error reservas: ${res.statusCode}');
    }

    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    setState(() {
      _misReservas = list.map((j) => _Reserva.fromJson(j)).toList();
    });
  }

  Future<void> _crearReserva() async {
    if (_areaSel == null || _hora == null) return;

    final parts = _hora!.split('-'); // ['18:00','19:00']
    final hIni = parts[0].trim();
    final hFin = parts[1].trim();

    final inicio = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      int.parse(hIni.split(':')[0]),
      int.parse(hIni.split(':')[1]),
    ).toUtc();

    final fin = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      int.parse(hFin.split(':')[0]),
      int.parse(hFin.split(':')[1]),
    ).toUtc();

    final token = await _getToken();
    if (token == null) {
      _snack('Sin token. Inicia sesión.');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/reservas/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "nombre": "Reserva ${_areaSel!.nombre}",
          "fecha_inicio": inicio.toIso8601String(), // 2025-09-25T22:00:00.000Z
          "fecha_fin": fin.toIso8601String(),
          "horario": _hora,
          "areacomun": _areaSel!.id,
          // "usuario": omitido → lo pone el backend con request.user
        }),
      );

      if (res.statusCode == 201) {
        _snack('Reserva creada');
        await _fetchMisReservas();
        _mostrarComprobante(res.body);
      } else if (res.statusCode == 400) {
        _snack(_extraerMensaje(res.body) ?? 'Validación 400');
      } else if (res.statusCode == 401) {
        _snack('Sesión expirada (401).');
      } else {
        _snack('Error al crear: ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarComprobante(String raw) {
    final f = '${_fecha.day}/${_fecha.month}/${_fecha.year}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reserva creada'),
        content: Text('Área: ${_areaSel?.nombre}\nFecha: $f\nHorario: $_hora\n\nRespuesta:\n$raw'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  String? _extraerMensaje(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return j['detail'].toString();
      return body;
    } catch (_) {
      return body;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchAreas();
                await _fetchMisReservas();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Selecciona fecha', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  CalendarDatePicker(
                    initialDate: _fecha,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    onDateChanged: (d) => setState(() => _fecha = d),
                  ),
                  const SizedBox(height: 8),

                  // Áreas desde API
                  DropdownButtonFormField<AreaComun>(
                    value: _areaSel,
                    items: _areas
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text('${a.nombre} • ${a.estado}'),
                            ))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Área común'),
                    onChanged: (v) => setState(() => _areaSel = v),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: _hora,
                    items: _horarios
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Horario'),
                    onChanged: (v) => setState(() => _hora = v),
                  ),

                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_areaSel != null && _hora != null) ? _crearReserva : null,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Confirmar reserva'),
                  ),

                  const SizedBox(height: 24),
                  Text('Mis reservas', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_misReservas.isEmpty) const Text('Sin reservas registradas.'),
                  ..._misReservas.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text(
                          '${r.areacomunNombre ?? 'Área #${r.areacomun}'} • ${_fmtFecha(r.fechaInicio)}',
                        ),
                        subtitle: Text('Horario: ${r.horario ?? '--'} • Estado: ${r.estado}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _fmtFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

/// ======== Models ========

class AreaComun {
  final int id;
  final String nombre;
  final String estado; // disponible / mantenimiento / etc.
  final int? capacidad;
  final String? ubicacion;
  final String? descripcion;
  final String? precioBase;

  AreaComun({
    required this.id,
    required this.nombre,
    required this.estado,
    this.capacidad,
    this.ubicacion,
    this.descripcion,
    this.precioBase,
  });

  factory AreaComun.fromJson(Map<String, dynamic> j) => AreaComun(
        id: j['id'] as int,
        nombre: (j['nombre'] ?? '').toString(),
        estado: (j['estado'] ?? '').toString(),
        capacidad: j['capacidad'] as int?,
        ubicacion: j['ubicacion'] as String?,
        descripcion: j['descripcion'] as String?,
        precioBase: j['precio_base']?.toString(),
      );

  @override
  String toString() => '$id - $nombre';
}

class _Reserva {
  final int id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? horario;
  final int? areacomun;
  final String? areacomunNombre;
  final String estado;

  _Reserva({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    this.horario,
    this.areacomun,
    this.areacomunNombre,
  });

  factory _Reserva.fromJson(Map<String, dynamic> j) => _Reserva(
        id: (j['id'] ?? 0) as int,
        nombre: (j['nombre'] ?? '') as String,
        fechaInicio: DateTime.parse(j['fecha_inicio'] as String).toLocal(),
        fechaFin: DateTime.parse(j['fecha_fin'] as String).toLocal(),
        horario: j['horario'] as String?,
        areacomun: j['areacomun'] as int?,
        areacomunNombre: j['areacomun_nombre'] as String?,
        estado: (j['estado'] ?? '').toString(),
      );
}
