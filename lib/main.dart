import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workia/l10n/app_localizations.dart';

import 'package:workia/providers/locale_provider.dart';

// Importamos vistas
import 'package:workia/views/auth/login_page.dart';
import 'package:workia/views/auth/register_page.dart';

// Importamos repositorios
import 'package:workia/domain/repositories/cliente_repository.dart';
import 'package:workia/domain/repositories/trabajo_repository.dart';
import 'package:workia/domain/repositories/gasto_repository.dart';
import 'package:workia/domain/repositories/empresa_repository.dart';

import 'package:workia/domain/repositories/problema_repository.dart';
import 'package:workia/domain/repositories/usuario_repository.dart';
// Importar repositorio de trabajos asignados
import 'package:workia/domain/repositories/trabajo_asignado_repository.dart';
// Importar repositorio de actividades
import 'package:workia/features/activities/domain/repositories/actividad_repository.dart';
import 'package:workia/domain/repositories/sesion_trabajo_repository.dart';

// Importamos implementaciones de repositorios
import 'package:workia/data/repositories/cliente_repository_firestore.dart';
import 'package:workia/data/repositories/trabajo_repository_firestore.dart';
import 'package:workia/data/repositories/gasto_repository_firestore.dart';
import 'package:workia/data/repositories/empresa_repository_firestore.dart';

import 'package:workia/data/repositories/problema_repository_firestore.dart';
import 'package:workia/data/repositories/usuario_repository_firestore.dart';
import 'package:workia/data/repositories/trabajo_asignado_repository_firestore.dart';
import 'package:workia/features/activities/data/repositories/actividad_repository_firestore.dart';
import 'package:workia/data/repositories/sesion_trabajo_repository_firestore.dart';

// Importamos casos de uso y view models
import 'package:workia/domain/usecases/clientes/agregar_cliente.dart';
import 'package:workia/domain/usecases/clientes/actualizar_cliente.dart';
import 'package:workia/domain/usecases/clientes/inactivar_cliente.dart';
import 'package:workia/domain/usecases/clientes/buscar_clientes.dart';
import 'package:workia/domain/usecases/clientes/obtener_clientes.dart';

import 'package:workia/domain/usecases/trabajos/agregar_trabajo.dart';
import 'package:workia/domain/usecases/trabajos/actualizar_trabajo.dart';
import 'package:workia/domain/usecases/trabajos/cancelar_trabajo.dart';
import 'package:workia/domain/usecases/trabajos/buscar_trabajos.dart';
import 'package:workia/domain/usecases/trabajos/obtener_trabajos.dart';
// Casos de uso para trabajos asignados
import 'package:workia/domain/usecases/trabajos_asignados/obtener_trabajos_asignados.dart';
import 'package:workia/domain/usecases/trabajos_asignados/agregar_trabajo_asignado.dart';
import 'package:workia/domain/usecases/trabajos_asignados/actualizar_trabajo_asignado.dart';
import 'package:workia/domain/usecases/trabajos_asignados/cancelar_trabajo_asignado.dart';
import 'package:workia/domain/usecases/trabajos_asignados/buscar_trabajos_asignados.dart';
// Casos de uso para actividades
import 'package:workia/features/activities/domain/usecases/obtener_actividades.dart';
import 'package:workia/features/activities/domain/usecases/obtener_todas_actividades.dart';
import 'package:workia/features/activities/domain/usecases/agregar_actividad.dart';
import 'package:workia/features/activities/domain/usecases/actualizar_actividad.dart';
import 'package:workia/features/activities/domain/usecases/eliminar_actividad.dart';

