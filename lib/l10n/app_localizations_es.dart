// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginButton => 'Entrar';

  @override
  String get registerLink => '¿No tienes cuenta? Regístrate';

  @override
  String get credentialsError => 'Por favor ingrese sus credenciales';

  @override
  String get authError => 'Credenciales incorrectas';

  @override
  String get userSettingsTitle => 'Configuración de Usuario';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get logoutButton => 'Cerrar sesión';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleFinance => 'Finanzas';

  @override
  String get roleTech => 'Técnico';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navClients => 'Clientes';

  @override
  String get navMyJobs => 'Mis trabajos';

  @override
  String get navExpenses => 'Gastos';

  @override
  String get navBalance => 'Balance';

  @override
  String get navUsers => 'Usuarios';

  @override
  String get navCompanyData => 'Datos Empresa';

  @override
  String get navMore => 'Más';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get exchangeRateLabel => 'Tasa de Cambio (USD -> HNL)';

  @override
  String get agendaTitle => 'Mi Agenda de Trabajo';

  @override
  String get agendaSubtitle =>
      'Gestiona tus trabajos asignados y registra actividades diarias';

  @override
  String get assignTaskTitle => 'Asignar tarea';

  @override
  String get taskNameLabel => 'Nombre de la tarea';

  @override
  String get descriptionLabel => 'Descripción (opcional)';

  @override
  String get assignEmployeeLabel => 'Asignar empleado';

  @override
  String get startTimeLabel => 'Hora de inicio';

  @override
  String get endTimeLabel => 'Hora de fin';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get assignButton => 'Asignar';

  @override
  String get registerMaterialExpenseTitle => 'Registrar gasto de materiales';

  @override
  String get expenseTypeLabel => 'Tipo de gasto';

  @override
  String get manageExpenseTypes => 'Gestionar tipos de gasto';

  @override
  String get addExpenseType => 'Añadir tipo de gasto';

  @override
  String get editExpenseType => 'Editar tipo de gasto';

  @override
  String get materialsExpenseLabel => 'Materiales';

  @override
  String get fuelExpenseLabel => 'Combustible';

  @override
  String get salariesExpenseLabel => 'Salarios';

  @override
  String get officeExpenseLabel => 'Oficina';

  @override
  String get expenseDescriptionLabel => 'Descripción del gasto';

  @override
  String get registerButton => 'Registrar';

  @override
  String get expenseRegisteredMessage =>
      'Gasto registrado y pendiente de aprobación.';

  @override
  String get viewDetailsButton => 'Ver Detalles';

  @override
  String get startJobButton => 'Iniciar Trabajo';

  @override
  String get registerActivityButton => 'Registrar actividad';

  @override
  String jobsForDateTitle(String date) {
    return 'Trabajos para $date';
  }

  @override
  String get noJobsFilterMessage =>
      'No hay trabajos que coincidan con los filtros.';

  @override
  String get clientLabel => 'Cliente';

  @override
  String get technicianLabel => 'Técnico';

  @override
  String get allLabel => 'Todos';

  @override
  String get filterByTechnician => 'Filtrar por técnico';

  @override
  String get noHoursRegistered => 'No se han registrado horas.';

  @override
  String get technicianPrefix => 'Técnico: ';

  @override
  String get hoursPrefix => 'Horas: ';

  @override
  String hoursValueShort(String hours) {
    return '$hours h';
  }

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get assignmentFilterLabel => 'Filtrar por asignación';

  @override
  String get showFiltersTooltip => 'Mostrar filtros';

  @override
  String get hideFiltersTooltip => 'Ocultar filtros';

  @override
  String get withoutClient => '(Sin cliente)';

  @override
  String get techniciansPrefix => 'Técnicos: ';

  @override
  String get jobsTodayMetric => 'Trabajos Hoy';

  @override
  String get registeredHoursMetric => 'Horas Registradas';

  @override
  String get completedJobsMetric => 'Finalizados / Cerrados';

  @override
  String get financialEvolutionTitle => 'Evolución Financiera';

  @override
  String get chartSummaryLabel => 'Resumen';

  @override
  String get chartDailyLabel => 'Diario';

  @override
  String get chartCumulativeLabel => 'Acumulado';

  @override
  String get marginLabel => 'Margen';

  @override
  String get pendingJobsMetric => 'En Espera / Iniciados';

  @override
  String get problemsTooltip => 'Problemas';

  @override
  String get jobNotFoundLabel => 'Trabajo no encontrado';

  @override
  String get jobIdPrefix => 'ID: ';

  @override
  String get clientIdPrefix => 'ID de Cliente: ';

  @override
  String get notesPrefix => 'Notas: ';

  @override
  String get noJobsTodayMessage => 'No hay trabajos asignados para hoy.';

  @override
  String get quickActionsTitle => 'Acciones Rápidas';

  @override
  String get reportProblemAction => 'Reportar Problema';

  @override
  String get registerMaterialsAction => 'Registrar Materiales';

  @override
  String get requestMaterialsAction => 'Solicitar Materiales';

  @override
  String get viewProblemsAction => 'Ver Problemas';

  @override
  String get clientsTitle => 'Clientes';

  @override
  String get searchClientLabel => 'Buscar cliente';

  @override
  String get activeFilter => 'Activos';

  @override
  String get inactiveFilter => 'Inactivos';

  @override
  String assignJobsTitle(String name) {
    return 'Asignar trabajos a $name';
  }

  @override
  String get jobsAssignedMessage => 'Trabajos asignados correctamente.';

  @override
  String get contactPrefix => 'Contacto: ';

  @override
  String get phonePrefix => 'Teléfono: ';

  @override
  String get emailPrefix => 'Correo: ';

  @override
  String get editTooltip => 'Editar';

  @override
  String get costPrefix => 'Costo: ';

  @override
  String get editClientTitle => 'Editar cliente';

  @override
  String get newClientTitle => 'Nuevo cliente';

  @override
  String get selectLocationTitle => 'Seleccionar ubicación';

  @override
  String get searchAddressHint => 'Buscar dirección';

  @override
  String get searchTooltip => 'Buscar';

  @override
  String get clearButton => 'Limpiar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get requiredError => 'Requerido';

  @override
  String get socialReasonLabel => 'Razón Social';

  @override
  String get contactPersonLabel => 'Persona de Contacto';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get locationPrefix => 'Ubicación: ';

  @override
  String get jobsTitle => 'Trabajos';

  @override
  String activitiesForJobTitle(String jobTitle) {
    return 'Actividades - $jobTitle';
  }

  @override
  String get searchJobLabel => 'Buscar trabajo';

  @override
  String get reportedProblemsTitle => 'Problemas Reportados';

  @override
  String get noPendingProblemsMessage => 'No hay problemas pendientes.';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get jobPrefix => 'Trabajo: ';

  @override
  String get expensePrefix => 'Gasto: ';

  @override
  String get reportedByPrefix => 'Reportado por: ';

  @override
  String get referencePrefix => 'Referencia: ';

  @override
  String get addressPrefix => 'Dirección: ';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get myProblemsTitle => 'Mis Problemas';

  @override
  String get noReportedProblemsMessage => 'No hay problemas reportados.';

  @override
  String get reportNewProblemTitle => 'Reportar nuevo problema';

  @override
  String get referenceTypePrefix => 'Tipo de referencia: ';

  @override
  String get selectJobLabel => 'Seleccionar trabajo';

  @override
  String get selectExpenseLabel => 'Seleccionar gasto';

  @override
  String get titleLabel => 'Título';

  @override
  String get problemDetailsLabel => 'Detalles del problema';

  @override
  String get addressOptionalLabel => 'Dirección (opcional)';

  @override
  String get imagePathOptionalLabel => 'Ruta de imagen (opcional)';

  @override
  String get sendButton => 'Enviar';

  @override
  String get deleteJobTooltip => 'Eliminar trabajo';

  @override
  String get deleteJobTitle => 'Eliminar trabajo';

  @override
  String deleteJobConfirmMessage(String title) {
    return '¿Está seguro de que desea cancelar el trabajo \"$title\"?';
  }

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get pricePrefix => 'Precio: ';

  @override
  String get otherType => 'Otro';

  @override
  String get editJobFormTitle => 'Editar trabajo';

  @override
  String get newJobFormTitle => 'Nuevo trabajo';

  @override
  String get jobInformationSection => 'Información del trabajo';

  @override
  String get descriptionFieldLabel => 'Descripción';

  @override
  String get costFieldLabel => 'Costo (ingreso) del trabajo';

  @override
  String get registerTitle => 'Registro';

  @override
  String get createAccountTitle => 'Crear cuenta';

  @override
  String get emailFieldLabel => 'Correo';

  @override
  String get confirmPasswordLabel => 'Confirmar Contraseña';

  @override
  String get userProfileLabel => 'Perfil de usuario';

  @override
  String get administratorRole => 'Administrador';

  @override
  String get registerButtonLabel => 'Registrar';

  @override
  String get emailAlreadyRegisteredError => 'El correo ya está registrado';

  @override
  String get passwordsDoNotMatchError => 'Las contraseñas no coinciden';

  @override
  String get emailVerificationError => 'Error al verificar el correo';

  @override
  String get unexpectedEmailVerificationError =>
      'Error inesperado al verificar el correo';

  @override
  String get accountCreatedSuccessMessage => 'Cuenta creada con éxito';

  @override
  String get userRegistrationError => 'Error al registrar el usuario';

  @override
  String unexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get invalidEmailError => 'Correo inválido';

  @override
  String get minimumCharactersError => 'Mínimo 3 caracteres';

  @override
  String get morePageTitle => 'Más';

  @override
  String get expensesMenuOption => 'Gastos';

  @override
  String get balanceMenuOption => 'Balance';

  @override
  String get companyDataMenuOption => 'Datos de la Empresa';

  @override
  String get usersMenuOption => 'Usuarios';

  @override
  String get companyDataTitle => 'Datos de la Empresa';

  @override
  String get commercialNameLabel => 'Nombre Comercial';

  @override
  String get legalNameLabel => 'Razón Social';

  @override
  String get logoUrlLabel => 'URL del Logo';

  @override
  String get saveChangesButton => 'Guardar Cambios';

  @override
  String get dataSavedMessage => 'Datos guardados';

  @override
  String get savedDataTitle => 'Datos Guardados';

  @override
  String get usersTitle => 'Usuarios';

  @override
  String get searchUserPlaceholder => 'Buscar usuario';

  @override
  String get statusFilterLabel => 'Estado';

  @override
  String get allOption => 'Todos';

  @override
  String get activeOption => 'Activos';

  @override
  String get inactiveOption => 'Inactivos';

  @override
  String get roleFilterLabel => 'Rol';

  @override
  String get editUserTooltip => 'Editar usuario';

  @override
  String get deleteUserTooltip => 'Eliminar usuario';

  @override
  String get deleteUserTitle => 'Eliminar usuario';

  @override
  String deleteUserConfirmation(String userName) {
    return '¿Desea desactivar al usuario \"$userName\"?';
  }

  @override
  String get problemsReportedTitle => 'Problemas Reportados';

  @override
  String get noProblemsMessage => 'No hay problemas pendientes.';

  @override
  String get addressFieldLabel => 'Dirección';

  @override
  String get noMyProblemsMessage => 'No hay problemas reportados.';

  @override
  String get optionalAddressLabel => 'Dirección (opcional)';

  @override
  String get optionalImageLabel => 'Ruta de imagen (opcional)';

  @override
  String get problemsPageTitle => 'Problemas';

  @override
  String get searchProblemPlaceholder => 'Buscar problema';

  @override
  String get reporterRoleLabel => 'Rol del reportante';

  @override
  String get allStatusOption => 'Todos';

  @override
  String get pendingStatus => 'Pendientes';

  @override
  String get resolvedStatus => 'Resueltos';

  @override
  String get ignoredStatus => 'Ignorados';

  @override
  String get noProblemsFilterMessage =>
      'No hay problemas que coincidan con los filtros.';

  @override
  String get referenceLabel => 'Referencia';

  @override
  String get assignedJobLabel => 'Trabajo asignado';

  @override
  String get jobLabel => 'Trabajo';

  @override
  String get jobIdLabel => 'Trabajo id';

  @override
  String get expenseLabel => 'Gasto';

  @override
  String get expenseIdLabel => 'Gasto id';

  @override
  String get addressLabelShort => 'Dirección';

  @override
  String get imageLabel => 'Imagen';

  @override
  String get reportedByLabel => 'Reportado por';

  @override
  String get clientsTab => 'Clientes';

  @override
  String get activitiesTab => 'Actividades';

  @override
  String get activitiesSectionTitle => 'Actividades';

  @override
  String get cyclicalJobLabel => 'Trabajo cíclico';

  @override
  String get confirmDeleteTitle => 'Confirmar eliminación';

  @override
  String get confirmDeleteMessage =>
      '¿Estás seguro de que deseas cancelar este trabajo?';

  @override
  String get yesButton => 'Sí';

  @override
  String get noButton => 'No';

  @override
  String get profileLabel => 'Perfil';

  @override
  String get clientNamePrefix => 'Nombre: ';

  @override
  String get legalNamePrefix => 'Razón social: ';

  @override
  String get contactPersonPrefix => 'Persona de contacto: ';

  @override
  String get deleteClientTitle => 'Eliminar cliente';

  @override
  String get deleteClientConfirmation =>
      '¿Está seguro de que desea eliminar este cliente?';

  @override
  String get assignJobsButton => 'Asignar trabajos';

  @override
  String get assignJobsDialogTitle => 'Asignar trabajos';

  @override
  String get searchJobsLabel => 'Buscar trabajos';

  @override
  String get jobsLabel => 'Trabajos';

  @override
  String get recurringJobTitle => 'Trabajo cíclico';

  @override
  String get finalPriceOptionalLabel => 'Precio final (opcional)';

  @override
  String get useBasePriceHint =>
      'Dejar vacío para usar precio base del trabajo';

  @override
  String get selectDateRangeError => 'Seleccione un rango de fechas';

  @override
  String get mustSelectJobError => 'Debe seleccionar un trabajo';

  @override
  String get newAssignedJobButton => 'Nuevo trabajo asignado';

  @override
  String get noAssignedJobsMessage =>
      'No hay trabajos asignados a este cliente.';

  @override
  String get viewActivitiesTooltip => 'Ver actividades';

  @override
  String get unassignTooltip => 'Desasignar';

  @override
  String unassignConfirmation(String title) {
    return '¿Está seguro de desasignar el trabajo \"$title\" de este cliente?';
  }

  @override
  String get assignJobsToClientTitle => 'Asignar trabajos al cliente';

  @override
  String get jobCostPrefix => 'Costo: ';

  @override
  String get assignNewJobTitle => 'Asignar nuevo trabajo';

  @override
  String get finalPriceLabel => 'Precio final';

  @override
  String get selectDateRangeButton => 'Seleccionar rango de fechas';

  @override
  String get rangeLabel => 'Rango';

  @override
  String get frequencyLabel => 'Frecuencia';

  @override
  String get monthlyOption => 'Mensual';

  @override
  String get quarterlyOption => 'Trimestral';

  @override
  String get semiannualOption => 'Semestral';

  @override
  String get annualOption => 'Anual';

  @override
  String get techniciansLabel => 'Técnicos';

  @override
  String get assignedTechniciansLabel => 'Técnicos asignados';

  @override
  String get openInGoogleMaps => 'Abrir en Google Maps';

  @override
  String get searchTechnicianLabel => 'Buscar técnico';

  @override
  String get noTechniciansAssignedMessage => 'No hay técnicos asignados';

  @override
  String get mapTabLabel => 'Mapa';

  @override
  String get selectJobAndDateRangeMessage =>
      'Seleccione un trabajo y un rango de fechas';

  @override
  String get problemTitleLabel => 'Título';

  @override
  String get problemAddressLabel => 'Dirección (opcional)';

  @override
  String get problemImageLabel => 'Ruta de imagen (opcional)';

  @override
  String get registerJobActivityTitle => 'Registrar Actividad de Trabajo';

  @override
  String get registerJobActivityDescription =>
      'Documenta las horas trabajadas, materiales utilizados y observaciones';

  @override
  String get jobStatusComplete => 'Completo';

  @override
  String get jobStatusInProgress => 'En Progreso';

  @override
  String get jobStatusPending => 'Pendiente';

  @override
  String get jobStatusOnHold => 'EN ESPERA';

  @override
  String get jobStatusStarted => 'INICIADO';

  @override
  String get jobStatusFinished => 'FINALIZADO';

  @override
  String get jobStatusClosed => 'CERRADO';

  @override
  String get saveDraftButton => 'Guardar borrador';

  @override
  String get tapCalendarPrompt =>
      'Toca un día en el calendario para abrir el panel.';

  @override
  String get commercialNamePrefix => 'Nombre Comercial: ';

  @override
  String get logoUrlPrefix => 'Logo URL: ';

  @override
  String get jobUnassignedSuccessfullyMessage =>
      'Trabajo desasignado correctamente.';

  @override
  String get editUserTitle => 'Editar usuario';

  @override
  String get jobsOfPrefix => 'Trabajos de ';

  @override
  String get searchJobOrClientPlaceholder => 'Buscar trabajo o cliente...';

  @override
  String get noJobsForRangeMessage => 'Sin trabajos para este rango';

  @override
  String get fromDateLabel => 'Desde';

  @override
  String get toDateLabel => 'Hasta';

  @override
  String get todayJobsLabel => 'Trabajos de Hoy';

  @override
  String get jobStatusCompleted => 'Completado';

  @override
  String get jobStatusCancelled => 'CANCELADO';

  @override
  String get editButton => 'Editar';

  @override
  String get clearFiltersButton => 'Limpiar Filtros';

  @override
  String get expensesTitle => 'Gastos';

  @override
  String get pendingExpensesTitle => 'Gastos pendientes';

  @override
  String get registeredExpensesTitle => 'Gastos registrados';

  @override
  String get newExpenseTitle => 'Nuevo Gasto';

  @override
  String get assignAmountTitle => 'Asignar monto al gasto';

  @override
  String get amountLabel => 'Monto';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get balanceTitle => 'Balance';

  @override
  String get incomesLabel => 'Ingresos';

  @override
  String get expensesLabel => 'Gastos';

  @override
  String get netBalanceLabel => 'Balance Neto';

  @override
  String get noDataMessage =>
      'No hay datos de ingresos o gastos para el periodo seleccionado.';

  @override
  String get thisMonthOption => 'Este Mes';

  @override
  String get lastMonthOption => 'Último Mes';

  @override
  String get lastYearOption => 'Último Año';

  @override
  String get searchJobPlaceholder => 'Buscar trabajo';

  @override
  String get assignmentLabel => 'Asignación';

  @override
  String get materialsLabel => 'Materiales';

  @override
  String get descriptionOptionalLabel => 'Descripción (opcional)';

  @override
  String get addButton => 'Agregar';

  @override
  String get selectFormatTitle => 'Seleccionar Formato';

  @override
  String get selectFormatMessage =>
      'Elige el formato en el que deseas exportar el reporte';

  @override
  String get csvFormatLabel => 'CSV';

  @override
  String get csvDescription => 'Simple, se abre en Excel';

  @override
  String get pdfFormatLabel => 'PDF';

  @override
  String get pdfDescription => 'Profesional con tablas formateadas';

  @override
  String get excelFormatLabel => 'Excel (.xlsx)';

  @override
  String get excelDescription => 'Completo y editable';

  @override
  String get technicianFilterLabel => 'Técnico';

  @override
  String get clientFilterLabel => 'Cliente';

  @override
  String get expenseTypeFilterLabel => 'Tipo de gasto';

  @override
  String get assignExpenseSuccessMessage => 'Monto asignado correctamente.';

  @override
  String get expenseAddedSuccessMessage => 'Gasto agregado correctamente.';

  @override
  String get openInGoogleMapsButton => 'Abrir en Google Maps';

  @override
  String get infoTab => 'Info';

  @override
  String get jobsTab => 'Trabajos';

  @override
  String get editAssignmentTitle => 'Editar asignación de trabajo';

  @override
  String get assignmentUpdatedMessage =>
      'Asignación actualizada correctamente.';

  @override
  String get jobAssignedSuccessfullyMessage =>
      'Trabajo asignado correctamente.';

  @override
  String get assignAmountButtonLabel => 'Asignar monto';

  @override
  String get englishLanguage => 'Inglés';

  @override
  String get spanishLanguage => 'Español';

  @override
  String get registerCompanyTitle => 'Registrar Empresa';

  @override
  String get companyEmailLabel => 'Email de Empresa';

  @override
  String get registerAndFinishButton => 'Registrar y Finalizar';

  @override
  String get selectCompanyError => 'Debe seleccionar una empresa';

  @override
  String get invalidCompanyIdError => 'El ID de empresa no es válido';

  @override
  String get companyLabel => 'Empresa';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get exportSummarySheet => 'Resumen';

  @override
  String get exportIncomeSheet => 'Ingresos';

  @override
  String get exportExpensesSheet => 'Gastos';

  @override
  String get exportBalanceReport => 'Reporte de Balance';

  @override
  String get exportPeriod => 'Período';

  @override
  String get exportConcept => 'Concepto';

  @override
  String get exportAmount => 'Monto';

  @override
  String get exportDate => 'Fecha';

  @override
  String get exportDescription => 'Descripción';

  @override
  String get exportClient => 'Cliente';

  @override
  String get exportJob => 'Trabajo';

  @override
  String get exportStartDate => 'Fecha Inicio';

  @override
  String get exportEndDate => 'Fecha Fin';

  @override
  String get exportTotalIncome => 'Ingresos Totales';

  @override
  String get exportTotalExpenses => 'Gastos Totales';

  @override
  String get exportNetBalance => 'Balance Neto';

  @override
  String get exportNoIncomeMessage => 'Sin ingresos en este período';

  @override
  String get exportNoExpensesMessage => 'Sin gastos en este período';

  @override
  String get confirmTitle => 'Confirmar';

  @override
  String get markAsResolvedConfirmation =>
      '¿Está seguro que desea marcar este problema como resuelto?';

  @override
  String get markAsResolvedButton => 'Marcar como Resuelto';

  @override
  String get noHistoryProblemsMessage => 'No hay problemas resueltos';

  @override
  String get roleReportedByLabel => 'Reportado por';

  @override
  String get resolvedByLabel => 'Resuelto por';

  @override
  String get referenceTypeLabel => 'Tipo de Referencia';

  @override
  String get selectAssignmentLabel => 'Seleccionar Asignación';

  @override
  String get responsibleManagementTitle => 'Gestión de Responsables';

  @override
  String get notResolvedStatus => 'No Resuelto';

  @override
  String get editProblemTitle => 'Editar Problema';

  @override
  String get clientPrefix => 'Cliente: ';

  @override
  String get datePrefix => 'Fecha: ';

  @override
  String get hoursWorkedPrefix => 'Horas trabajadas: ';

  @override
  String get materialPrefix => 'Material: ';

  @override
  String get noDescriptionLabel => '(Sin descripción)';

  @override
  String get activityDescriptionLabel => 'Descripción de la actividad *';

  @override
  String get hoursWorkedLabel => 'Horas trabajadas *';

  @override
  String get notesLabel => 'Notas (opcional)';

  @override
  String get materialsOptionalLabel => 'Materiales (Opcional)';

  @override
  String get materialNameLabel => 'Nombre del material';

  @override
  String get quantityLabel => 'Cantidad';

  @override
  String get unitCostLabel => 'Costo unitario';

  @override
  String get activityRegisteredSuccess => 'Actividad registrada exitosamente.';

  @override
  String get materialsRegisteredSuccess =>
      'Actividad y gasto de material registrados.';

  @override
  String get descriptionAndHoursRequired =>
      'La descripción y las horas son requeridas.';

  @override
  String get mustSelectClient => 'Debe seleccionar un cliente.';

  @override
  String get cleanDatesButton => 'Limpiar fechas';

  @override
  String get filterByStatusLabel => 'Estado';

  @override
  String get inProgressStatus => 'En Progreso';

  @override
  String get completedStatus => 'Finalizado';

  @override
  String get cancelledStatus => 'Cancelado';

  @override
  String get searchClientsLabel => 'Buscar clientes';

  @override
  String get selectTechniciansLabel => 'Seleccionar técnicos';

  @override
  String get dateRangeLabel => 'Rango de fechas';

  @override
  String get monthlyFrequency => 'Mensual';

  @override
  String get quarterlyFrequency => 'Trimestral';

  @override
  String get semiannualFrequency => 'Semestral';

  @override
  String get annualFrequency => 'Anual';

  @override
  String get manageAssignmentsTitle => 'Administrar Asignaciones';

  @override
  String get assignmentUpdateNote =>
      'Nota: Se actualizarán las asignaciones de todos los clientes seleccionados. Deseleccionar no elimina la asignación existente (debe hacerlo desde el estado).';

  @override
  String get techniciansSectionTitle => 'Técnicos';

  @override
  String get selectAtLeastOneClientError =>
      'Debe seleccionar al menos un cliente';

  @override
  String assignmentsProcessedMessage(int count) {
    return 'Se procesaron $count asignaciones correctamente';
  }

  @override
  String get reportProblemTitle => 'Reportar Problema';

  @override
  String get myReportedProblemsTitle => 'Mis Problemas Reportados';

  @override
  String get fillTitleAndDetailsError =>
      'Por favor complete el título y los detalles';

  @override
  String selectReferenceError(String type) {
    return 'Por favor seleccione un $type';
  }

  @override
  String get problemReportedSuccess => 'Problema reportado exitosamente';

  @override
  String get selectDateRangeLabel => 'Seleccionar rango de fechas';

  @override
  String get assignClientLabel => 'Asignar Cliente';

  @override
  String get noClientsAssignedMessage =>
      'No hay clientes asignados a este trabajo.';

  @override
  String get noClientsFoundMessage =>
      'No se encontraron clientes con los filtros seleccionados.';

  @override
  String get changeStatusTooltip => 'Cambiar estado';

  @override
  String get editAssignmentTooltip => 'Editar asignación';

  @override
  String get registerActivityLabel => 'Registrar Actividad';

  @override
  String get noActivitiesMessage =>
      'Aún no hay actividades registradas para este trabajo.';

  @override
  String get unknownTechnicianLabel => 'Técnico desconocido';

  @override
  String get unspecifiedClientLabel => 'Cliente no especificado';

  @override
  String clientWithIdLabel(String id) {
    return 'Cliente (ID: $id)';
  }

  @override
  String get businessNamePrefix => 'Razón social: ';

  @override
  String get periodPrefix => 'Período: ';

  @override
  String get nextDatePrefix => 'Próxima fecha: ';

  @override
  String get nextLabel => 'Próxima:';

  @override
  String get outOfRangeTitle => 'Fuera de rango';

  @override
  String outOfRangeMessage(String distance, String maxDistance) {
    return 'Estás a $distance metros del trabajo. Debes estar a menos de ${maxDistance}m.';
  }

  @override
  String get gpsRequiredMessage => 'Por favor activa el GPS';

  @override
  String get locationPermissionDeniedMessage => 'Permiso de ubicación denegado';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Permisos de ubicación denegados permanentemente';

  @override
  String get okButton => 'OK';

  @override
  String get dateRangePrefix => 'Rango: ';

  @override
  String get selectStartDateError => 'Seleccione una fecha de inicio';

  @override
  String get fileSavedSuccess => '✓ Archivo guardado exitosamente';

  @override
  String get shareAction => 'Compartir';

  @override
  String exportError(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get incomeVsExpensesTitle => 'Ingresos vs Gastos';

  @override
  String get accumulatedBalanceTitle => 'Balance Acumulado';

  @override
  String get incomeLabelSingular => 'Ingreso';

  @override
  String get expenseLabelSingular => 'Gasto';

  @override
  String get selectDatePlaceholder => 'Seleccionar fecha…';

  @override
  String get selectTimePlaceholder => 'Seleccionar hora…';

  @override
  String get timeLogTitle => 'Registro de Tiempo';

  @override
  String get breakTimeLabel => 'Tiempo de Descanso';

  @override
  String get totalHoursLabel => 'Total Horas';

  @override
  String get usedMaterialsLabel => 'Materiales Utilizados';

  @override
  String get addMaterialButton => 'Agregar Material';

  @override
  String get jobStatusLabel => 'Estado del Trabajo';

  @override
  String get minutesLabel => 'minutos';

  @override
  String get editJobTooltip => 'Editar trabajo';

  @override
  String get emptyForBasePriceHint =>
      'Dejar vacío para usar precio base del trabajo';

  @override
  String get startDateLabel => 'Fecha Inicio:';

  @override
  String get selectStartDateLabel => 'Seleccionar Fecha Inicio';

  @override
  String get expenseDetailsTitle => 'Detalles del Gasto';

  @override
  String get breakMinutesHint => 'Descanso (minutos)';

  @override
  String get materialLabel => 'Material';

  @override
  String get materialExampleHint => 'Ej: Cable eléctrico 12 AWG';

  @override
  String get unitLabel => 'Unidad';

  @override
  String get unitPieces => 'piezas';

  @override
  String get unitMeters => 'metros';

  @override
  String get unitLiters => 'litros';

  @override
  String get notesObservationsLabel => 'Notas y Observaciones';

  @override
  String get dragPhotosHint =>
      'Arrastra fotos aquí o haz clic para seleccionar';

  @override
  String get selectFilesButton => 'Seleccionar Archivos';

  @override
  String get statusLabel => 'Estado';

  @override
  String get roleLabel => 'Rol';

  @override
  String get adminRole => 'Administrador';

  @override
  String get financeRole => 'Finanzas';

  @override
  String get technicianRole => 'Técnico';

  @override
  String get assignedFilter => 'Asignados';

  @override
  String get unassignedFilter => 'No asignados';

  @override
  String get startButton => 'INICIAR';

  @override
  String get finishButton => 'FINALIZAR';

  @override
  String get confirmDeleteActivityMessage =>
      '¿Estás seguro de que deseas eliminar esta actividad?';

  @override
  String get expenseDeleted => 'Gasto eliminado correctamente.';

  @override
  String get resetPasswordAction => 'Restablecer contraseña';

  @override
  String get resetPasswordSuccessMessage =>
      'Correo de restablecimiento enviado correctamente.';

  @override
  String resetPasswordErrorMessage(String error) {
    return 'Error al enviar el correo de restablecimiento: $error';
  }

  @override
  String get resetPasswordConfirmTitle => 'Restablecer contraseña';

  @override
  String resetPasswordConfirmMessage(String email) {
    return '¿Está seguro de que desea enviar un correo de restablecimiento a $email?';
  }

  @override
  String get forgotPasswordLink => '¿Olvidó su contraseña?';

  @override
  String get forgotPasswordDescription =>
      'Ingrese su correo electrónico para recibir un enlace de restablecimiento.';

  @override
  String get emailNotFoundError => 'El correo no existe';

  @override
  String get invalidPhoneError => 'El teléfono no es válido';
}
