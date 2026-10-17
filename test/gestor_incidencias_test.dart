import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

class AlmacenPrueba extends AlmacenLocal {
  AlmacenPrueba(this.registros);
  List<Map<String, dynamic>> registros;

  @override
  Future<List<Incidencia>> leer() async => registros
      .map((r) => Incidencia.desdeJson(Map<String, dynamic>.from(r)))
      .toList();

  @override
  Future<void> guardar(List<Incidencia> lista) async {
    registros = lista.map((x) => x.toJson()).toList();
  }

  @override
  Future<void> restaurarDatosDeEjemplo() async {}
}

Map<String, dynamic> caso(String id, String titulo, String descripcion,
        String estado) =>
    {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': 'Cliente de prueba',
      'categoria': 'Redes',
      'estado': estado,
      'fecha': '2026-10-14',
    };

void main() {
  test('BUG-001: el cambio de estado persiste y no altera otros registros', () async {
    final almacen = AlmacenPrueba([
      caso('INC-1', 'Caso A', 'Descripción A', 'Pendiente'),
      caso('INC-2', 'Caso B', 'Descripción B', 'En proceso'),
    ]);
    final gestor = GestorIncidencias(almacen: almacen);
    await gestor.iniciar();
    await gestor.cambiarEstado('INC-1', 'Resuelta');

    expect(gestor.porId('INC-1')!.estado, 'Resuelta');
    expect(gestor.porId('INC-2')!.estado, 'En proceso');
    final gestorTrasReinicio = GestorIncidencias(almacen: almacen);
    await gestorTrasReinicio.iniciar();
    expect(gestorTrasReinicio.porId('INC-1')!.estado, 'Resuelta');
    expect(gestorTrasReinicio.porId('INC-2')!.estado, 'En proceso');
  });

  test('BUG-002: busca título y descripción sin distinguir mayúsculas', () async {
    final gestor = GestorIncidencias(
      almacen: AlmacenPrueba([
        caso('INC-1', 'WiFi intermitente en recepción', 'Se corta la red', 'Pendiente'),
        caso('INC-2', 'Configuración VPN', 'No conecta el túnel seguro', 'En proceso'),
      ]),
    );
    await gestor.iniciar();
    expect(gestor.buscar('wifi').map((x) => x.id), contains('INC-1'));
    expect(gestor.buscar('WiFi').map((x) => x.id), contains('INC-1'));
    expect(gestor.buscar(' túnel ').map((x) => x.id), contains('INC-2'));
    expect(gestor.buscar('   '), hasLength(2));
  });

  test('FEAT-001: prioridad se crea, cambia y persiste tras reconstruir gestor', () async {
    final antiguo = caso('INC-ANTIGUA', 'Antigua', 'Sin prioridad', 'Pendiente');
    final almacen = AlmacenPrueba([antiguo]);
    final gestor = GestorIncidencias(almacen: almacen);
    await gestor.iniciar();
    expect(gestor.porId('INC-ANTIGUA')!.prioridad, 'Media');

    await gestor.crear('Caso urgente', 'Descripción', 'Cliente', 'Redes', prioridad: 'Alta');
    final nuevo = gestor.incidencias.first;
    expect(nuevo.prioridad, 'Alta');
    await gestor.cambiarPrioridad(nuevo.id, 'Baja');
    expect(gestor.porId(nuevo.id)!.prioridad, 'Baja');

    final trasReinicio = GestorIncidencias(almacen: almacen);
    await trasReinicio.iniciar();
    expect(trasReinicio.porId(nuevo.id)!.prioridad, 'Baja');
    expect(trasReinicio.porId('INC-ANTIGUA')!.prioridad, 'Media');
  });

  test('FEAT-001: rechaza prioridades no permitidas', () async {
    final almacen = AlmacenPrueba([caso('INC-1', 'Caso', 'Descripción', 'Pendiente')]);
    final gestor = GestorIncidencias(almacen: almacen);
    await gestor.iniciar();
    await expectLater(gestor.cambiarPrioridad('INC-1', 'Crítica'), throwsArgumentError);
    expect(Incidencia.desdeJson(caso('INC-2', 'Antigua', 'Descripción', 'Pendiente')).prioridad, 'Media');
  });


  test('FEAT-002: combina búsqueda, estado y prioridad', () async {
    final gestor = GestorIncidencias(
      almacen: AlmacenPrueba([
        {...caso('INC-1', 'WiFi recepción', 'Se corta la red', 'Pendiente'), 'prioridad': 'Alta'},
        {...caso('INC-2', 'WiFi oficina', 'Red lenta', 'Resuelta'), 'prioridad': 'Alta'},
        {...caso('INC-3', 'Correo recepción', 'No abre el correo', 'Pendiente'), 'prioridad': 'Media'},
        {...caso('INC-4', 'Pantalla', 'No enciende', 'En proceso'), 'prioridad': 'Baja'},
      ]),
    );
    await gestor.iniciar();

    final resultado = gestor.filtrar(
      texto: ' wifi ',
      estado: 'Pendiente',
      prioridad: 'Alta',
    );
    expect(resultado.map((x) => x.id), ['INC-1']);

    expect(gestor.filtrar(estado: 'Pendiente').map((x) => x.id).toSet(),
        {'INC-1', 'INC-3'});
    expect(gestor.filtrar(prioridad: 'Alta').map((x) => x.id).toSet(),
        {'INC-1', 'INC-2'});

    // Al limpiar texto y seleccionar los valores generales, vuelven todos.
    expect(gestor.filtrar(texto: '', estado: 'Todos', prioridad: 'Todas'),
        hasLength(4));
  });

  test('FEAT-002: cero coincidencias devuelve una lista vacía', () async {
    final gestor = GestorIncidencias(
      almacen: AlmacenPrueba([
        {...caso('INC-1', 'WiFi recepción', 'Se corta la red', 'Pendiente'), 'prioridad': 'Alta'},
      ]),
    );
    await gestor.iniciar();
    expect(gestor.filtrar(texto: 'inexistente', estado: 'Resuelta', prioridad: 'Baja'), isEmpty);
  });

  test('BUG-003: los conteos se calculan desde los datos actuales', () async {
    final almacen = AlmacenPrueba([
      caso('INC-1', 'Caso A', 'A', 'Pendiente'),
      caso('INC-2', 'Caso B', 'B', 'Resuelta'),
    ]);
    final gestor = GestorIncidencias(almacen: almacen);
    await gestor.iniciar();
    expect(gestor.contar('Pendiente'), 1);
    await gestor.cambiarEstado('INC-1', 'Resuelta');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('Resuelta'), 2);
    await gestor.crear('Caso nuevo', 'Descripción', 'Cliente', 'Software');
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('Resuelta'), 2);
    final trasReinicio = GestorIncidencias(almacen: almacen);
    await trasReinicio.iniciar();
    expect(trasReinicio.contar('Pendiente'), 1);
    expect(trasReinicio.contar('Resuelta'), 2);
  });
}