import 'package:workia/domain/usecases/gastos/agregar_gasto.dart';
import 'package:workia/domain/usecases/gastos/actualizar_gasto.dart';
import 'package:workia/domain/usecases/gastos/eliminar_gasto.dart';
import 'package:workia/domain/usecases/gastos/gastos_por_rango.dart';
import 'package:workia/domain/usecases/gastos/gastos_por_tipo.dart';
import 'package:workia/domain/usecases/gastos/obtener_gastos.dart';
import 'package:workia/domain/usecases/gastos/obtener_tipos_gasto.dart';
import 'package:workia/domain/usecases/gastos/agregar_tipo_gasto.dart';
import 'package:workia/domain/usecases/gastos/actualizar_tipo_gasto.dart';
import 'package:workia/domain/usecases/gastos/eliminar_tipo_gasto.dart';

import 'package:workia/domain/usecases/empresa/actualizar_empresa.dart';
import 'package:workia/domain/usecases/empresa/obtener_empresa.dart';
import 'package:workia/domain/usecases/empresa/agregar_empresa.dart';
import 'package:workia/domain/usecases/empresa/obtener_empresas.dart';
import 'package:workia/domain/usecases/empresa/existe_empresa.dart';

import 'package:workia/domain/usecases/usuarios/agregar_usuario.dart';
import 'package:workia/domain/usecases/usuarios/actualizar_usuario.dart';
import 'package:workia/domain/usecases/usuarios/inactivar_usuario.dart';
import 'package:workia/domain/usecases/usuarios/obtener_usuarios.dart';
import 'package:workia/domain/usecases/usuarios/login_usuario.dart';
import 'package:workia/domain/usecases/usuarios/email_existente.dart';

import 'package:workia/domain/usecases/problemas/agregar_problema.dart';
import 'package:workia/domain/usecases/problemas/ignorar_problema.dart';
import 'package:workia/domain/usecases/problemas/resolver_problema.dart';
import 'package:workia/domain/usecases/problemas/obtener_problemas.dart';
import 'package:workia/domain/usecases/problemas/actualizar_problema.dart';
import 'package:workia/domain/usecases/problemas/eliminar_problema.dart';

import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/reportes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';

import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// Entry point for the STGF mobile application.
///
/// This app exposes a simple bottom‑navigation structure with
/// four primary sections: the dashboard (home), jobs, agenda and
/// a catch‑all “More” page.  Selecting the items in the bottom
/// navigation swaps out the main content area.  Additional
/// sections (expenses, balance, configuration, users and AI
/// messages) can be reached via the “More” page.
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:workia/views/agenda/agenda_page.dart';
import 'package:workia/views/clients/clients_page.dart';
import 'package:workia/views/expenses/expenses_page.dart';
import 'package:workia/views/reports/balance_page.dart';
import 'package:workia/views/settings/config_page.dart';
import 'package:workia/views/employees/users_page.dart';

import 'package:workia/views/jobs/mis_trabajos_page.dart';
import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/views/expenses/expense_types_view.dart';

Future<void> main() async {
  // Aseguramos la inicialización de Flutter antes de usar cualquier plugin.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase con la configuración generada en firebase_options.dart.
  // Esto permite usar Firestore, Cloud Functions, autenticación y otros servicios.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configuramos el cliente de Cloud Functions para la región especificada.
  FirebaseFunctions.instanceFor(region: 'us-central1');

  // Ejecutamos la aplicación Flutter.
  runApp(const STGFApp());
}

/// Widget raíz de la aplicación.
class STGFApp extends StatelessWidget {
  const STGFApp({super.key});

