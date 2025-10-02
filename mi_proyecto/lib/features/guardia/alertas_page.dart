import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================
/// CONFIG
/// ============================
const String kApiBase =
    'https://backend-condominio-production.up.railway.app/api';

Map<String, String> _headers(String token) => {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};

/// ============================
/// MODELO
/// ============================
class Noti {
  final int id;
  final String titulo;
  final String poligono;
  final String descripcion;
  final DateTime creadoEn;
  bool leido;

  Noti({
    required this.id,
    required this.titulo,
    required this.poligono,
    required this.descripcion,
    required this.creadoEn,
    required this.leido,
  });

  factory Noti.fromJson(Map<String, dynamic> j) => Noti(
    id: j['id'],
    titulo: j['titulo'] ?? '',
    poligono: j['poligono'] ?? '',
    descripcion: j['descripcion'] ?? '',
    creadoEn: DateTime.parse(j['creado_en']),
    leido: j['leido'] == true,
  );
}

/// ============================
/// CLIENTE HTTP
/// ============================
class NotiApi {
  static Future<List<Noti>> list({
    required String token,
    String? search,
    bool? leido,
    String ordering = '-creado_en',
  }) async {
    final qp = <String, String>{'ordering': ordering};
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (leido != null) qp['leido'] = leido ? 'true' : 'false';

    final uri = Uri.parse(
      '$kApiBase/notificaciones/',
    ).replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception('Error list: ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body);
    final list = (body is Map && body['results'] != null)
        ? body['results']
        : body;
    return (list as List).map((e) => Noti.fromJson(e)).toList();
  }

  static Future<Noti> marcarLeida({
    required String token,
    required int id,
  }) async {
    final res = await http.post(
      Uri.parse('$kApiBase/notificaciones/$id/marcar_leida/'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('Error marcar_leida: ${res.statusCode} ${res.body}');
    }
    return Noti.fromJson(jsonDecode(res.body));
  }

  static Future<Noti> marcarNoLeida({
    required String token,
    required int id,
  }) async {
    final res = await http.post(
      Uri.parse('$kApiBase/notificaciones/$id/marcar_no_leida/'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('Error marcar_no_leida: ${res.statusCode} ${res.body}');
    }
    return Noti.fromJson(jsonDecode(res.body));
  }
}

/// ============================
/// UI
/// ============================
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});
  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final _searchCtrl = TextEditingController();
  bool? _filtroLeido; // null = todos, true = leídos, false = no leídos
  late Future<List<Noti>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Noti>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token de sesión');
    return await NotiApi.list(
      token: token,
      search: _searchCtrl.text.trim(),
      leido: _filtroLeido,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetch());
    await _future;
  }

  Future<void> _toggleLeido(Noti n) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      _snack('No hay token');
      return;
    }

    try {
      Noti actualizado;
      if (n.leido) {
        actualizado = await NotiApi.marcarNoLeida(token: token, id: n.id);
      } else {
        actualizado = await NotiApi.marcarLeida(token: token, id: n.id);
      }
      setState(() {
        n.leido = actualizado.leido;
      });
    } catch (e) {
      _snack('Error: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Column(
        children: [
          // Barra de búsqueda + filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar (título, descripción, polígono, usuario...)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _refresh(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filtroLeido == null,
                  onSelected: (_) {
                    setState(() => _filtroLeido = null);
                    _refresh();
                  },
                ),
                FilterChip(
                  label: const Text('No leídos'),
                  selected: _filtroLeido == false,
                  onSelected: (_) {
                    setState(() => _filtroLeido = false);
                    _refresh();
                  },
                ),
                FilterChip(
                  label: const Text('Leídos'),
                  selected: _filtroLeido == true,
                  onSelected: (_) {
                    setState(() => _filtroLeido = true);
                    _refresh();
                  },
                ),
                IconButton(
                  tooltip: 'Buscar',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: FutureBuilder<List<Noti>>(
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
                  return const Center(child: Text('Sin notificaciones.'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: n.leido
                                ? cs.surfaceContainerHighest
                                : cs.primaryContainer,
                            child: Icon(
                              n.leido
                                  ? Icons.mark_email_read
                                  : Icons.markunread,
                              color: n.leido ? cs.secondary : cs.primary,
                            ),
                          ),
                          title: Text(
                            n.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${n.poligono} • ${_fmt(n.creadoEn)}\n${n.descripcion}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: TextButton.icon(
                            onPressed: () => _toggleLeido(n),
                            icon: Icon(
                              n.leido ? Icons.visibility_off : Icons.visibility,
                            ),
                            label: Text(
                              n.leido ? 'Marcar no leída' : 'Marcar leída',
                            ),
                          ),
                          onTap: () => _detalle(n),
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
    );
  }

  void _detalle(Noti n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Polígono: ${n.poligono}'),
            const SizedBox(height: 6),
            Text('Fecha: ${_fmt(n.creadoEn)}'),
            const SizedBox(height: 12),
            Text(n.descripcion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleLeido(n);
            },
            child: Text(n.leido ? 'Marcar no leída' : 'Marcar leída'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    final h =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }
}
