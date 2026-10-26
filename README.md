# Punto de Venta Dolores (Flutter + SQLite + TDD)

Práctica de **Desarrollo Móvil Integral · UTNG** (Manual paso a paso con TDD).
Punto de venta que guarda productos y ventas en **SQLite local**, calcula total, IVA y cambio con
**centavos enteros** (nunca `double`), descuenta inventario con una **transacción** y hace el corte del día.

- **Alumno:** ______________________________
- **Grupo / Fecha:** ______________________________

## Arquitectura

| Capa | Carpeta | Contenido | Depende de |
|---|---|---|---|
| Dominio (Dart puro) | `lib/dominio/` | `dinero`, `producto`, `carrito`, `venta`, `excepciones` | Nada (ni Flutter ni SQLite) |
| Datos | `lib/datos/` | `base_datos`, `repositorio_productos`, `repositorio_ventas` | Dominio + sqflite |
| Presentación | `lib/presentacion/` | `caja_viewmodel`, `pantalla_caja` | Dominio + repositorios |
| Composition root | `lib/main.dart` | Crea y conecta los objetos | Todas |

## Cómo ejecutar

```bash
flutter pub get
flutter test                 # pruebas automatizadas (dominio + datos)
flutter run                  # app en emulador o celular Android
```

> `sqflite` funciona en Android/iOS. Las pruebas de `test/datos_test.dart` usan `sqflite_common_ffi`
> (SQLite en la computadora, base en memoria), por eso corren sin emulador.

---

## 1. Pruebas automatizadas realizadas

**Total: 22 pruebas** → 17 del manual (11 de dominio + 6 de datos) + 5 de los retos.
Marca cada resultado con ✅ cuando `flutter test` las muestre en verde.

### 1.1 Dominio (`test/dominio_test.dart`) — 13 pruebas

| ID | Grupo | Prueba | Resultado esperado | Resultado |
|---|---|---|---|---|
| D-01 | Dinero | formatea centavos | `0`→`$0.00`, `5`→`$0.05`, `123456`→`$1,234.56` | ☐ |
| D-02 | Dinero | convierte texto a centavos | `'12.5'`→1250, `'$1,200'`→120000, `'0.07'`→7 | ☐ |
| D-03 | Dinero | rechaza texto inválido | `''` y `'1.2.3'` lanzan `FormatException` | ☐ |
| D-04 | Dinero | RETO: `'.5'` son 50 centavos | `pesosACentavos('.5')` = 50 | ☐ |
| D-05 | Dinero | RETO: montos negativos | `formatearPesos(-250)` = `-$2.50` | ☐ |
| D-06 | Producto | ida y vuelta a mapa | `desdeMapa(aMapa())` conserva código y precio | ☐ |
| D-07 | Producto | copiarCon | cambia solo lo indicado (existencias 4, precio 100) | ☐ |
| D-08 | Carrito | suma cantidades del mismo producto | 1 renglón con cantidad 2 y total 5000 | ☐ |
| D-09 | Carrito | no excede existencias | lanza `ExistenciasInsuficientesException` | ☐ |
| D-10 | Carrito | desglosa IVA 16 % | $100.00 → IVA 1379 y subtotal + IVA = total | ☐ |
| D-11 | Carrito | calcula cambio | paga 5000 con total 2500 → cambio 2500 | ☐ |
| D-12 | Carrito | pago insuficiente | lanza `PagoInsuficienteException` | ☐ |
| D-13 | Carrito | carrito vacío no cobra | lanza `CarritoVacioException` | ☐ |

### 1.2 Datos (`test/datos_test.dart`) — 9 pruebas (SQLite en memoria)

| ID | Prueba | Resultado esperado | Resultado |
|---|---|---|---|
| B-01 | guarda y busca producto | encuentra "Nieve de limón" con `id` asignado | ☐ |
| B-02 | código duplicado | lanza `CodigoDuplicadoException` (no un error de SQL) | ☐ |
| B-03 | cobrar descuenta inventario y registra venta | cambio 5000 y existencias 5 → 3 | ☐ |
| B-04 | si falla el cobro NO se descuenta inventario | `PagoInsuficienteException` y existencias siguen en 5 | ☐ |
| B-05 | corte del día suma ventas de hoy | 2 ventas y total 7500 ($75.00) | ☐ |
| B-06 | bajo inventario alerta | 1 producto con existencias ≤ 5 | ☐ |
| B-07 | RETO: bajoInventario con 2 y 50 existencias | devuelve `['DU-001','NV-001']`, no el de 50 | ☐ |
| B-08 | RETO: vender 5 y luego 1 más | `ExistenciasInsuficientesException` y existencias = 0 | ☐ |
| B-09 | sembrarEjemplos | carga los 8 productos de la nevería | ☐ |

