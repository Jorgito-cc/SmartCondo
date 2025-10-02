import 'package:flutter/material.dart';

class CostosPage extends StatefulWidget {
  const CostosPage({super.key});
  @override
  State<CostosPage> createState() => _CostosPageState();
}

class _CostosPageState extends State<CostosPage> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _monto = TextEditingController();

  final List<_Costo> _historial = [
    _Costo('Repuesto luminaria', 45.5, DateTime.now().subtract(const Duration(days: 1))),
    _Costo('Pintura baranda', 120, DateTime.now().subtract(const Duration(days: 3))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costos y reparaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Registrar costo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _monto,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto (Bs.)'),
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Monto inválido' : null,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    setState(() {
                      _historial.insert(0, _Costo(_desc.text.trim(),
                          double.parse(_monto.text), DateTime.now()));
                      _desc.clear(); _monto.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Costo registrado (mock)')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Guardar costo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Historial', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._historial.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(c.descripcion),
                  subtitle: Text(_fmt(c.fecha)),
                  trailing: Text('Bs. ${c.monto.toStringAsFixed(2)}'),
                ),
              )),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Costo {
  final String descripcion;
  final double monto;
  final DateTime fecha;
  _Costo(this.descripcion, this.monto, this.fecha);
}
