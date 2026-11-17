import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellas/app.dart';
import 'package:huellas/core/dependencias.dart';
import 'package:huellas/core/errores.dart';
import 'package:huellas/core/rutas.dart';
import 'package:huellas/features/diario/presentation/pages/formulario_entrada_page.dart';
import 'package:huellas/features/seguridad/data/servicio_biometrico.dart';

import 'fakes.dart';

/// Simula la pantalla de un teléfono (432 x 960 puntos lógicos) para que el
/// formulario completo quepa sin desplazarse.
void _pantallaDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// Monta solo el formulario, con un botón para abrirlo y comprobar el resultado.
Future<void> _abrirFormulario(WidgetTester tester, Dependencias dep) async {
  _pantallaDeTelefono(tester);
  await tester.pumpWidget(AppScope(
    dependencias: dep,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute<bool>(builder: (_) => const FormularioEntradaPage())),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista vacía muestra la invitación a escribir', (tester) async {
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas()));
    await tester.pumpAndSettle();
    expect(find.text('Tu diario está vacío'), findsOneWidget);
    expect(find.text('Nueva entrada'), findsOneWidget);
  });

  testWidgets('la lista muestra las entradas guardadas y el resumen', (tester) async {
    final repo = RepositorioFalso([entradaDeEjemplo(id: 1), entradaDeEjemplo(id: 2, titulo: 'Cenote')]);
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas(repositorio: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Cenote'), findsOneWidget);
    expect(find.text('Paseo por Paseo de Montejo'), findsOneWidget);
    expect(find.text('lugares'), findsOneWidget);
  });

  testWidgets('si SQLite falla se muestra el error con botón Reintentar', (tester) async {
    final repo = RepositorioFalso()..fallar = true;
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas(repositorio: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Algo salió mal'), findsOneWidget);

    repo.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu diario está vacío'), findsOneWidget);
  });

  testWidgets('el botón Nueva entrada abre el formulario y al guardar vuelve a la lista', (tester) async {
    _pantallaDeTelefono(tester);
    final repo = RepositorioFalso();
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas(repositorio: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva entrada'));
    await tester.pumpAndSettle();
    expect(find.text('Agrega una foto de tu día'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Título del día'), 'Primer día');
    await tester.enterText(find.widgetWithText(TextFormField, '¿Qué pasó hoy?'), 'Todo bien.');
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Entrada guardada en tu diario'), findsOneWidget);
    expect(find.text('Primer día'), findsOneWidget);
  });

  testWidgets('tocar una tarjeta abre el detalle con su mapa', (tester) async {
    _pantallaDeTelefono(tester);
    final repo = RepositorioFalso([entradaDeEjemplo()]);
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas(repositorio: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paseo por Paseo de Montejo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('¿Dónde fue?'), findsOneWidget);
    expect(find.text('Abrir en Google Maps'), findsOneWidget);
  });

  testWidgets('el drawer navega al mapa con rutas nombradas', (tester) async {
    _pantallaDeTelefono(tester);
    // La fuente de pruebas (cuadros del mismo ancho) es más ancha que Roboto.
    tester.platformDispatcher.textScaleFactorTestValue = 0.85;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(HuellasApp(dependencias: dependenciasFalsas()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa de recuerdos'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay lugares'), findsOneWidget);
  });

  testWidgets('con bloqueo activo, la app abre en la pantalla de huella', (tester) async {
    final prefs = PreferenciasEnMemoria()..bloqueoActivo = true;
    final bio = BiometriaFalsa(resultado: ResultadoAutenticacion.cancelado);
    await tester.pumpWidget(
        HuellasApp(dependencias: dependenciasFalsas(preferencias: prefs, biometria: bio)));
    await tester.pumpAndSettle();
    expect(find.text('Tu diario está protegido'), findsOneWidget);
    expect(find.textContaining('cancelada'), findsOneWidget);

    bio.resultado = ResultadoAutenticacion.exito;
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Mis huellas'), findsOneWidget);
  });

  testWidgets('el formulario valida los campos obligatorios', (tester) async {
    await _abrirFormulario(tester, dependenciasFalsas());
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ponle un título a tu día'), findsOneWidget);
    expect(find.text('Cuenta un poco de tu día'), findsOneWidget);
  });

  testWidgets('el dictado escribe en el campo de texto', (tester) async {
    await _abrirFormulario(tester, dependenciasFalsas());
    await tester.tap(find.byTooltip('Dictar con voz'));
    await tester.pumpAndSettle();
    expect(find.text('Hoy fue un gran día'), findsOneWidget);
  });

  testWidgets('micrófono negado muestra el aviso de permiso', (tester) async {
    final dictado = DictadoFalso()
      ..fallaAlPreparar = const FallaPermiso('Micrófono bloqueado', permanente: true);
    await _abrirFormulario(tester, dependenciasFalsas(dictado: dictado));
    await tester.tap(find.byTooltip('Dictar con voz'));
    await tester.pumpAndSettle();
    expect(find.text('Permiso necesario'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
  });

  testWidgets('guardar captura el GPS y escribe en el repositorio', (tester) async {
    final repo = RepositorioFalso();
    await _abrirFormulario(tester, dependenciasFalsas(repositorio: repo));
    await tester.enterText(find.widgetWithText(TextFormField, 'Título del día'), 'Cenote Ik Kil');
    await tester.enterText(find.widgetWithText(TextFormField, '¿Qué pasó hoy?'), 'Nadamos un rato.');
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.entradas, hasLength(1));
    expect(repo.entradas.single.ubicacion?.latitud, 21.0419);
  });

  testWidgets('sin permiso de GPS se ofrece guardar sin ubicación', (tester) async {
    final repo = RepositorioFalso();
    final gps = UbicacionFalsa()..falla = const FallaPermiso('Sin permiso de ubicación');
    await _abrirFormulario(tester, dependenciasFalsas(repositorio: repo, ubicacion: gps));
    await tester.enterText(find.widgetWithText(TextFormField, 'Título del día'), 'Sin GPS');
    await tester.enterText(find.widgetWithText(TextFormField, '¿Qué pasó hoy?'), 'Día en casa.');
    await tester.tap(find.byTooltip('Guardar'));
    // El indicador de progreso sigue girando detrás del diálogo: no se usa pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Permiso de ubicación'), findsOneWidget);
    await tester.tap(find.text('Guardar sin ubicación'));
    await tester.pumpAndSettle();
    expect(repo.entradas.single.ubicacion, isNull);
  });

  test('las rutas nombradas son únicas', () {
    final rutas = {Rutas.bloqueo, Rutas.lista, Rutas.detalle, Rutas.nueva, Rutas.mapa, Rutas.ajustes};
    expect(rutas, hasLength(6));
  });
}
