import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_dolores/datos/base_datos.dart';
import 'package:punto_venta_dolores/datos/repositorio_productos.dart';
import 'package:punto_venta_dolores/datos/repositorio_ventas.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; // SQLite en tu computadora

  late RepositorioProductos productos;
  late RepositorioVentas ventas;

  setUp(() async {
    final db = await BaseDatos.abrir(ruta: inMemoryDatabasePath);
    productos = RepositorioProductos(db);
    ventas = RepositorioVentas(db);
    await productos.agregar(const Producto(
        codigo: 'NV-001', nombre: 'Nieve de limón',
        precioCentavos: 2500, existencias: 5));
  });

  test('guarda y busca producto', () async {
    final p = await productos.buscarPorCodigo('NV-001');
    expect(p!.nombre, 'Nieve de limón');
    expect(p.id, isNotNull);
  });

  test('código duplicado lanza excepción de dominio', () {
    expect(
        () => productos.agregar(const Producto(
            codigo: 'NV-001', nombre: 'Otra',
            precioCentavos: 100, existencias: 1)),
        throwsA(isA<CodigoDuplicadoException>()));
  });

  test('cobrar descuenta inventario y registra venta', () async {
    final p = (await productos.buscarPorCodigo('NV-001'))!;
    final carrito = Carrito()..agregar(p, cantidad: 2);
    final venta = await ventas.cobrar(carrito, 10000);
    expect(venta.cambioCentavos, 5000);
    expect((await productos.buscarPorCodigo('NV-001'))!.existencias, 3);
  });

  test('si falla el cobro NO se descuenta inventario', () async {
    final p = (await productos.buscarPorCodigo('NV-001'))!;
    final carrito = Carrito()..agregar(p, cantidad: 2);
    await expectLater(ventas.cobrar(carrito, 100),
        throwsA(isA<PagoInsuficienteException>()));
    expect((await productos.buscarPorCodigo('NV-001'))!.existencias, 5);
  });

  test('corte del día suma ventas de hoy', () async {
    final p = (await productos.buscarPorCodigo('NV-001'))!;
    await ventas.cobrar(Carrito()..agregar(p), 2500);
    await ventas.cobrar(Carrito()..agregar(p, cantidad: 2), 5000);
    final r = await ventas.corteDelDia(DateTime.now());
    expect(r.numeroVentas, 2);
    expect(r.totalCentavos, 7500);
  });

  test('bajo inventario alerta', () async {
    expect((await productos.bajoInventario()).length, 1);
  });

  // RETO de la Ronda 4: un producto con 2 existencias y otro con 50.
  test('RETO: bajoInventario devuelve solo los de pocas existencias', () async {
    await productos.agregar(const Producto(
        codigo: 'DU-001', nombre: 'Dulce', precioCentavos: 1800, existencias: 2));
    await productos.agregar(const Producto(
        codigo: 'DU-002', nombre: 'Alegría', precioCentavos: 1200, existencias: 50));
    final bajos = await productos.bajoInventario();
    expect(bajos.map((p) => p.codigo).toList(), ['DU-001', 'NV-001']);
  });

  // RETO de la Ronda 5: vender las 5 nieves y luego intentar 1 más.
  test('RETO: no vende más de lo que hay (revalida dentro de la transacción)',
      () async {
    final p = (await productos.buscarPorCodigo('NV-001'))!; // 5 existencias
    await ventas.cobrar(Carrito()..agregar(p, cantidad: 5), 12500);
    await expectLater(ventas.cobrar(Carrito()..agregar(p), 2500),
        throwsA(isA<ExistenciasInsuficientesException>()));
    expect((await productos.buscarPorCodigo('NV-001'))!.existencias, 0);
  });

  test('sembrarEjemplos carga los 8 productos de la nevería', () async {
    await productos.eliminar('NV-001'); // deja el catálogo vacío
    await productos.sembrarEjemplos();
    expect((await productos.listar()).length, 8);
  });
}