  /// Defines the custom Workia color scheme used throughout the
  /// application.  The primary and secondary colors are pulled from
  /// the Workia branding and used to seed the [ColorScheme].  This
  /// theme also customizes buttons, cards and other widgets to
  /// ensure a cohesive look and feel across the entire app.
  ThemeData _buildWorkiaTheme() {
    // Definimos los colores principales de la aplicación para mantener una apariencia
    // consistente en todas las pantallas. Estos valores se usan en barras, botones
    // y otros componentes de Material.
    const workiaPrimary = Colors.blue;
    const workiaSecondary = Colors.blue;
    const workiaError = Color(0xFFEF4444);
    const workiaSurface = Color(0xFFF7F9FC);
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: workiaPrimary,
      primary: workiaPrimary,
      secondary: workiaSecondary,
      error: workiaError,
      surface: workiaSurface,
      brightness: Brightness.light,
      // Colores semánticos usados por componentes de éxito y errores.
      tertiary: const Color(0xFF10B981), // Verde de éxito
      tertiaryContainer: const Color(0xFFD1FAE5), // Fondo verde suave
      errorContainer: const Color(0xFFFEE2E2), // Fondo rojo suave
      surfaceContainerHighest: const Color(
        0xFFE3F2FD,
      ), // Superficie con tinte azul claro
      outline: Colors.grey, // Color de bordes y líneas
    );
    return base.copyWith(
      primaryColor:
          workiaPrimary, // Explicitly set legacy primary color to ensure consistency
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(
        0xFFF5F7FA,
      ), // Light Blue-Grey Background
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFFF5F7FA), // Match Scaffold Background
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B), // Slate 800
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B), // Slate 800
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155), // Slate 700
        ),
        bodyMedium: const TextStyle(color: Color(0xFF334155)), // Slate 700
        bodySmall: const TextStyle(color: Color(0xFF64748B)), // Slate 500
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: workiaPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
      cardTheme:
          const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 2,
            margin: EdgeInsets.only(bottom: 12),
          ).copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: workiaPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: workiaPrimary,
          side: const BorderSide(color: workiaPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minLeadingWidth: 24,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configuración de rutas de navegación con GoRouter.
    // Cada ruta se asocia a una pantalla y/o a datos adicionales.
    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // Recuperamos el estado pasado al navegar desde login.
            final extras = state.extra as Map<String, dynamic>;
            final role = extras['role'] as String;
            final userName = extras['userName'] as String;
            final userId = extras['userId'] as String;
            final empresaId = extras['empresaId'] as String;

            // Definimos qué páginas son visibles según el rol del usuario.
            final Map<String, List<String>> roleScreens = {
              'PERF_ADMIN': [
                'agenda',
                'clientes',
                'mis_trabajos',
                'gastos',
                'balance',
                'usuarios',
                'configuracion',
              ],
              'PERF_FIN': ['gastos', 'balance'],
              'PERF_TEC': ['agenda', 'mis_trabajos'],
            };

            final allowed = roleScreens[role] ?? [];

            return MainApp(
              role: role,
              allowedPages: allowed,
              userName: userName,
              userId: userId,
              empresaId: empresaId,
            );
          },
        ),
      ],
    );

    // Proveedores de dependencias globales. Estos objetos se inyectan
    // una sola vez y estarán disponibles en cualquier punto de la app.
    return MultiProvider(
      providers: [
        Provider<ClienteRepository>(
          create: (_) => ClienteRepositoryFirestore(),
        ),
        Provider<TrabajoRepository>(
          create: (_) => TrabajoRepositoryFirestore(),
        ),
        // Repositorio para trabajos asignados (órdenes de trabajo)
        Provider<TrabajoAsignadoRepository>(
          create: (_) => TrabajoAsignadoRepositoryFirestore(),
        ),
        Provider<GastoRepository>(create: (_) => GastoRepositoryFirestore()),
        Provider<EmpresaRepository>(
          create: (_) => EmpresaRepositoryFirestore(),
        ),

        Provider<ProblemaRepository>(
          create: (_) => ProblemaRepositoryFirestore(),
        ),
        Provider<UsuarioRepository>(
          create: (_) => UsuarioRepositoryFirestore(),
        ),
        // Repositorio para actividades registradas.
        Provider<ActividadRepository>(
          create: (_) => ActividadRepositoryFirestore(),
        ),
        Provider<SesionTrabajoRepository>(
          create: (_) => SesionTrabajoRepositoryFirestore(),
        ),
        // ViewModels
        ChangeNotifierProvider<ClientesViewModel>(
          create: (context) => ClientesViewModel(
            ObtenerClientes(context.read<ClienteRepository>()),
            AgregarCliente(context.read<ClienteRepository>()),
            ActualizarCliente(context.read<ClienteRepository>()),
            InactivarCliente(context.read<ClienteRepository>()),
            BuscarClientes(context.read<ClienteRepository>()),
          ),
        ),
        ChangeNotifierProvider<TrabajosViewModel>(
          create: (context) => TrabajosViewModel(
            ObtenerTrabajos(context.read<TrabajoRepository>()),
            AgregarTrabajo(context.read<TrabajoRepository>()),
            ActualizarTrabajo(context.read<TrabajoRepository>()),
            CancelarTrabajo(context.read<TrabajoRepository>()),
            BuscarTrabajos(context.read<TrabajoRepository>()),
          ),
        ),
        // ViewModel para trabajos asignados.  Se carga la lista de
        // órdenes de trabajo inmediatamente al iniciar la aplicación.
        ChangeNotifierProvider<TrabajosAsignadosViewModel>(
          create: (context) => TrabajosAsignadosViewModel(
            ObtenerTrabajosAsignados(context.read<TrabajoAsignadoRepository>()),
            AgregarTrabajoAsignado(context.read<TrabajoAsignadoRepository>()),
            ActualizarTrabajoAsignado(
              context.read<TrabajoAsignadoRepository>(),
            ),
            CancelarTrabajoAsignado(context.read<TrabajoAsignadoRepository>()),
            BuscarTrabajosAsignados(context.read<TrabajoAsignadoRepository>()),
          ),
        ),
        ChangeNotifierProvider<GastosViewModel>(
          create: (context) => GastosViewModel(
            ObtenerGastos(context.read<GastoRepository>()),
            AgregarGasto(context.read<GastoRepository>()),
            ActualizarGasto(context.read<GastoRepository>()),
            EliminarGasto(context.read<GastoRepository>()),
            GastosPorTipo(context.read<GastoRepository>()),
            GastosPorRango(context.read<GastoRepository>()),
            // El último argumento debe pasarse como parámetro nombrado
            obtenerTiposGasto: ObtenerTiposGasto(
              context.read<GastoRepository>(),
            ),
            agregarTipoGasto: AgregarTipoGasto(context.read<GastoRepository>()),
            actualizarTipoGasto: ActualizarTipoGasto(
              context.read<GastoRepository>(),
            ),
            eliminarTipoGasto: EliminarTipoGasto(
              context.read<GastoRepository>(),
            ),
          ),
        ),
        ChangeNotifierProvider<EmpresaViewModel>(
          create: (context) => EmpresaViewModel(
            obtenerEmpresa: ObtenerEmpresa(context.read<EmpresaRepository>()),
            actualizarEmpresa: ActualizarEmpresa(
              context.read<EmpresaRepository>(),
            ),
            agregarEmpresa: AgregarEmpresa(context.read<EmpresaRepository>()),
            obtenerEmpresas: ObtenerEmpresas(context.read<EmpresaRepository>()),
            existeEmpresa: ExisteEmpresa(context.read<EmpresaRepository>()),
          ),
        ),
        ChangeNotifierProvider<UsuariosViewModel>(
          create: (context) => UsuariosViewModel(
            ObtenerUsuarios(context.read<UsuarioRepository>()),
            AgregarUsuario(context.read<UsuarioRepository>()),
            ActualizarUsuario(context.read<UsuarioRepository>()),
            InactivarUsuario(context.read<UsuarioRepository>()),
            LoginUsuario(context.read<UsuarioRepository>()),
            EmailExistente(context.read<UsuarioRepository>()),
          ),
        ),

        ChangeNotifierProvider<ProblemasViewModel>(
          create: (context) => ProblemasViewModel(
            ObtenerProblemas(context.read<ProblemaRepository>()),
            AgregarProblema(context.read<ProblemaRepository>()),
            IgnorarProblema(context.read<ProblemaRepository>()),
            ResolverProblema(context.read<ProblemaRepository>()),
            ActualizarProblema(context.read<ProblemaRepository>()),
            EliminarProblema(context.read<ProblemaRepository>()),
          ),
        ),
        // ViewModel para actividades.  No se cargan actividades
        // inicialmente; se cargarán bajo demanda en las vistas de
        // actividades.
        ChangeNotifierProvider<ActividadesViewModel>(
          create: (context) => ActividadesViewModel(
            ObtenerActividades(context.read<ActividadRepository>()),
            ObtenerTodasActividades(context.read<ActividadRepository>()),
            AgregarActividad(context.read<ActividadRepository>()),
            ActualizarActividad(context.read<ActividadRepository>()),
            EliminarActividad(context.read<ActividadRepository>()),
          ),
        ),

        // ViewModel para reportes financieros.  Para los ingresos se
        // utilizan las asignaciones de trabajos (trabajosAsignados), ya
        // que el estado y el precio final se almacenan allí.  Se pasa
        // ObtenerTrabajos se usa sólo para resolver el nombre del trabajo
        // en exportaciones (PDF/Excel/CSV); los ingresos se siguen calculando
        // con las asignaciones.  Los gastos se calculan igual.
        ChangeNotifierProvider<ReportesViewModel>(
          create: (context) => ReportesViewModel(
            obtenerTrabajos: ObtenerTrabajos(context.read<TrabajoRepository>()),
            obtenerGastos: ObtenerGastos(context.read<GastoRepository>()),
            obtenerTrabajosAsignados: ObtenerTrabajosAsignados(
              context.read<TrabajoAsignadoRepository>(),
            ),
          ),
        ),
        ChangeNotifierProvider<SesionesViewModel>(
          create: (context) => SesionesViewModel(
            repository: context.read<SesionTrabajoRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // Provider para la sesión del usuario (multi-tenancy)
        ChangeNotifierProvider<UserSessionProvider>(
          create: (_) => UserSessionProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp.router(
            // Aplicación configurada para funcionar con GoRouter y
            // localización. El tema y el idioma se controlan mediante providers.
            title: 'Workia',
            theme: _buildWorkiaTheme(),
            routerConfig: router,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Spanish
            ],
          );
        },
      ),
    );
  }
}

