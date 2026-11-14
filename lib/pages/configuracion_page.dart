import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../tema.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final _url = TextEditingController();
  bool _probando = false;
  bool? _conectado;

  @override
  void initState() {
    super.initState();
    ApiService.obtenerUrl().then((u) {
      if (mounted) setState(() => _url.text = u);
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _probar() async {
    setState(() {
      _probando = true;
      _conectado = null;
    });
    var url = _url.text.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final ok = await ApiService.probarConexion(url);
    if (mounted) {
      setState(() {
        _probando = false;
        _conectado = ok;
      });
    }
  }

  Future<void> _guardar() async {
    await ApiService.guardarUrl(_url.text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirección de la API',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Escribe la dirección donde está publicada la API, por ejemplo la IP de la lap en la misma red Wi-Fi.',
            style: TextStyle(color: Colores.secundario),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() => _conectado = null),
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'http://192.168.1.100:5080',
            ),
          ),
          const SizedBox(height: 12),
          if (_conectado != null)
            Row(
              children: [
                Icon(_conectado! ? Icons.check_circle_outline : Icons.error_outline,
                    size: 18, color: _conectado! ? Colores.primario : Colores.cancelado),
                const SizedBox(width: 8),
                Text(_conectado! ? 'Conexión correcta' : 'No responde en esa dirección',
                    style: TextStyle(color: _conectado! ? Colores.primario : Colores.cancelado)),
              ],
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _probando ? null : _probar,
            child: _probando
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Probar conexión'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
