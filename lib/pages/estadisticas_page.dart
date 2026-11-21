import 'package:flutter/material.dart';

import '../models/paciente.dart';
import '../tema.dart';
import '../widgets/etiqueta.dart';

class EstadisticasPage extends StatelessWidget {
  final List<Paciente> pacientes;

  const EstadisticasPage({super.key, required this.pacientes});

  double _promedio(Iterable<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final activos = pacientes.where((x) => x.activo).toList();
    final cancelados = pacientes.length - activos.length;
    final imcProm = _promedio(activos.map((x) => x.imc));
    final pesoProm = _promedio(activos.map((x) => x.peso));
    final alturaProm = _promedio(activos.map((x) => x.altura));
    final porCategoria = {
      for (final c in categoriasImc) c: activos.where((x) => x.categoriaImc == c).length,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              _Tarjeta(titulo: 'Total', valor: '${pacientes.length}'),
              const SizedBox(width: 10),
              _Tarjeta(titulo: 'Activos', valor: '${activos.length}'),
              const SizedBox(width: 10),
              _Tarjeta(titulo: 'Cancelados', valor: '$cancelados'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.campo, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IMC promedio (activos)', style: TextStyle(fontSize: 12, color: p.secundario)),
                      const SizedBox(height: 4),
                      Text(activos.isEmpty ? '--' : imcProm.toStringAsFixed(1),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: p.primario)),
                    ],
                  ),
                ),
                if (activos.isNotEmpty) Etiqueta(categoriaImc(imcProm)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Tarjeta(
                  titulo: 'Peso promedio', valor: activos.isEmpty ? '--' : '${pesoProm.toStringAsFixed(1)} kg'),
              const SizedBox(width: 10),
              _Tarjeta(
                  titulo: 'Altura promedio',
                  valor: activos.isEmpty ? '--' : '${alturaProm.toStringAsFixed(0)} cm'),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Activos por categoría de IMC',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          if (activos.isEmpty)
            Text('No hay pacientes activos.', style: TextStyle(color: p.secundario))
          else
            for (final c in categoriasImc)
              _Barra(etiqueta: c, cantidad: porCategoria[c]!, total: activos.length),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Tarjeta({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: p.borde),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.secundario)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final String etiqueta;
  final int cantidad;
  final int total;

  const _Barra({required this.etiqueta, required this.cantidad, required this.total});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final frac = total == 0 ? 0.0 : cantidad / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 14))),
              Text('$cantidad · ${(frac * 100).round()}%',
                  style: TextStyle(fontSize: 13, color: p.secundario)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: p.campo),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(height: 10, color: p.primario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
