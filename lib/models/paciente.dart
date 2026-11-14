class Paciente {
  final int idPaciente;
  final String nombre;
  final String aPaterno;
  final String aMaterno;
  final String direccion;
  final String telefono;
  final double peso; // kg
  final double altura; // cm
  final String estatus;
  final double imc;
  final String categoriaImc;

  const Paciente({
    required this.idPaciente,
    required this.nombre,
    required this.aPaterno,
    this.aMaterno = '',
    required this.direccion,
    required this.telefono,
    required this.peso,
    required this.altura,
    this.estatus = 'A',
    this.imc = 0,
    this.categoriaImc = '',
  });

  bool get activo => estatus == 'A';

  String get nombreCompleto =>
      [nombre, aPaterno, aMaterno].where((s) => s.isNotEmpty).join(' ');

  String get iniciales {
    final a = nombre.isNotEmpty ? nombre[0] : '';
    final b = aPaterno.isNotEmpty ? aPaterno[0] : '';
    return (a + b).toUpperCase();
  }

  factory Paciente.fromJson(Map<String, dynamic> j) => Paciente(
        idPaciente: j['idPaciente'] as int,
        nombre: j['nombre'] ?? '',
        aPaterno: j['aPaterno'] ?? '',
        aMaterno: j['aMaterno'] ?? '',
        direccion: j['direccion'] ?? '',
        telefono: j['telefono'] ?? '',
        peso: (j['peso'] as num).toDouble(),
        altura: (j['altura'] as num).toDouble(),
        estatus: j['estatus'] ?? 'A',
        imc: (j['imc'] as num?)?.toDouble() ?? 0,
        categoriaImc: j['categoriaImc'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'idPaciente': idPaciente,
        'nombre': nombre,
        'aPaterno': aPaterno,
        'aMaterno': aMaterno,
        'direccion': direccion,
        'telefono': telefono,
        'peso': peso,
        'altura': altura,
        'estatus': estatus,
      };
}

// Mismo cálculo que la API, para mostrar el IMC mientras se captura
({double imc, String categoria}) calcularImc(double peso, double alturaCm) {
  if (peso <= 0 || alturaCm <= 0) return (imc: 0, categoria: '');
  final m = alturaCm / 100;
  final imc = double.parse((peso / (m * m)).toStringAsFixed(1));
  final categoria = imc < 18.5
      ? 'Bajo peso'
      : imc < 25
          ? 'Normal'
          : imc < 30
              ? 'Sobrepeso'
              : 'Obesidad';
  return (imc: imc, categoria: categoria);
}
