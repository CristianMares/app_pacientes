import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paciente.dart';

class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);
  @override
  String toString() => mensaje;
}

class ResultadoLista {
  final List<Paciente> pacientes;
  // Si es true, la lista viene de la última copia guardada (sin conexión)
  final bool desdeCache;
  final DateTime? fechaCache;

  ResultadoLista(this.pacientes, {this.desdeCache = false, this.fechaCache});
}

class ApiService {
  static const _claveUrl = 'api_url';
  static const _claveCache = 'cache_pacientes';
  static const _claveFechaCache = 'cache_fecha';
  static const urlPorDefecto = 'http://pacientes.runasp.net';
  static const _timeout = Duration(seconds: 10);
  static const _headers = {'Content-Type': 'application/json'};

  static Future<String> obtenerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveUrl) ?? urlPorDefecto;
  }

  static Future<void> guardarUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var limpia = url.trim();
    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }
    await prefs.setString(_claveUrl, limpia);
  }

  static Future<Uri> _uri(String ruta, [Map<String, String>? query]) async {
    final base = await obtenerUrl();
    return Uri.parse('$base/api/pacientes$ruta').replace(queryParameters: query);
  }

  static List<Paciente> _parsear(String body) =>
      (jsonDecode(body) as List).map((e) => Paciente.fromJson(e)).toList();

  // Trae todos los pacientes y guarda una copia para usarla sin conexión
  static Future<ResultadoLista> listarTodos() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await _enviar(() async => http.get(await _uri('')));
      final lista = _parsear(res.body);
      await prefs.setString(_claveCache, res.body);
      await prefs.setString(_claveFechaCache, DateTime.now().toIso8601String());
      return ResultadoLista(lista);
    } on ApiException {
      final copia = prefs.getString(_claveCache);
      if (copia == null) rethrow;
      return ResultadoLista(
        _parsear(copia),
        desdeCache: true,
        fechaCache: DateTime.tryParse(prefs.getString(_claveFechaCache) ?? ''),
      );
    }
  }

  static Future<Paciente> crear(Paciente p) async {
    final res = await _enviar(
        () async => http.post(await _uri(''), headers: _headers, body: jsonEncode(p.toJson())));
    return Paciente.fromJson(jsonDecode(res.body));
  }

  static Future<Paciente> editar(Paciente p) async {
    final res = await _enviar(() async => http.put(await _uri('/${p.idPaciente}'),
        headers: _headers, body: jsonEncode(p.toJson())));
    return Paciente.fromJson(jsonDecode(res.body));
  }

  static Future<Paciente> cancelar(int id) async {
    final res = await _enviar(() async => http.patch(await _uri('/$id/cancelar')));
    return Paciente.fromJson(jsonDecode(res.body));
  }

  static Future<Paciente> reactivar(int id) async {
    final res = await _enviar(() async => http.patch(await _uri('/$id/reactivar')));
    return Paciente.fromJson(jsonDecode(res.body));
  }

  // Regresa el paciente con mismo nombre completo y teléfono, si existe.
  // Si no hay conexión regresa null y se deja que el guardado marque el error.
  static Future<Paciente?> buscarDuplicado(Paciente p) async {
    try {
      final query = {
        'nombre': p.nombre,
        'aPaterno': p.aPaterno,
        'aMaterno': p.aMaterno,
        'telefono': p.telefono,
        if (p.idPaciente > 0) 'excluirId': '${p.idPaciente}',
      };
      final res = await _enviar(() async => http.get(await _uri('/duplicado', query)));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['existe'] == true && body['paciente'] != null) {
        return Paciente.fromJson(body['paciente']);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> probarConexion(String url) async {
    try {
      final res = await http.get(Uri.parse('$url/api/pacientes')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _enviar(Future<http.Response> Function() peticion) async {
    http.Response res;
    try {
      res = await peticion().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('El servidor no respondió. Revisa tu conexión.');
    } catch (_) {
      throw ApiException('No se pudo conectar con la API.');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return res;
    throw ApiException(_mensajeError(res));
  }

  static String _mensajeError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['mensaje'] != null) return body['mensaje'];
      // Errores de validación de ASP.NET
      if (body is Map && body['errors'] is Map) {
        final errores = (body['errors'] as Map).values.expand((v) => v as List).join('\n');
        if (errores.isNotEmpty) return errores;
      }
    } catch (_) {}
    return 'Error ${res.statusCode}';
  }
}