/// Main application scaffold with dynamic navigation based on a
/// user’s role.  The [allowedPages] list determines which
/// sections appear in the bottom navigation bar and in the
/// overflow “Más” menu.  The [role] identifier can be used to
/// customize display (e.g. show avatar initials, etc.).
class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.role,
    required this.allowedPages,
    required this.userName,
    required this.userId,
    required this.empresaId,
  });
  final String role;
  final List<String> allowedPages;
  final String userName;

  /// Identificador único del usuario autenticado.  Se utiliza para
  /// auditar las operaciones de creación y actualización en los
  /// repositorios.
  final String userId;

  /// Identificador de la empresa asociada al usuario.  Se asigna a
  /// los registros creados para filtrar datos por empresa.
  final String empresaId;
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  late List<String> _bottomNavPages;
  late List<String> _overflowPages;

  // Map the page key to its corresponding widget, label and icon.
  late final Map<String, Widget> _pageWidgets;

  final Map<String, IconData> _pageIcons = {
    'agenda': Icons.calendar_today,
    'clientes': Icons.group,
    'mis_trabajos': Icons.work,
    'gastos': Icons.receipt_long,
    'balance': Icons.bar_chart,
    'usuarios': Icons.people,
    'configuracion': Icons.settings,
  };

  @override
  void initState() {
    super.initState();

    // Inicializar la sesión del usuario en el Provider global
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserSessionProvider>().setSession(
        empresaId: widget.empresaId,
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.role,
      );
    });
    // Determine which pages go in the bottom nav and which go in
    // the overflow (Más) menu.  We limit the bottom nav to at
    // most three items; remaining pages go to overflow.
    final allowed = widget.allowedPages;
    if (allowed.length <= 3) {
      _bottomNavPages = List.from(allowed);
      _overflowPages = [];
    } else {
      _bottomNavPages = allowed.take(3).toList();
      _overflowPages = allowed.skip(3).toList();
    }
    // Build the page widgets with the current user's information.
    _pageWidgets = {
      'agenda': AgendaPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'clientes': ClientsPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'mis_trabajos': MisTrabajosPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'gastos': ExpensesPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'balance': BalancePage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'usuarios': UsersPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
      'configuracion': ConfigPage(
        userName: widget.userName,
        role: widget.role,
        userId: widget.userId,
        empresaId: widget.empresaId,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Generate localized labels
    final Map<String, String> pageLabels = {
      'agenda': AppLocalizations.of(context)!.navAgenda,
      'clientes': AppLocalizations.of(context)!.navClients,
      'mis_trabajos': AppLocalizations.of(context)!.navMyJobs,
      'gastos': AppLocalizations.of(context)!.navExpenses,
      'balance': AppLocalizations.of(context)!.navBalance,
      'usuarios': AppLocalizations.of(context)!.navUsers,
      'configuracion': AppLocalizations.of(context)!.navCompanyData,
    };

    // Build list of widgets for bottom nav pages.
    final List<Widget> pageWidgets = _bottomNavPages
        .map((key) => _pageWidgets[key]!)
        .toList();
    // Add a placeholder for overflow if needed.
    if (_overflowPages.isNotEmpty) {
      pageWidgets.add(
        _MoreOverflowPage(
          overflowPages: _overflowPages,
          pageWidgets: _pageWidgets,
          pageIcons: _pageIcons,
          pageLabels: pageLabels,
          userName: widget.userName,
          role: widget.role,
          empresaId: widget.empresaId,
        ),
      );
    }

    return Scaffold(
      body: pageWidgets[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          for (final key in _bottomNavPages)
            BottomNavigationBarItem(
              icon: Icon(_pageIcons[key]),
              label: pageLabels[key],
            ),
          if (_overflowPages.isNotEmpty)
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: AppLocalizations.of(context)!.navMore,
            ),
        ],
      ),
    );
  }
}

