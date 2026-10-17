import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  GestorIncidencias({AlmacenLocal? almacen}) : datos = almacen ?? AlmacenLocal();

  final AlmacenLocal datos;
  List<Incidencia> incidencias = [];

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  List<Incidencia> buscar(String texto) {
    final consulta = texto.trim().toLowerCase();
    if (consulta.isEmpty) return List<Incidencia>.from(incidencias);
    return incidencias.where((x) {
      return x.titulo.toLowerCase().contains(consulta) ||
          x.descripcion.toLowerCase().contains(consulta);
    }).toList();
  }

  // Combina la búsqueda de texto con los filtros de estado y prioridad.
  List<Incidencia> filtrar({
    String texto = '',
    String estado = 'Todos',
    String prioridad = 'Todas',
  }) {
    final consulta = texto.trim().toLowerCase();
    return incidencias.where((x) {
      final coincideTexto = consulta.isEmpty ||
          x.titulo.toLowerCase().contains(consulta) ||
          x.descripcion.toLowerCase().contains(consulta);
      final coincideEstado = estado == 'Todos' || x.estado == estado;
      final coincidePrioridad = prioridad == 'Todas' || x.prioridad == prioridad;
      return coincideTexto && coincideEstado && coincidePrioridad;
    }).toList();
  }

  Incidencia? porId(String id) {
    for (final x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) =>
      incidencias.where((x) => x.estado == estado).length;

  Future<void> cambiarEstado(String id, String estado) async {
    final indice = incidencias.indexWhere((x) => x.id == id);
    if (indice == -1) throw StateError('No existe la incidencia $id');

    // Se crea una lista nueva para guardar el estado actualizado antes de darlo por terminado.
    final actualizadas = incidencias.toList();
    final actual = actualizadas[indice];
    actualizadas[indice] = Incidencia(
      id: actual.id,
      titulo: actual.titulo,
      descripcion: actual.descripcion,
      cliente: actual.cliente,
      categoria: actual.categoria,
      estado: estado,
      prioridad: actual.prioridad,
      fecha: actual.fecha,
    );
    await datos.guardar(actualizadas);
    incidencias = actualizadas;
  }

  Future<void> cambiarPrioridad(String id, String prioridad) async {
    if (!Incidencia.prioridadesValidas.contains(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Debe ser Baja, Media o Alta');
    }
    final indice = incidencias.indexWhere((x) => x.id == id);
    if (indice == -1) throw StateError('No existe la incidencia $id');
    final actualizadas = incidencias.toList();
    final actual = actualizadas[indice];
    actualizadas[indice] = Incidencia(
      id: actual.id,
      titulo: actual.titulo,
      descripcion: actual.descripcion,
      cliente: actual.cliente,
      categoria: actual.categoria,
      estado: actual.estado,
      prioridad: prioridad,
      fecha: actual.fecha,
    );
    await datos.guardar(actualizadas);
    incidencias = actualizadas;
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria, {String prioridad = 'Media'}) async {
    if (!Incidencia.prioridadesValidas.contains(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Debe ser Baja, Media o Alta');
    }
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      prioridad: prioridad,
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    final actualizadas = [nuevo, ...incidencias];
    await datos.guardar(actualizadas);
    incidencias = actualizadas;
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
