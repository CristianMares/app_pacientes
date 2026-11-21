import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/paciente.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../widgets/etiqueta.dart';

class FormularioPacientePage extends StatefulWidget {
  // Si viene un paciente se edita, si no se crea uno nuevo
  final Paciente? paciente;

  const FormularioPacientePage({super.key, this.paciente});

  @override
  State<FormularioPacientePage> createState() => _FormularioPacientePageState();
}

class _FormularioPacientePageState extends State<FormularioPacientePage> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.paciente?.nombre ?? '');
  late final _aPaterno = TextEditingController(text: widget.paciente?.aPaterno ?? '');
  late final _aMaterno = TextEditingController(text: widget.paciente?.aMaterno ?? '');
  late final _direccion = TextEditingController(text: widget.paciente?.direccion ?? '');
  late final _telefono = TextEditingController(text: widget.paciente?.telefono ?? '');
  late final _peso = TextEditingController(text: _n(widget.paciente?.peso));
  late final _altura = TextEditingController(text: _n(widget.paciente?.altura));
  bool _guardando = false;

  bool get _editando => widget.paciente != null;

  static String _n(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _aPaterno, _aMaterno, _direccion, _telefono, _peso, _altura]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _decimal(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final p = Paciente(
      // Al crear la API asigna el Id
      idPaciente: widget.paciente?.idPaciente ?? 0,
      nombre: _nombre.text.trim(),
      aPaterno: _aPaterno.text.trim(),
      aMaterno: _aMaterno.text.trim(),
      direccion: _direccion.text.trim(),
      telefono: _telefono.text.trim(),
      peso: _decimal(_peso.text)!,
      altura: _decimal(_altura.text)!,
      estatus: widget.paciente?.estatus ?? 'A',
    );

    final duplicado = await ApiService.buscarDuplicado(p);
    if (!mounted) return;
    if (duplicado != null && !await _confirmarDuplicado(duplicado)) {
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      final guardado = _editando ? await ApiService.editar(p) : await ApiService.crear(p);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editando ? 'Cambios guardados' : 'Paciente registrado')));
      // Al editar se regresa el paciente para refrescar el detalle
      Navigator.pop(context, _editando ? guardado : true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _confirmarDuplicado(Paciente d) async {
    final pal = context.paleta;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Posible duplicado'),
        content: Text('Ya existe el paciente #${d.idPaciente} ${d.nombreCompleto} '
            'con el mismo teléfono${d.activo ? '' : ' (cancelado)'}. ¿Guardar de todos modos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: pal.secundario),
            child: const Text('Revisar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar paciente' : 'Nuevo paciente',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _Seccion('Datos personales'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _aPaterno,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Apellido paterno'),
                    validator: _requerido,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _aMaterno,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Apellido materno'),
                  ),
                ),
              ],
            ),
            _Seccion('Contacto'),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(labelText: 'Teléfono (10 dígitos)'),
              validator: (v) =>
                  (v == null || v.trim().length != 10) ? 'Debe tener 10 dígitos' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccion,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: _requerido,
            ),
            _Seccion('Medidas'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _peso,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
                    validator: (v) {
                      final n = _decimal(v ?? '');
                      if (n == null) return 'Número inválido';
                      if (n < 1 || n > 500) return 'Entre 1 y 500';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _altura,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm'),
                    validator: (v) {
                      final n = _decimal(v ?? '');
                      if (n == null) return 'Número inválido';
                      if (n < 30 || n > 280) return 'Entre 30 y 280';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _VistaImc(peso: _decimal(_peso.text) ?? 0, altura: _decimal(_altura.text) ?? 0),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_editando ? 'Guardar cambios' : 'Registrar paciente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String texto;
  const _Seccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(texto,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: context.paleta.secundario)),
    );
  }
}

class _VistaImc extends StatelessWidget {
  final double peso;
  final double altura;

  const _VistaImc({required this.peso, required this.altura});

  @override
  Widget build(BuildContext context) {
    final r = calcularImc(peso, altura);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: context.paleta.borde),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('IMC', style: TextStyle(color: context.paleta.secundario)),
          const SizedBox(width: 12),
          Text(r.imc > 0 ? r.imc.toStringAsFixed(1) : '--',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (r.categoria.isNotEmpty) Etiqueta(r.categoria),
        ],
      ),
    );
  }
}
