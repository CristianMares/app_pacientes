import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/paciente.dart';
import '../services/api_service.dart';
import '../services/exportar_service.dart';
import '../tema.dart';
import '../util/formato.dart';
import '../widgets/dialogos.dart';
import '../widgets/etiqueta.dart';
import 'configuracion_page.dart';
import 'detalle_paciente_page.dart';
import 'estadisticas_page.dart';
import 'formulario_paciente_page.dart';

enum Filtro { todos, activos, cancelados }

enum Orden {
  id('Id'),
  nombre('Nombre (A-Z)'),
  imcMayor('IMC mayor a menor'),
  imcMenor('IMC menor a mayor'),
  recientes('Más recientes');

  final String texto;
  const Orden(this.texto);
}

class ListaPacientesPage extends StatefulWidget {
  const ListaPacientesPage({super.key});

  @override
  State<ListaPacientesPage> createState() => _ListaPacientesPageState();
}

class _ListaPacientesPageState extends State<ListaPacientesPage> {
  final _buscar = TextEditingController();
  Filtro _filtro = Filtro.todos;
  Orden _orden = Orden.id;
  List<Paciente> _todos = [];
  bool _cargando = true;
  bool _sinConexion = false;
  DateTime? _fechaCopia;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await ApiService.listarTodos();
      if (!mounted) return;
      setState(() {
        _todos = r.pacientes;
        _sinConexion = r.desdeCache;
        _fechaCopia = r.fechaCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Filtro, búsqueda y orden se aplican en el teléfono
  List<Paciente> get _visibles {
    final texto = normalizar(_buscar.text);
    final lista = _todos.where((p) {
      if (_filtro == Filtro.activos && !p.activo) return false;
      if (_filtro == Filtro.cancelados && p.activo) return false;
      return texto.isEmpty || normalizar(p.nombreCompleto).contains(texto);
    }).toList();

    int porId(Paciente a, Paciente b) => a.idPaciente.compareTo(b.idPaciente);
    switch (_orden) {
      case Orden.id:
        lista.sort(porId);
      case Orden.nombre:
        lista.sort((a, b) => normalizar(a.nombreCompleto).compareTo(normalizar(b.nombreCompleto)));
      case Orden.imcMayor:
        lista.sort((a, b) => b.imc.compareTo(a.imc));
      case Orden.imcMenor:
        lista.sort((a, b) => a.imc.compareTo(b.imc));
      case Orden.recientes:
        lista.sort((a, b) {
          final fa = a.fechaRegistro, fb = b.fechaRegistro;
          if (fa == null && fb == null) return porId(b, a);
          if (fa == null) return 1;
          if (fb == null) return -1;
          return fb.compareTo(fa);
        });
    }
    return lista;
  }

  Future<void> _abrir(Widget pagina) async {
    final cambio = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => pagina));
    if (cambio == true) _cargar();
  }

  Future<void> _deslizar(Paciente p) async {
    final r = await cambiarEstatus(context, p);
    if (r != null) _cargar();
  }

  Future<void> _exportar() async {
    final lista = _visibles;
    if (lista.isEmpty) {
      _aviso('No hay pacientes para exportar');
      return;
    }
    final opcion = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final p = ctx.paleta;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exportar lista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Se exportan los ${lista.length} pacientes que ves en pantalla',
                    style: TextStyle(color: p.secundario, fontSize: 13)),
                const SizedBox(height: 16),
                _OpcionExportar(
                  icono: Icons.picture_as_pdf_outlined,
                  titulo: 'PDF',
                  detalle: 'Tabla lista para imprimir o enviar',
                  onTap: () => Navigator.pop(ctx, 'pdf'),
                ),
                _OpcionExportar(
                  icono: Icons.table_chart_outlined,
                  titulo: 'CSV',
                  detalle: 'Para abrir en Excel u hojas de cálculo',
                  onTap: () => Navigator.pop(ctx, 'csv'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (opcion == null) return;

    try {
      if (opcion == 'pdf') {
        await ExportarService.pdf(lista);
      } else {
        await ExportarService.csv(lista);
      }
    } catch (_) {
      _aviso('No se pudo generar el archivo');
    }
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final activos = _todos.where((x) => x.activo).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Logo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pacientes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${_todos.length} registrados · $activos activos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: p.secundario),
                        ),
                      ],
                    ),
                  ),
                  BotonIcono(
                    icono: Icons.insights_outlined,
                    tooltip: 'Estadísticas',
                    onTap: () => _abrir(EstadisticasPage(pacientes: _todos)),
                  ),
                  const SizedBox(width: 8),
                  _Menu(
                    onExportar: _exportar,
                    onConfigurar: () => _abrir(const ConfiguracionPage()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _buscar,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o apellido',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _buscar.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(_buscar.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Chip('Todos', _filtro == Filtro.todos, () => setState(() => _filtro = Filtro.todos)),
                          const SizedBox(width: 8),
                          _Chip('Activos', _filtro == Filtro.activos,
                              () => setState(() => _filtro = Filtro.activos)),
                          const SizedBox(width: 8),
                          _Chip('Cancelados', _filtro == Filtro.cancelados,
                              () => setState(() => _filtro = Filtro.cancelados)),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<Orden>(
                    tooltip: 'Ordenar',
                    initialValue: _orden,
                    onSelected: (o) => setState(() => _orden = o),
                    icon: Icon(Icons.swap_vert, color: p.primario),
                    itemBuilder: (_) => [
                      for (final o in Orden.values)
                        CheckedPopupMenuItem(value: o, checked: o == _orden, child: Text(o.texto)),
                    ],
                  ),
                ],
              ),
            ),
            if (_sinConexion) _AvisoSinConexion(cuando: _fechaCopia, onReintentar: _cargar),
            const SizedBox(height: 4),
            Expanded(child: _contenido()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(const FormularioPacientePage()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paciente', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      ),
    );
  }

  Widget _contenido() {
    final p = context.paleta;
    if (_cargando && _todos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _todos.isEmpty) {
      return _Mensaje(
        titulo: 'Sin conexión',
        detalle: _error!,
        accion: 'Reintentar',
        onAccion: _cargar,
        accion2: 'Configurar API',
        onAccion2: () => _abrir(const ConfiguracionPage()),
      );
    }

    final lista = _visibles;
    if (lista.isEmpty) {
      return RefreshIndicator(
        color: p.primario,
        backgroundColor: p.superficie,
        onRefresh: _cargar,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            _Mensaje(
              titulo: _todos.isEmpty ? 'Aún no hay pacientes' : 'Sin resultados',
              detalle: _todos.isEmpty
                  ? 'Registra el primero con el botón Nuevo paciente.'
                  : 'No hay pacientes que coincidan con la búsqueda o el filtro.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: p.primario,
      backgroundColor: p.superficie,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: lista.length + 1,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          if (i == lista.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Desliza un paciente a la izquierda para cancelarlo o reactivarlo',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.secundario)),
            );
          }
          final x = lista[i];
          return _FilaPaciente(
            paciente: x,
            onTap: () => _abrir(DetallePacientePage(paciente: x)),
            onDeslizar: () => _deslizar(x),
          );
        },
      ),
    );
  }
}

