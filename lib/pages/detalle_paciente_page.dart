import 'package:flutter/material.dart';

import '../models/paciente.dart';
import '../tema.dart';
import '../util/formato.dart';
import '../widgets/dialogos.dart';
import '../widgets/etiqueta.dart';
import 'formulario_paciente_page.dart';

class DetallePacientePage extends StatefulWidget {
  final Paciente paciente;

  const DetallePacientePage({super.key, required this.paciente});

  @override
  State<DetallePacientePage> createState() => _DetallePacientePageState();
}

class _DetallePacientePageState extends State<DetallePacientePage> {
  late Paciente _p = widget.paciente;
  bool _cambio = false;
  bool _procesando = false;

  Future<void> _editar() async {
    final actualizado = await Navigator.push<Paciente>(
      context,
      MaterialPageRoute(builder: (_) => FormularioPacientePage(paciente: _p)),
    );
    if (actualizado != null) {
      setState(() {
        _p = actualizado;
        _cambio = true;
      });
    }
  }

  Future<void> _cambiarEstatus() async {
    setState(() => _procesando = true);
    final r = await cambiarEstatus(context, _p);
    if (!mounted) return;
    setState(() {
      _procesando = false;
      if (r != null) {
        _p = r;
        _cambio = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _cambio);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Paciente #${_p.idPaciente}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          actions: [
            if (_p.activo)
              IconButton(
                tooltip: 'Editar',
                onPressed: _editar,
                icon: Icon(Icons.edit_outlined, color: p.primario),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Avatar(_p.iniciales, tam: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_p.nombreCompleto, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _p.activo ? const Etiqueta('Activo') : const Etiqueta('Cancelado', cancelado: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.campo, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _Dato('IMC', _p.imc.toStringAsFixed(1), grande: true),
                  _Dato('Categoría', _p.categoriaImc),
                  _Dato('Peso', '${numero(_p.peso)} kg'),
                  _Dato('Altura', '${numero(_p.altura)} cm'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Fila(Icons.phone_outlined, 'Teléfono', _p.telefono),
            const Divider(),
            _Fila(Icons.place_outlined, 'Dirección', _p.direccion),
            const Divider(),
            _Fila(Icons.event_outlined, 'Registrado',
                _p.fechaRegistro == null ? 'Sin dato' : fecha(_p.fechaRegistro!)),
            const Divider(),
            _Fila(Icons.update, 'Última modificación',
                _p.fechaModificacion == null ? 'Sin cambios' : fecha(_p.fechaModificacion!)),
            const SizedBox(height: 32),
            _p.activo
                ? OutlinedButton(
                    onPressed: _procesando ? null : _cambiarEstatus,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.cancelado,
                      side: BorderSide(color: p.canceladoFondo, width: 1.5),
                    ),
                    child: const Text('Cancelar paciente'),
                  )
                : FilledButton(
                    onPressed: _procesando ? null : _cambiarEstatus,
                    child: const Text('Reactivar paciente'),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool grande;

  const _Dato(this.etiqueta, this.valor, {this.grande = false});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 12, color: p.secundario)),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                fontSize: grande ? 20 : 14,
                fontWeight: grande ? FontWeight.w700 : FontWeight.w600,
                color: grande ? p.primario : p.texto,
              )),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Fila(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: p.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: TextStyle(fontSize: 12, color: p.secundario)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
