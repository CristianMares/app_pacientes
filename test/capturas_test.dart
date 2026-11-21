// Genera capturas de las pantallas en tema claro y oscuro.
// Solo corre en CI con CAPTURAS=1 y FUENTES=<carpeta con Inter-*.ttf>
import 'dart:convert';
import 'dart:io';

import 'package:app_pacientes/models/paciente.dart';
import 'package:app_pacientes/pages/detalle_paciente_page.dart';
import 'package:app_pacientes/pages/estadisticas_page.dart';
import 'package:app_pacientes/pages/formulario_paciente_page.dart';
import 'package:app_pacientes/pages/lista_pacientes_page.dart';
import 'package:app_pacientes/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _activa = Platform.environment['CAPTURAS'] == '1';

final _datos = [
  {'idPaciente': 1, 'nombre': 'María Fernanda', 'aPaterno': 'López', 'aMaterno': 'Ruiz', 'direccion': 'Av. Juárez 120, Centro', 'telefono': '5512345678', 'peso': 62, 'altura': 165, 'estatus': 'A', 'imc': 22.8, 'categoriaImc': 'Normal', 'fechaRegistro': '2026-11-14T16:03:00Z', 'fechaModificacion': '2026-11-20T18:30:00Z'},
  {'idPaciente': 2, 'nombre': 'José Luis', 'aPaterno': 'Hernández', 'aMaterno': 'Soto', 'direccion': 'Calle 5 de Mayo 33', 'telefono': '5598765432', 'peso': 91, 'altura': 172, 'estatus': 'A', 'imc': 30.8, 'categoriaImc': 'Obesidad', 'fechaRegistro': '2026-11-15T17:10:00Z', 'fechaModificacion': null},
  {'idPaciente': 3, 'nombre': 'Ana Karen', 'aPaterno': 'Martínez', 'aMaterno': 'Díaz', 'direccion': 'Privada Olivo 8', 'telefono': '5511223344', 'peso': 48, 'altura': 168, 'estatus': 'C', 'imc': 17.0, 'categoriaImc': 'Bajo peso', 'fechaRegistro': null, 'fechaModificacion': null},
  {'idPaciente': 4, 'nombre': 'Ricardo', 'aPaterno': 'Gómez', 'aMaterno': 'Vega', 'direccion': 'Blvd. Hidalgo 450', 'telefono': '5566778899', 'peso': 80, 'altura': 178, 'estatus': 'A', 'imc': 25.2, 'categoriaImc': 'Sobrepeso', 'fechaRegistro': '2026-11-18T15:00:00Z', 'fechaModificacion': null},
];

List<Paciente> get _pacientes => _datos.map(Paciente.fromJson).toList();

Future<void> _cargarFuentes() async {
  final dir = Directory(Platform.environment['FUENTES']!);
  final inter = FontLoader('Inter');
  for (final f in dir.listSync().whereType<File>()) {
    if (RegExp(r'Inter-(Regular|Medium|SemiBold|Bold)\.ttf$').hasMatch(f.path)) {
      inter.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await inter.load();

  final iconos = FontLoader('MaterialIcons');
  final ruta = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  iconos.addFont(Future.value(ByteData.view(File(ruta).readAsBytesSync().buffer)));
  await iconos.load();
}

Future<void> _capturar(WidgetTester tester, String nombre, Widget pantalla, Brightness brillo,
    {Future<void> Function()? antes}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: crearTema(brillo, fuentesGoogle: false),
    home: pantalla,
  ));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Las imágenes se decodifican fuera del tiempo simulado
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();

  if (antes != null) {
    await antes();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final tema = brillo == Brightness.dark ? 'oscuro' : 'claro';
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('capturas/${nombre}_$tema.png'));
}

void main() {
  setUpAll(() async {
    if (_activa) await _cargarFuentes();
  });

  for (final brillo in Brightness.values) {
    testWidgets('lista $brillo', skip: !_activa, (tester) async {
      // Sin red en pruebas: la lista sale de la copia guardada
      SharedPreferences.setMockInitialValues({
        'cache_pacientes': jsonEncode(_datos),
        'cache_fecha': '2026-11-21T08:40:00',
      });
      await _capturar(tester, '1_lista', const ListaPacientesPage(), brillo);
    });

    testWidgets('detalle $brillo', skip: !_activa, (tester) async {
      await _capturar(tester, '2_detalle', DetallePacientePage(paciente: _pacientes[0]), brillo);
    });

    testWidgets('confirmar $brillo', skip: !_activa, (tester) async {
      await _capturar(tester, '3_confirmar', DetallePacientePage(paciente: _pacientes[0]), brillo,
          antes: () => tester.tap(find.text('Cancelar paciente')));
    });

    testWidgets('formulario $brillo', skip: !_activa, (tester) async {
      await _capturar(tester, '4_formulario', FormularioPacientePage(paciente: _pacientes[3]), brillo);
    });

    testWidgets('estadisticas $brillo', skip: !_activa, (tester) async {
      await _capturar(tester, '5_estadisticas', EstadisticasPage(pacientes: _pacientes), brillo);
    });
  }
}