class _FilaPaciente extends StatelessWidget {
  final Paciente paciente;
  final VoidCallback onTap;
  final Future<void> Function() onDeslizar;

  const _FilaPaciente({required this.paciente, required this.onTap, required this.onDeslizar});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final x = paciente;
    final fondo = x.activo ? p.canceladoFondo : p.suave;
    final color = x.activo ? p.cancelado : p.primario;

    return Dismissible(
      key: ValueKey('${x.idPaciente}-${x.estatus}'),
      direction: DismissDirection.endToStart,
      // No se quita de la lista: se confirma, se cambia el estatus y se recarga
      confirmDismiss: (_) async {
        await onDeslizar();
        return false;
      },
      background: Container(
        color: fondo,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(x.activo ? Icons.block : Icons.restart_alt, color: color, size: 20),
            const SizedBox(width: 8),
            Text(x.activo ? 'Cancelar' : 'Reactivar',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Material(
        color: p.fondo,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Avatar(x.iniciales),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(x.nombreCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        '#${x.idPaciente} · ${numero(x.peso)} kg · ${numero(x.altura)} cm',
                        style: TextStyle(fontSize: 13, color: p.secundario),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(x.imc.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    x.activo ? Etiqueta(x.categoriaImc) : const Etiqueta('Cancelado', cancelado: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final VoidCallback onExportar;
  final VoidCallback onConfigurar;

  const _Menu({required this.onExportar, required this.onConfigurar});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Material(
      color: p.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: p.borde)),
      child: SizedBox(
        width: 44,
        height: 44,
        child: PopupMenuButton<int>(
          tooltip: 'Más opciones',
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert, color: p.primario, size: 20),
          onSelected: (v) => v == 0 ? onExportar() : onConfigurar(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 0,
              child: Row(children: [
                Icon(Icons.file_download_outlined, color: p.primario, size: 20),
                const SizedBox(width: 12),
                const Text('Exportar'),
              ]),
            ),
            PopupMenuItem(
              value: 1,
              child: Row(children: [
                Icon(Icons.settings_outlined, color: p.primario, size: 20),
                const SizedBox(width: 12),
                const Text('Configurar API'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoSinConexion extends StatelessWidget {
  final DateTime? cuando;
  final VoidCallback onReintentar;

  const _AvisoSinConexion({required this.cuando, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(color: p.campo, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: p.secundario),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cuando == null ? 'Sin conexión · datos guardados' : 'Sin conexión · datos del ${fecha(cuando!)}',
              style: TextStyle(fontSize: 13, color: p.texto),
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _Chip(this.texto, this.activo, this.onTap);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Material(
      color: activo ? p.primario : p.superficie,
      shape: StadiumBorder(side: BorderSide(color: activo ? p.primario : p.borde)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
              color: activo ? p.sobrePrimario : p.texto,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionExportar extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _OpcionExportar({required this.icono, required this.titulo, required this.detalle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: p.suave, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: p.primario),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detalle, style: TextStyle(color: p.secundario, fontSize: 13)),
      onTap: onTap,
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String titulo;
  final String detalle;
  final String? accion;
  final VoidCallback? onAccion;
  final String? accion2;
  final VoidCallback? onAccion2;

  const _Mensaje({
    required this.titulo,
    required this.detalle,
    this.accion,
    this.onAccion,
    this.accion2,
    this.onAccion2,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(detalle, textAlign: TextAlign.center, style: TextStyle(color: p.secundario)),
            if (accion != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 200, child: FilledButton(onPressed: onAccion, child: Text(accion!))),
            ],
            if (accion2 != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAccion2, child: Text(accion2!)),
            ],
          ],
        ),
      ),
    );
  }
}
