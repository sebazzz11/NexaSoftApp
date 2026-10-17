class Incidencia {
  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String prioridad;
  String fecha;

  static const prioridadesValidas = ['Baja', 'Media', 'Alta'];
  static String normalizarPrioridad(dynamic valor) =>
      prioridadesValidas.contains(valor) ? valor as String : 'Media';

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    this.prioridad = 'Media',
    required this.fecha,
  });

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      prioridad: normalizarPrioridad(m['prioridad']),
      fecha: m['fecha']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'prioridad': normalizarPrioridad(prioridad),
      'fecha': fecha,
    };
  }
}
