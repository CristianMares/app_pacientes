import 'package:app_pacientes/models/paciente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula IMC y categoría', () {
    expect(calcularImc(62, 165).imc, 22.8);
    expect(calcularImc(62, 165).categoria, 'Normal');
    expect(calcularImc(48, 168).categoria, 'Bajo peso');
    expect(calcularImc(80, 178).categoria, 'Sobrepeso');
    expect(calcularImc(91, 172).categoria, 'Obesidad');
  });
}