### 1.3 Evidencia del ciclo TDD y de la ejecución

**Rojo → Verde.** Cada regla de negocio se escribió primero como prueba que fallaba y después se
implementó el código mínimo para pasarla (Ronda 1 al 5 del manual).

| Evidencia | Comando | Captura |
|---|---|---|
| (Opcional) Prueba en ROJO antes de crear `dinero.dart`: "Target of URI doesn't exist" | `flutter test` | ![rojo](capturas/00_rojo_tdd.png) |
| Pruebas de dominio en verde | `flutter test test/dominio_test.dart --reporter expanded` | ![dominio](capturas/01_test_dominio.png) |
| Pruebas de datos en verde | `flutter test test/datos_test.dart --reporter expanded` | ![datos](capturas/02_test_datos.png) |
| **Todas** las pruebas en verde | `flutter test --reporter expanded` | ![todas](capturas/03_test_todas_verde.png) |

---

## 2. Pruebas manuales en la app

Se parte de una instalación nueva (la base se llena con 8 productos de ejemplo).

| ID | Escenario | Pasos | Resultado esperado | Resultado |
|---|---|---|---|---|
| M-01 | Catálogo inicial | Abrir la app | 8 productos con existencias y precio (Nieve de limón: 40 disponibles, $25.00) | ☐ |
| M-02 | Agregar al carrito | Tocar "Nieve de limón" 2 veces | Renglón `2 × Nieve de limón (1 bola)` $50.00, IVA incluido $6.90, TOTAL $50.00 | ☐ |
| M-03 | Cobrar con cambio | "Paga con $" = `100` → Cobrar | Mensaje `Cambio: $50.00`; existencias 40 → 38; carrito y campo vacíos | ☐ |
| M-04 | Pago insuficiente | 2 nieves y pagar `10` | `Faltan 4000 centavos para cubrir la cuenta`; existencias sin cambio | ☐ |
| M-05 | Carrito vacío | Cobrar sin productos | `No hay productos en el carrito` | ☐ |
| M-06 | Excede existencias | Tocar "Cerámica Talavera chica" 9 veces (hay 8) | En la 9.ª: `Solo quedan 8 de Cerámica Talavera chica` | ☐ |
| M-07 | Búsqueda | Escribir `nieve` | Solo aparecen las 3 nieves | ☐ |
| M-08 | Persistencia | Cerrar y reabrir la app | Las existencias siguen en 38 (SQLite) | ☐ |
| M-09 | Monto inválido | Cobrar con el campo de pago vacío | Muestra el mensaje de error y la app no se cierra | ☐ |
| M-10 | Producto agotado | Vender las 8 Talavera (pagar `1500`) | Cambio `$60.00`; el producto queda en 0 y ya no se puede tocar | ☐ |

### Capturas de la app

| Escenario | Captura |
|---|---|
| M-01 Catálogo | ![catalogo](capturas/04_app_catalogo.png) |
| M-02 Carrito con total e IVA | ![carrito](capturas/05_app_carrito.png) |
| M-03 Cambio y existencias 38 | ![cambio](capturas/06_app_cambio.png) |
| M-04 Pago insuficiente | ![pago](capturas/07_app_pago_insuficiente.png) |
| M-06 / M-10 Sin existencias | ![agotado](capturas/08_app_sin_existencias.png) |
| M-07 Búsqueda | ![busqueda](capturas/09_app_busqueda.png) |

---

## 3. Checklist de calidad del manual

| Verificación | Estado |
|---|---|
| Todo el dinero está en centavos enteros; ningún `double` en el dominio | ✅ (revisado en el código) |
| El dominio no importa Flutter ni sqflite | ✅ (revisado en el código) |
| Cada regla de negocio nació de una prueba roja | ☐ (ver captura 00) |
| Cobrar usa una transacción y se probó el caso de fallo | ✅ `db.transaction` + pruebas B-04 y B-08 |
| Los errores técnicos se traducen a excepciones de negocio con mensaje claro | ✅ (`CodigoDuplicadoException`, etc.) |
| La pantalla no contiene reglas de negocio | ✅ (solo dibuja y llama al ViewModel) |
| `flutter test` termina completamente en verde | ☐ (ver captura 03) |

## 4. Problemas conocidos

- **Windows: `Failed to load dynamic library 'sqlite3.dll'`** al correr `test/datos_test.dart`.
  Descarga `sqlite3.dll` (paquete "Precompiled Binaries for Windows", x64, de sqlite.org) y colócala en la
  raíz del proyecto o en una carpeta del `PATH`; vuelve a ejecutar `flutter test`.
- **Navegador (Chrome/Edge):** `sqflite` no funciona en web. La app se ejecuta en Android/iOS.
