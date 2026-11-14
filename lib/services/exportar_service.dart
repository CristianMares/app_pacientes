import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/paciente.dart';

class ExportarService {
  static const _columnas = [
    'Id', 'Nombre', 'A. Paterno', 'A. Materno', 'Dirección', 'Teléfono',
    'Peso (kg)', 'Altura (cm)', 'IMC', 'Categoría', 'Estatus'
  ];

  static List<String> _fila(Paciente p) => [
        '${p.idPaciente}', p.nombre, p.aPaterno, p.aMaterno, p.direccion, p.telefono,
        _num(p.peso), _num(p.altura), p.imc.toStringAsFixed(1), p.categoriaImc,
        p.activo ? 'Activo' : 'Cancelado',
      ];

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static String _fecha() {
    final n = DateTime.now();
    String d(int x) => x.toString().padLeft(2, '0');
    return '${n.year}${d(n.month)}${d(n.day)}_${d(n.hour)}${d(n.minute)}';
  }

  static Future<void> csv(List<Paciente> pacientes) async {
    String celda(String v) => '"${v.replaceAll('"', '""')}"';
    final lineas = [
      _columnas.map(celda).join(','),
      ...pacientes.map((p) => _fila(p).map(celda).join(',')),
    ];

    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/pacientes_${_fecha()}.csv');
    // BOM para que Excel respete los acentos
    await archivo.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(lineas.join('\r\n'))]);
    await Share.shareXFiles([XFile(archivo.path, mimeType: 'text/csv')], subject: 'Pacientes');
  }

  static Future<void> pdf(List<Paciente> pacientes) async {
    final doc = pw.Document();
    const verde = PdfColor.fromInt(0xFF0F5E63);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Catálogo de pacientes',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: verde)),
            pw.Text('${pacientes.length} registros', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headers: _columnas,
          data: pacientes.map(_fila).toList(),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: verde),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F5)),
        ),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/pacientes_${_fecha()}.pdf');
    await archivo.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(archivo.path, mimeType: 'application/pdf')], subject: 'Pacientes');
  }
}
