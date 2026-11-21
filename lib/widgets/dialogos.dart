import 'package:flutter/material.dart';

import '../models/paciente.dart';
import '../services/api_service.dart';
import '../tema.dart';

// Confirma y cambia el estatus. Regresa el paciente actualizado o null.
Future<Paciente?> cambiarEstatus(BuildContext context, Paciente p) async {
  final cancelar = p.activo;
  final paleta = context.paleta;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(cancelar ? 'Cancelar paciente' : 'Reactivar paciente'),
      content: Text(cancelar
          ? '${p.nombreCompleto} quedará como cancelado. Podrás reactivarlo después.'
          : '${p.nombreCompleto} volverá a estar activo.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(foregroundColor: paleta.secundario),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
              foregroundColor: cancelar ? paleta.cancelado : paleta.primario),
          child: Text(cancelar ? 'Sí, cancelar' : 'Sí, reactivar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;

  try {
    final r = cancelar ? await ApiService.cancelar(p.idPaciente) : await ApiService.reactivar(p.idPaciente);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cancelar ? 'Paciente cancelado' : 'Paciente reactivado')));
    }
    return r;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
    return null;
  }
}
