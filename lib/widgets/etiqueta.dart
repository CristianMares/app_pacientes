import 'package:flutter/material.dart';

import '../tema.dart';

class Etiqueta extends StatelessWidget {
  final String texto;
  final bool cancelado;

  const Etiqueta(this.texto, {super.key, this.cancelado = false});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cancelado ? p.canceladoFondo : p.suave,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: cancelado ? p.cancelado : p.primario,
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
    final p = context.paleta;
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.suave, shape: BoxShape.circle),
      child: Text(
        iniciales,
        style: TextStyle(color: p.primario, fontWeight: FontWeight.w600, fontSize: tam * 0.34),
      ),
    );
  }
}

// En tema oscuro el logo va sobre una tarjeta blanca para que se lea
class Logo extends StatelessWidget {
  final double alto;

  const Logo({super.key, this.alto = 48});

  @override
  Widget build(BuildContext context) {
    final img = Image.asset('assets/logo.png', height: alto);
    if (!context.paleta.oscuro) return img;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Image.asset('assets/logo.png', height: alto - 8),
    );
  }
}

class BotonIcono extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const BotonIcono({super.key, required this.icono, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: p.borde),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icono, color: p.primario, size: 20)),
        ),
      ),
    );
  }
}
