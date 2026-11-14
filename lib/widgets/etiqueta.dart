import 'package:flutter/material.dart';

import '../tema.dart';

class Etiqueta extends StatelessWidget {
  final String texto;
  final bool cancelado;

  const Etiqueta(this.texto, {super.key, this.cancelado = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cancelado ? Colores.canceladoFondo : Colores.suave,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: cancelado ? Colores.cancelado : Colores.primario,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String iniciales;
  final double tam;

  const Avatar(this.iniciales, {super.key, this.tam = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colores.suave, shape: BoxShape.circle),
      child: Text(
        iniciales,
        style: TextStyle(
          color: Colores.primario,
          fontWeight: FontWeight.w600,
          fontSize: tam * 0.34,
        ),
      ),
    );
  }
}
