import 'package:flutter/material.dart';

import 'pages/lista_pacientes_page.dart';
import 'tema.dart';

void main() {
  runApp(const AppPacientes());
}

class AppPacientes extends StatelessWidget {
  const AppPacientes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pacientes',
      debugShowCheckedModeBanner: false,
      theme: crearTema(),
      home: const ListaPacientesPage(),
    );
  }
}
