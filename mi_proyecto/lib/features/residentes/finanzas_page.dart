import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'https://backend-condominio-production.up.railway.app/api';

class FinanzasPage extends StatefulWidget {
  const FinanzasPage({super.key});
  @override
  State<FinanzasPage> createState() => _FinanzasPageState();
}

class _FinanzasPageState extends State<FinanzasPage> {
  bool _loading = false;
  int? _unidadId;
  String? _username;
  final _unidadCtrl = TextEditingController();

  List<_Cuota> _cuotas = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await _cargarUnidadPreferida();
      await _fetchMe();
      if (_unidadId != null) {
        await _fetchCuotas();
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarUnidadPreferida() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_unidad_id');
    if (last != null) {
      _unidadId = last;
      _unidadCtrl.text = last.toString();
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token. Inicia sesión.');
    return token;
  }

  Future<void> _fetchMe() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$kBaseUrl/usuarios/me/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Sesión expirada (401).');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Perfil ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    _username = j['username'] as String?;
    final uid = j['unidad_id'] ?? j['unidad'] ?? j['unidadId'];
    if (uid is int) {
      _unidadId = uid;
      _unidadCtrl.text = uid.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_unidad_id', uid);
    }
    setState(() {});
  }

  Future<void> _fetchCuotas() async {
    if (_unidadId == null) return;
    final token = await _getToken();
    final url = Uri.parse('$kBaseUrl/cuotas?unidad=$_unidadId&ordering=-fecha_a_pagar');
    final res = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Sesión expirada (401).');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Cuotas ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    setState(() {
      _cuotas = list.map(_Cuota.fromJson).toList();
    });
  }

  Future<void> _marcarComoPagada(_Cuota c) async {
    // Simulación de pago → simplemente marcar en backend
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$kBaseUrl/pagos/marcar-pagada/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'cuota_id': c.id}),
    );

    if (res.statusCode != 200) {
      _snack('Error al registrar pago: ${res.body}');
      return;
    }

    _snack('Pago de cuota ${c.id} registrado.');
    await _fetchCuotas();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _unidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _cuotas.where((c) => (c.estado ?? '').toUpperCase() != 'PAGADA').toList();
    final pagadas    = _cuotas.where((c) => (c.estado ?? '').toUpperCase() == 'PAGADA').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Finanzas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async { if (_unidadId != null) await _fetchCuotas(); },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _unidadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Unidad ID',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final v = int.tryParse(_unidadCtrl.text.trim());
                          if (v == null) { _snack('Unidad inválida'); return; }
                          setState(() => _unidadId = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('last_unidad_id', v);
                          await _fetchCuotas();
                        },
                        child: const Text('Cargar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (pendientes.isNotEmpty) ...[
                    Text('Pendientes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...pendientes.map((c) => _CuotaTile(
                      c: c,
                      trailing: FilledButton.icon(
                        onPressed: () => _marcarComoPagada(c),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marcar pagada'),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  Text('Historial de pagos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (pagadas.isEmpty) const Text('Sin pagos.'),
                  ...pagadas.map((c) => _CuotaTile(
                    c: c,
                    trailing: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Detalle'),
                            content: Text('Periodo: ${c.periodo ?? '-'}\n'
                                'Monto: ${c.monto ?? '-'} ${c.moneda ?? ''}\n'
                                'Estado: ${c.estado}'),
                            actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cerrar'))],
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Comprobante'),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}

class _CuotaTile extends StatelessWidget {
  final _Cuota c;
  final Widget trailing;
  const _CuotaTile({required this.c, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final venc = c.fechaVenc != null
        ? '${c.fechaVenc!.day.toString().padLeft(2, '0')}/${c.fechaVenc!.month.toString().padLeft(2, '0')}/${c.fechaVenc!.year}'
        : '--';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.request_page_outlined),
        title: Text('Cuota ${c.periodo ?? c.id} • ${c.monto ?? '-'} ${c.moneda ?? ''}'),
        subtitle: Text('Vence: $venc • Estado: ${c.estado ?? '-'}'),
        trailing: trailing,
        isThreeLine: true,
      ),
    );
  }
}

class _Cuota {
  final int id;
  final int unidadId;
  final String? periodo;
  final String? estado;
  final String? descripcion;
  final String? moneda;
  final double? monto;
  final DateTime? fechaVenc;

  _Cuota({
    required this.id,
    required this.unidadId,
    this.periodo,
    this.estado,
    this.descripcion,
    this.moneda,
    this.monto,
    this.fechaVenc,
  });

  factory _Cuota.fromJson(Map<String, dynamic> j) {
    double? _toD(v) => v == null ? null : double.tryParse(v.toString());
    DateTime? _toDate(v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return _Cuota(
      id: j['id'] as int,
      unidadId: j['unidad'] is int ? j['unidad'] as int : int.tryParse('${j['unidad'] ?? 0}') ?? 0,
      periodo: j['periodo'] as String?,
      estado: j['estado'] as String?,
      descripcion: j['descripcion'] as String?,
      moneda: 'BOB',
      monto: _toD(j['cantidad_pago']),
      fechaVenc: _toDate(j['fecha_vencimiento']),
    );
  }
}
