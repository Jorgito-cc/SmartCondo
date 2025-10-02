import 'package:flutter/material.dart';

class ComunidadPage extends StatefulWidget {
  const ComunidadPage({super.key});
  @override
  State<ComunidadPage> createState() => _ComunidadPageState();
}

class _ComunidadPageState extends State<ComunidadPage> {
  final List<_Post> _posts = [
    _Post(
      autor: 'María López',
      rol: 'Residente',
      titulo: 'Mallas del parque rotas',
      contenido: 'En el parque norte, el cercado está roto y es peligroso para los niños.',
      categoria: 'Mantenimiento',
      estado: 'ABIERTO',
      hora: DateTime.now().subtract(const Duration(minutes: 14)),
      imagenUrl: 'https://via.placeholder.com/800x450.png?text=Parque',
      votos: 5,
      comentarios: [
        _Comentario(usuario: 'Guardia Carlos', rol: 'Guardia', texto: 'Recibido, informo a mantenimiento.', hora: DateTime.now().subtract(const Duration(minutes: 8))),
        _Comentario(usuario: 'Ana Ruiz', rol: 'Residente', texto: 'Gracias por avisar 🙌', hora: DateTime.now().subtract(const Duration(minutes: 5))),
      ],
    ),
    _Post(
      autor: 'Jorge Méndez',
      rol: 'Residente',
      titulo: 'Luz fundida en pasillo Torre B',
      contenido: 'El foco del 3er piso no enciende por las noches.',
      categoria: 'Mantenimiento',
      estado: 'EN PROGRESO',
      hora: DateTime.now().subtract(const Duration(hours: 2)),
      votos: 2,
    ),
  ];

  void _nuevoPost() async {
    final nuevo = await Navigator.push<_Post>(
      context,
      MaterialPageRoute(builder: (_) => const CrearPostPage()),
    );
    if (nuevo != null) {
      setState(() => _posts.insert(0, nuevo));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación creada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoPost, icon: const Icon(Icons.add_comment), label: const Text('Nuevo'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = _posts[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final updated = await Navigator.push<_Post>(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetallePage(post: p)),
                );
                if (updated != null) setState(() => _posts[i] = updated);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (p.imagenUrl != null)
                    AspectRatio(
                      aspectRatio: 16/9,
                      child: Image.network(p.imagenUrl!, fit: BoxFit.cover),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(child: Text(p.autor.characters.first)),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${p.autor} • ${p.rol}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(_fmtHora(p.hora), style: Theme.of(context).textTheme.bodySmall),
                        ]),
                        const SizedBox(height: 8),
                        Text(p.titulo, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(p.contenido, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          Chip(label: Text(p.categoria)),
                          Chip(
                            label: Text(p.estado),
                            backgroundColor: switch (p.estado) {
                              'ABIERTO' => Colors.orange.shade100,
                              'EN PROGRESO' => Colors.blue.shade100,
                              _ => Colors.green.shade100,
                            },
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () => setState(() => p.votos++),
                            ),
                            Text('${p.votos}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.mode_comment_outlined, size: 20),
                            const SizedBox(width: 4),
                            Text('${p.comentarios.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class PostDetallePage extends StatefulWidget {
  final _Post post;
  const PostDetallePage({super.key, required this.post});
  @override
  State<PostDetallePage> createState() => _PostDetallePageState();
}

class _PostDetallePageState extends State<PostDetallePage> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (p.imagenUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(p.imagenUrl!, height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Text(p.titulo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  Chip(label: Text(p.categoria)),
                  Chip(label: Text(p.estado)),
                ]),
                const SizedBox(height: 8),
                Text(p.contenido),
                const SizedBox(height: 16),
                const Divider(),
                Text('Comentarios', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...p.comentarios.map((c) => ListTile(
                      leading: CircleAvatar(child: Text(c.usuario.characters.first)),
                      title: Text('${c.usuario} • ${c.rol}'),
                      subtitle: Text(c.texto),
                      trailing: Text(_fmtHora(c.hora)),
                    )),
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_ctrl.text.trim().isEmpty) return;
                      setState(() {
                        p.comentarios.add(
                          _Comentario(
                            usuario: 'Tú',
                            rol: 'Residente',
                            texto: _ctrl.text.trim(),
                            hora: DateTime.now(),
                          ),
                        );
                        _ctrl.clear();
                      });
                    },
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class CrearPostPage extends StatefulWidget {
  const CrearPostPage({super.key});
  @override
  State<CrearPostPage> createState() => _CrearPostPageState();
}

class _CrearPostPageState extends State<CrearPostPage> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _contenido = TextEditingController();
  String _categoria = 'Mantenimiento';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo feedback')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _categoria,
              items: const [
                DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                DropdownMenuItem(value: 'Seguridad', child: Text('Seguridad')),
                DropdownMenuItem(value: 'Convivencia', child: Text('Convivencia')),
                DropdownMenuItem(value: 'Sugerencia', child: Text('Sugerencia')),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? 'Mantenimiento'),
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contenido,
              minLines: 3, maxLines: 6,
              decoration: const InputDecoration(labelText: 'Describe el problema/sugerencia'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final nuevo = _Post(
                  autor: 'Tú',
                  rol: 'Residente',
                  titulo: _titulo.text.trim(),
                  contenido: _contenido.text.trim(),
                  categoria: _categoria,
                  estado: 'ABIERTO',
                  hora: DateTime.now(),
                );
                Navigator.pop(context, nuevo);
              },
              icon: const Icon(Icons.send),
              label: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== modelos simples (mock) ======
class _Post {
  final String autor, rol, titulo, contenido, categoria;
  String estado;
  final DateTime hora;
  final String? imagenUrl;
  int votos;
  final List<_Comentario> comentarios;

  _Post({
    required this.autor,
    required this.rol,
    required this.titulo,
    required this.contenido,
    required this.categoria,
    required this.estado,
    required this.hora,
    this.imagenUrl,
    this.votos = 0,
    List<_Comentario>? comentarios,
  }) : comentarios = comentarios ?? [];
}

class _Comentario {
  final String usuario, rol, texto;
  final DateTime hora;
  _Comentario({required this.usuario, required this.rol, required this.texto, required this.hora});
}
