import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';

class PantallaDetalle extends StatefulWidget {
  final GestorIncidencias gestor;
  final String id;
  const PantallaDetalle({super.key, required this.gestor, required this.id});

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  bool guardando = false;
  bool guardandoPrioridad = false;

  Future<void> cambiar(String? valor) async {
    if (valor == null) return;
    setState(() => guardando = true);
    try {
      await widget.gestor.cambiarEstado(widget.id, valor);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> cambiarPrioridad(String? valor) async {
    if (valor == null) return;
    setState(() => guardandoPrioridad = true);
    try {
      await widget.gestor.cambiarPrioridad(widget.id, valor);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la prioridad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => guardandoPrioridad = false);
    }
  }

  Widget fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 3),
        Text(valor, style: const TextStyle(fontSize: 16)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Incidencia? item = widget.gestor.porId(widget.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de incidencia')),
      body: item == null
          ? const Center(child: Text('Incidencia no encontrada'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 670),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(item.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(item.titulo, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          fila('Cliente', item.cliente),
                          fila('Categoría', item.categoria),
                          fila('Prioridad', item.prioridad),
                          fila('Fecha de reporte', item.fecha),
                          fila('Descripción', item.descripcion),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: item.estado,
                      decoration: const InputDecoration(labelText: 'Estado actual', border: OutlineInputBorder()),
                      items: ['Pendiente', 'En proceso', 'Resuelta']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: guardando ? null : cambiar,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: item.prioridad,
                      decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()),
                      items: Incidencia.prioridadesValidas
                          .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (guardando || guardandoPrioridad) ? null : cambiarPrioridad,
                    ),
                    if (guardando || guardandoPrioridad) const Padding(
                      padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Los cambios se reflejan al volver a la lista.',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
    );
  }
}