/// A page that lists additional pages not shown in the bottom nav.
class _MoreOverflowPage extends StatelessWidget {
  const _MoreOverflowPage({
    required this.overflowPages,
    required this.pageWidgets,
    required this.pageIcons,
    required this.pageLabels,
    required this.userName,
    required this.role,
    required this.empresaId,
  });
  final List<String> overflowPages;
  final Map<String, Widget> pageWidgets;
  final Map<String, IconData> pageIcons;
  final Map<String, String> pageLabels;
  final String userName;
  final String role;
  final String empresaId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.navMore),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      UserSettingsPage(userName: userName, role: role),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _initials(userName),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final key in overflowPages)
            ListTile(
              leading: Icon(
                pageIcons[key],
                color: Theme.of(context).primaryColor,
              ),
              title: Text(pageLabels[key] ?? key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => pageWidgets[key]!));
              },
            ),
          ListTile(
            leading: Icon(
              Icons.receipt_long,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(AppLocalizations.of(context)!.manageExpenseTypes),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseTypesView(empresaId: empresaId),
                ),
              );
            },
          ),
          // Se eliminó la opción de "Cerrar sesión" en esta sección
          // porque la funcionalidad de cerrar sesión está disponible
          // desde la página de configuración del usuario (UserSettingsPage).
        ],
      ),
    );
  }

  /// Helper to compute initials from a name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
