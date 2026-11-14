import 'dart:async';

import 'package:flutter/material.dart';

import '../models/paciente.dart';
import '../services/api_service.dart';
import '../services/exportar_service.dart';
import '../tema.dart';
import '../widgets/etiqueta.dart';
import 'configuracion_page.dart';
import 'detalle_paciente_page.dart';
import 'formulario_paciente_page.dart';

enum Filtro { todos, activos, cancelados }

class ListaPacientesPage extends StatefulWidget {
  const ListaPacientesPage({super.key});

  @override
  State<ListaPacientesPage> createState() => _ListaPacientesPageState();
}

class _ListaPacientesPageState extends State<ListaPacientesPage> {
  final _buscar = TextEditingController();
  Timer? _espera;
  Filtro _filtro = Filtro.todos;
  List<Paciente> _pacientes = [];
  bool _cargando = true;
  String? _error;

  // Totales sin filtrar para el encabezado
  int _total = 0;
  int _activos = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final estatus = switch (_filtro) {
        Filtro.activos => 'A',
        Filtro.cancelados => 'C',
        Filtro.todos => null,
      };
      final resultados = await Future.wait([
        ApiService.listar(buscar: _buscar.text, estatus: estatus),
        ApiService.listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _pacientes = resultados[0];
        _total = resultados[1].length;
        _activos = resultados[1].where((p) => p.activo).length;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _alEscribir(String _) {
    setState(() {});
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), _cargar);
  }

  void _cambiarFiltro(Filtro f) {
    if (f == _filtro) return;
    setState(() => _filtro = f);
    _cargar();
  }

  Future<void> _abrir(Widget pagina) async {
    final cambio = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => pagina));
    if (cambio == true) _cargar();
  }

  Future<void> _exportar() async {
    if (_pacientes.isEmpty) {
      _aviso('No hay pacientes para exportar');
      return;
    }
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exportar lista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Se exportan los ${_pacientes.length} pacientes que ves en pantalla',
                  style: const TextStyle(color: Colores.secundario, fontSize: 13)),
              const SizedBox(height: 16),
              _OpcionExportar(
                icono: Icons.picture_as_pdf_outlined,
                titulo: 'PDF',
                detalle: 'Tabla lista para imprimir o enviar',
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              _OpcionExportar(
                icono: Icons.table_chart_outlined,
                titulo: 'CSV',
                detalle: 'Para abrir en Excel u hojas de cálculo',
                onTap: () => Navigator.pop(context, 'csv'),
              ),
            ],
          ),
        ),
      ),
    );
    if (opcion == null) return;

    try {
      if (opcion == 'pdf') {
        await ExportarService.pdf(_pacientes);
      } else {
        await ExportarService.csv(_pacientes);
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pacientes',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('$_total registrados · $_activos activos',
                            style: const TextStyle(fontSize: 13, color: Colores.secundario)),
                      ],
                    ),
                  ),
                  _BotonIcono(icono: Icons.file_download_outlined, tooltip: 'Exportar', onTap: _exportar),
                  const SizedBox(width: 8),
                  _BotonIcono(
                    icono: Icons.settings_outlined,
                    tooltip: 'Configurar API',
                    onTap: () => _abrir(const ConfiguracionPage()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _buscar,
                onChanged: _alEscribir,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o apellido',
                  prefixIcon: const Icon(Icons.search, color: Colores.secundario, size: 20),
                  suffixIcon: _buscar.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _buscar.clear();
                            _cargar();
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Chip('Todos', _filtro == Filtro.todos, () => _cambiarFiltro(Filtro.todos)),
                  const SizedBox(width: 8),
                  _Chip('Activos', _filtro == Filtro.activos, () => _cambiarFiltro(Filtro.activos)),
                  const SizedBox(width: 8),
                  _Chip('Cancelados', _filtro == Filtro.cancelados,
                      () => _cambiarFiltro(Filtro.cancelados)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _contenido()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(const FormularioPacientePage()),
        backgroundColor: Colores.primario,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paciente', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _pacientes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colores.primario));
    }
    if (_error != null) {
      return _Mensaje(
        titulo: 'Sin conexión',
        detalle: _error!,
        accion: 'Reintentar',
        onAccion: _cargar,
        accion2: 'Configurar API',
        onAccion2: () => _abrir(const ConfiguracionPage()),
      );
    }
    if (_pacientes.isEmpty) {
      return _Mensaje(
        titulo: _buscar.text.isEmpty ? 'Aún no hay pacientes' : 'Sin resultados',
        detalle: _buscar.text.isEmpty
            ? 'Registra el primero con el botón Nuevo paciente.'
            : 'No hay pacientes que coincidan con "${_buscar.text}".',
      );
    }

    return RefreshIndicator(
      color: Colores.primario,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _pacientes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final p = _pacientes[i];
          return InkWell(
            onTap: () => _abrir(DetallePacientePage(paciente: p)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Avatar(p.iniciales),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombreCompleto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                          '#${p.idPaciente} · ${_n(p.peso)} kg · ${_n(p.altura)} cm',
                          style: const TextStyle(fontSize: 13, color: Colores.secundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(p.imc.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      p.activo
                          ? Etiqueta(p.categoriaImc)
                          : const Etiqueta('Cancelado', cancelado: true),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _Chip(this.texto, this.activo, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo ? Colores.primario : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: activo ? Colores.primario : Colores.borde)),
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
              color: activo ? Colors.white : Colores.texto,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonIcono extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const _BotonIcono({required this.icono, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colores.borde),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icono, color: Colores.primario, size: 20)),
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

  const _OpcionExportar({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colores.suave, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: Colores.primario),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detalle, style: const TextStyle(color: Colores.secundario, fontSize: 13)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(detalle,
                textAlign: TextAlign.center, style: const TextStyle(color: Colores.secundario)),
            if (accion != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: FilledButton(onPressed: onAccion, child: Text(accion!)),
              ),
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
