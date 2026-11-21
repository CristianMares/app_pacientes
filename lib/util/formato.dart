const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String numero(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

// 21 nov 2026, 08:40
String fecha(DateTime f) {
  final l = f.toLocal();
  String d(int x) => x.toString().padLeft(2, '0');
  return '${l.day} ${_meses[l.month - 1]} ${l.year}, ${d(l.hour)}:${d(l.minute)}';
}

// Para comparar textos sin importar mayúsculas ni acentos
String normalizar(String s) {
  const con = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sin = 'aeiouunAEIOUUN';
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = con.indexOf(c);
    b.write(i >= 0 ? sin[i] : c);
  }
  return b.toString().toLowerCase().trim();
}
