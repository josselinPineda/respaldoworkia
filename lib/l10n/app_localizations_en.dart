// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Enter';

  @override
  String get registerLink => 'Don\'t have an account? Register';

  @override
  String get credentialsError => 'Please enter your credentials';

  @override
  String get authError => 'Incorrect credentials';

  @override
  String get userSettingsTitle => 'User Settings';

  @override
  String get nameLabel => 'Name';

  @override
  String get logoutButton => 'Logout';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleFinance => 'Finance';

  @override
  String get roleTech => 'Technician';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navClients => 'Clients';

  @override
  String get navMyJobs => 'My Jobs';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navBalance => 'Balance';

  @override
  String get navUsers => 'Users';

  @override
  String get navCompanyData => 'Company Data';

  @override
  String get navMore => 'More';

  @override
  String get languageLabel => 'Language';

  @override
  String get exchangeRateLabel => 'Exchange Rate (USD -> HNL)';

  @override
  String get agendaTitle => 'My Work Agenda';

  @override
  String get agendaSubtitle =>
      'Manage your assigned jobs and register daily activities';

  @override
  String get assignTaskTitle => 'Assign Task';

  @override
  String get taskNameLabel => 'Task Name';

  @override
  String get descriptionLabel => 'Description (optional)';

  @override
  String get assignEmployeeLabel => 'Assign Employee';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get endTimeLabel => 'End Time';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get assignButton => 'Assign';

  @override
  String get registerMaterialExpenseTitle => 'Register Material Expense';

  @override
  String get expenseTypeLabel => 'Expense type';

  @override
  String get manageExpenseTypes => 'Manage expense types';

  @override
  String get addExpenseType => 'Add expense type';

  @override
  String get editExpenseType => 'Edit expense type';

  @override
  String get materialsExpenseLabel => 'Materials';

  @override
  String get fuelExpenseLabel => 'Fuel';

  @override
  String get salariesExpenseLabel => 'Salaries';

  @override
  String get officeExpenseLabel => 'Office';

  @override
  String get expenseDescriptionLabel => 'Expense Description';

  @override
  String get registerButton => 'Register';

  @override
  String get expenseRegisteredMessage =>
      'Expense registered and pending approval.';

  @override
  String get viewDetailsButton => 'View Details';

  @override
  String get startJobButton => 'Start Job';

  @override
  String get registerActivityButton => 'Register activity';

  @override
  String jobsForDateTitle(String date) {
    return 'Jobs for $date';
  }

  @override
  String get noJobsFilterMessage => 'No jobs match the filters.';

  @override
  String get clientLabel => 'Client';

  @override
  String get technicianLabel => 'Technician';

  @override
  String get allLabel => 'All';

  @override
  String get filterByTechnician => 'Filter by Technician';

  @override
  String get noHoursRegistered => 'No hours registered.';

  @override
  String get technicianPrefix => 'Technician: ';

  @override
  String get hoursPrefix => 'Hours: ';

  @override
  String hoursValueShort(String hours) {
    return '$hours h';
  }

  @override
  String get filtersTitle => 'Filters';

  @override
  String get assignmentFilterLabel => 'Filter by assignment';

  @override
  String get showFiltersTooltip => 'Show filters';

  @override
  String get hideFiltersTooltip => 'Hide filters';

  @override
  String get withoutClient => '(No Client)';

  @override
  String get techniciansPrefix => 'Technicians: ';

  @override
  String get jobsTodayMetric => 'Jobs Today';

  @override
  String get registeredHoursMetric => 'Registered Hours';

  @override
  String get completedJobsMetric => 'Completed Jobs';

  @override
  String get financialEvolutionTitle => 'Financial Evolution';

  @override
  String get chartSummaryLabel => 'Summary';

  @override
  String get chartDailyLabel => 'Daily';

  @override
  String get chartCumulativeLabel => 'Cumulative';

  @override
  String get marginLabel => 'Margin';

  @override
  String get pendingJobsMetric => 'Pend. / In Progress';

  @override
  String get problemsTooltip => 'Problems';

  @override
  String get jobNotFoundLabel => 'Job not found';

  @override
  String get jobIdPrefix => 'ID: ';

  @override
  String get clientIdPrefix => 'Client ID: ';

  @override
  String get notesPrefix => 'Notes: ';

  @override
  String get noJobsTodayMessage => 'No jobs assigned for today.';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get reportProblemAction => 'Report Problem';

  @override
  String get registerMaterialsAction => 'Register Materials';

  @override
  String get requestMaterialsAction => 'Request Materials';

  @override
  String get viewProblemsAction => 'View Problems';

  @override
  String get clientsTitle => 'Clients';

  @override
  String get searchClientLabel => 'Search Client';

  @override
  String get activeFilter => 'Active';

  @override
  String get inactiveFilter => 'Inactive';

  @override
  String assignJobsTitle(String name) {
    return 'Assign jobs to $name';
  }

  @override
  String get jobsAssignedMessage => 'Jobs assigned successfully.';

  @override
  String get contactPrefix => 'Contact: ';

  @override
  String get phonePrefix => 'Phone: ';

  @override
  String get emailPrefix => 'Email: ';

  @override
  String get editTooltip => 'Edit';

  @override
  String get costPrefix => 'Cost: ';

  @override
  String get editClientTitle => 'Edit Client';

  @override
  String get newClientTitle => 'New Client';

  @override
  String get selectLocationTitle => 'Select Location';

  @override
  String get searchAddressHint => 'Search Address';

  @override
  String get searchTooltip => 'Search';

  @override
  String get clearButton => 'Clear';

  @override
  String get saveButton => 'Save';

  @override
  String get requiredError => 'Required';

  @override
  String get socialReasonLabel => 'Social Reason';

  @override
  String get contactPersonLabel => 'Contact Person';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel => 'Address';

  @override
  String get locationPrefix => 'Location: ';

  @override
  String get jobsTitle => 'Jobs';

  @override
  String activitiesForJobTitle(String jobTitle) {
    return 'Activities - $jobTitle';
  }

  @override
  String get searchJobLabel => 'Search job';

  @override
  String get reportedProblemsTitle => 'Reported Problems';

  @override
  String get noPendingProblemsMessage => 'No pending problems.';

  @override
  String get typeLabel => 'Type';

  @override
  String get jobPrefix => 'Job: ';

  @override
  String get expensePrefix => 'Expense: ';

  @override
  String get reportedByPrefix => 'Reported by: ';

  @override
  String get referencePrefix => 'Reference: ';

  @override
  String get addressPrefix => 'Address: ';

  @override
  String get closeButton => 'Close';

  @override
  String get myProblemsTitle => 'My problems';

  @override
  String get noReportedProblemsMessage => 'No problems reported.';

  @override
  String get reportNewProblemTitle => 'Report new problem';

  @override
  String get referenceTypePrefix => 'Reference type: ';

  @override
  String get selectJobLabel => 'Select job';

  @override
  String get selectExpenseLabel => 'Select expense';

  @override
  String get titleLabel => 'Title';

  @override
  String get problemDetailsLabel => 'Problem details';

  @override
  String get addressOptionalLabel => 'Address (optional)';

  @override
  String get imagePathOptionalLabel => 'Image path (optional)';

  @override
  String get sendButton => 'Send';

  @override
  String get deleteJobTooltip => 'Delete job';

  @override
  String get deleteJobTitle => 'Delete job';

  @override
  String deleteJobConfirmMessage(String title) {
    return 'Are you sure you want to cancel the job \"$title\"?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get pricePrefix => 'Price: ';

  @override
  String get otherType => 'Other';

  @override
  String get editJobFormTitle => 'Edit Job';

  @override
  String get newJobFormTitle => 'New Job';

  @override
  String get jobInformationSection => 'Job Information';

  @override
  String get descriptionFieldLabel => 'Description';

  @override
  String get costFieldLabel => 'Cost (income) of the job';

  @override
  String get registerTitle => 'Register';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get userProfileLabel => 'User profile';

  @override
  String get administratorRole => 'Administrator';

  @override
  String get registerButtonLabel => 'Register';

  @override
  String get emailAlreadyRegisteredError => 'The email is already registered';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';

  @override
  String get emailVerificationError => 'Error verifying email';

  @override
  String get unexpectedEmailVerificationError =>
      'Unexpected error verifying email';

  @override
  String get accountCreatedSuccessMessage => 'Account created successfully';

  @override
  String get userRegistrationError => 'Error registering user';

  @override
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get invalidEmailError => 'Invalid email';

  @override
  String get minimumCharactersError => 'Minimum 3 characters';

  @override
  String get morePageTitle => 'More';

  @override
  String get expensesMenuOption => 'Expenses';

  @override
  String get balanceMenuOption => 'Balance';

  @override
  String get companyDataMenuOption => 'Company Data';

  @override
  String get usersMenuOption => 'Users';

  @override
  String get companyDataTitle => 'Company Data';

  @override
  String get commercialNameLabel => 'Commercial Name';

  @override
  String get legalNameLabel => 'Legal Name';

  @override
  String get logoUrlLabel => 'Logo URL';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get dataSavedMessage => 'Data saved';

  @override
  String get savedDataTitle => 'Saved Data';

  @override
  String get usersTitle => 'Users';

  @override
  String get searchUserPlaceholder => 'Search user';

  @override
  String get statusFilterLabel => 'Status';

  @override
  String get allOption => 'All';

  @override
  String get activeOption => 'Active';

  @override
  String get inactiveOption => 'Inactive';

  @override
  String get roleFilterLabel => 'Role';

  @override
  String get editUserTooltip => 'Edit user';

  @override
  String get deleteUserTooltip => 'Delete user';

  @override
  String get deleteUserTitle => 'Delete user';

  @override
  String deleteUserConfirmation(String userName) {
    return 'Do you want to deactivate user \"$userName\"?';
  }

  @override
  String get problemsReportedTitle => 'Reported problems';

  @override
  String get noProblemsMessage => 'There are no pending problems.';

  @override
  String get addressFieldLabel => 'Address';

  @override
  String get noMyProblemsMessage => 'No problems reported.';

  @override
  String get optionalAddressLabel => 'Address (optional)';

  @override
  String get optionalImageLabel => 'Image path (optional)';

  @override
  String get problemsPageTitle => 'Problems';

  @override
  String get searchProblemPlaceholder => 'Search problem';

  @override
  String get reporterRoleLabel => 'Reporter role';

  @override
  String get allStatusOption => 'All';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get resolvedStatus => 'Resolved';

  @override
  String get ignoredStatus => 'Ignored';

  @override
  String get noProblemsFilterMessage =>
      'No problems match the selected filters.';

  @override
  String get referenceLabel => 'Reference';

  @override
  String get assignedJobLabel => 'Assigned job';

  @override
  String get jobLabel => 'Job';

  @override
  String get jobIdLabel => 'Job id';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get expenseIdLabel => 'Expense id';

  @override
  String get addressLabelShort => 'Address';

  @override
  String get imageLabel => 'Image';

  @override
  String get reportedByLabel => 'Reported by';

  @override
  String get clientsTab => 'Clients';

  @override
  String get activitiesTab => 'Activities';

  @override
  String get activitiesSectionTitle => 'Activities';

  @override
  String get cyclicalJobLabel => 'Cyclical job';

  @override
  String get confirmDeleteTitle => 'Confirm deletion';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to cancel this job?';

  @override
  String get yesButton => 'Yes';

  @override
  String get noButton => 'No';

  @override
  String get profileLabel => 'Profile';

  @override
  String get clientNamePrefix => 'Name: ';

  @override
  String get legalNamePrefix => 'Legal name: ';

  @override
  String get contactPersonPrefix => 'Contact person: ';

  @override
  String get deleteClientTitle => 'Delete client';

  @override
  String get deleteClientConfirmation =>
      'Are you sure you want to delete this client?';

  @override
  String get assignJobsButton => 'Assign jobs';

  @override
  String get assignJobsDialogTitle => 'Assign jobs';

  @override
  String get searchJobsLabel => 'Search jobs';

  @override
  String get jobsLabel => 'Jobs';

  @override
  String get recurringJobTitle => 'Recurring job';

  @override
  String get finalPriceOptionalLabel => 'Final price (optional)';

  @override
  String get useBasePriceHint => 'Leave empty to use job base price';

  @override
  String get selectDateRangeError => 'Select a date range';

  @override
  String get mustSelectJobError => 'You must select a job';

  @override
  String get newAssignedJobButton => 'New assigned job';

  @override
  String get noAssignedJobsMessage =>
      'There are no assigned jobs for this client.';

  @override
  String get viewActivitiesTooltip => 'View activities';

  @override
  String get unassignTooltip => 'Unassign';

  @override
  String unassignConfirmation(String title) {
    return 'Are you sure you want to unassign job \"$title\" from this client?';
  }

  @override
  String get assignJobsToClientTitle => 'Assign jobs to client';

  @override
  String get jobCostPrefix => 'Cost: ';

  @override
  String get assignNewJobTitle => 'Assign new job';

  @override
  String get finalPriceLabel => 'Final price';

  @override
  String get selectDateRangeButton => 'Select date range';

  @override
  String get rangeLabel => 'Range';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get monthlyOption => 'Monthly';

  @override
  String get quarterlyOption => 'Quarterly';

  @override
  String get semiannualOption => 'Semiannual';

  @override
  String get annualOption => 'Annual';

  @override
  String get techniciansLabel => 'Technicians';

  @override
  String get assignedTechniciansLabel => 'Assigned technicians';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get searchTechnicianLabel => 'Search technician';

  @override
  String get noTechniciansAssignedMessage => 'No technicians assigned';

  @override
  String get mapTabLabel => 'Map';

  @override
  String get selectJobAndDateRangeMessage => 'Select a job and a date range';

  @override
  String get problemTitleLabel => 'Title';

  @override
  String get problemAddressLabel => 'Address (optional)';

  @override
  String get problemImageLabel => 'Image path (optional)';

  @override
  String get registerJobActivityTitle => 'Register job activity';

  @override
  String get registerJobActivityDescription =>
      'Document the hours worked, materials used, and observations';

  @override
  String get jobStatusComplete => 'Complete';

  @override
  String get jobStatusInProgress => 'In progress';

  @override
  String get jobStatusPending => 'Pending';

  @override
  String get jobStatusOnHold => 'ON HOLD';

  @override
  String get jobStatusStarted => 'STARTED';

  @override
  String get jobStatusFinished => 'FINISHED';

  @override
  String get jobStatusClosed => 'CLOSED';

  @override
  String get saveDraftButton => 'Save draft';

  @override
  String get tapCalendarPrompt =>
      'Tap a day on the calendar to open the panel.';

  @override
  String get commercialNamePrefix => 'Commercial name: ';

  @override
  String get logoUrlPrefix => 'Logo URL: ';

  @override
  String get jobUnassignedSuccessfullyMessage => 'Job unassigned successfully.';

  @override
  String get editUserTitle => 'Edit user';

  @override
  String get jobsOfPrefix => 'Jobs of ';

  @override
  String get searchJobOrClientPlaceholder => 'Search job or client...';

  @override
  String get noJobsForRangeMessage => 'No jobs for this range';

  @override
  String get fromDateLabel => 'From date';

  @override
  String get toDateLabel => 'To date';

  @override
  String get todayJobsLabel => 'Today\'s Jobs';

  @override
  String get jobStatusCompleted => 'Completed';

  @override
  String get jobStatusCancelled => 'Cancelled';

  @override
  String get editButton => 'Edit';

  @override
  String get clearFiltersButton => 'Clear Filters';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get pendingExpensesTitle => 'Pending Expenses';

  @override
  String get registeredExpensesTitle => 'Registered Expenses';

  @override
  String get newExpenseTitle => 'New Expense';

  @override
  String get assignAmountTitle => 'Assign amount to expense';

  @override
  String get amountLabel => 'Amount';

  @override
  String get dateLabel => 'Date';

  @override
  String get balanceTitle => 'Balance';

  @override
  String get incomesLabel => 'Incomes';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get netBalanceLabel => 'Net Balance';

  @override
  String get noDataMessage =>
      'No income or expense data for the selected period.';

  @override
  String get thisMonthOption => 'This Month';

  @override
  String get lastMonthOption => 'Last Month';

  @override
  String get lastYearOption => 'Last Year';

  @override
  String get searchJobPlaceholder => 'Search job';

  @override
  String get assignmentLabel => 'Assignment';

  @override
  String get materialsLabel => 'Materials';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get addButton => 'Add';

  @override
  String get selectFormatTitle => 'Select Format';

  @override
  String get selectFormatMessage => 'Choose the format to export the report';

  @override
  String get csvFormatLabel => 'CSV';

  @override
  String get csvDescription => 'Simple, opens in Excel';

  @override
  String get pdfFormatLabel => 'PDF';

  @override
  String get pdfDescription => 'Professional with formatted tables';

  @override
  String get excelFormatLabel => 'Excel (.xlsx)';

  @override
  String get excelDescription => 'Complete and editable';

  @override
  String get technicianFilterLabel => 'Technician';

  @override
  String get clientFilterLabel => 'Client';

  @override
  String get expenseTypeFilterLabel => 'Expense type';

  @override
  String get assignExpenseSuccessMessage => 'Amount assigned successfully.';

  @override
  String get expenseAddedSuccessMessage => 'Expense added successfully.';

  @override
  String get openInGoogleMapsButton => 'Open in Google Maps';

  @override
  String get infoTab => 'Info';

  @override
  String get jobsTab => 'Jobs';

  @override
  String get editAssignmentTitle => 'Edit job assignment';

  @override
  String get assignmentUpdatedMessage => 'Assignment updated successfully.';

  @override
  String get jobAssignedSuccessfullyMessage => 'Job assigned successfully.';

  @override
  String get assignAmountButtonLabel => 'Assign amount';

  @override
  String get englishLanguage => 'English';

  @override
  String get spanishLanguage => 'Spanish';

  @override
  String get registerCompanyTitle => 'Register Company';

  @override
  String get companyEmailLabel => 'Company Email';

  @override
  String get registerAndFinishButton => 'Register and Finish';

  @override
  String get selectCompanyError => 'You must select a company';

  @override
  String get invalidCompanyIdError => 'Company ID is not valid';

  @override
  String get companyLabel => 'Company';

  @override
  String get nextButton => 'Next';

  @override
  String get exportSummarySheet => 'Summary';

  @override
  String get exportIncomeSheet => 'Income';

  @override
  String get exportExpensesSheet => 'Expenses';

  @override
  String get exportBalanceReport => 'Balance Report';

  @override
  String get exportPeriod => 'Period';

  @override
  String get exportConcept => 'Concept';

  @override
  String get exportAmount => 'Amount';

  @override
  String get exportDate => 'Date';

  @override
  String get exportDescription => 'Description';

  @override
  String get exportClient => 'Client';

  @override
  String get exportJob => 'Job';

  @override
  String get exportStartDate => 'Start Date';

  @override
  String get exportEndDate => 'End Date';

  @override
  String get exportTotalIncome => 'Total Income';

  @override
  String get exportTotalExpenses => 'Total Expenses';

  @override
  String get exportNetBalance => 'Net Balance';

  @override
  String get exportNoIncomeMessage => 'No income in this period';

  @override
  String get exportNoExpensesMessage => 'No expenses in this period';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String get markAsResolvedConfirmation =>
      'Are you sure you want to mark this problem as resolved?';

  @override
  String get markAsResolvedButton => 'Mark as Resolved';

  @override
  String get noHistoryProblemsMessage => 'No resolved problems';

  @override
  String get roleReportedByLabel => 'Reported by';

  @override
  String get resolvedByLabel => 'Resolved by';

  @override
  String get referenceTypeLabel => 'Reference Type';

  @override
  String get selectAssignmentLabel => 'Select Assignment';

  @override
  String get responsibleManagementTitle => 'Responsible Management';

  @override
  String get notResolvedStatus => 'Not Resolved';

  @override
  String get editProblemTitle => 'Edit Problem';

  @override
  String get clientPrefix => 'Client: ';

  @override
  String get datePrefix => 'Date: ';

  @override
  String get hoursWorkedPrefix => 'Hours worked: ';

  @override
  String get materialPrefix => 'Material: ';

  @override
  String get noDescriptionLabel => '(No description)';

  @override
  String get activityDescriptionLabel => 'Activity description *';

  @override
  String get hoursWorkedLabel => 'Hours worked *';

  @override
  String get notesLabel => 'Notes (optional)';

  @override
  String get materialsOptionalLabel => 'Materials (Optional)';

  @override
  String get materialNameLabel => 'Material name';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitCostLabel => 'Unit cost';

  @override
  String get activityRegisteredSuccess => 'Activity registered successfully.';

  @override
  String get materialsRegisteredSuccess =>
      'Activity and material expense registered.';

  @override
  String get descriptionAndHoursRequired =>
      'Description and hours are required.';

  @override
  String get mustSelectClient => 'Must select a client.';

  @override
  String get cleanDatesButton => 'Clear Dates';

  @override
  String get filterByStatusLabel => 'Filter by Status';

  @override
  String get inProgressStatus => 'In Progress';

  @override
  String get completedStatus => 'Completed';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get searchClientsLabel => 'Search clients';

  @override
  String get selectTechniciansLabel => 'Select technicians';

  @override
  String get dateRangeLabel => 'Date Range';

  @override
  String get monthlyFrequency => 'Monthly';

  @override
  String get quarterlyFrequency => 'Quarterly';

  @override
  String get semiannualFrequency => 'Semiannual';

  @override
  String get annualFrequency => 'Annual';

  @override
  String get manageAssignmentsTitle => 'Manage Assignments';

  @override
  String get assignmentUpdateNote =>
      'Note: Assignments for all selected clients will be updated. Deselecting does not remove existing assignment (must be done from status).';

  @override
  String get techniciansSectionTitle => 'Technicians';

  @override
  String get selectAtLeastOneClientError =>
      'You must select at least one client';

  @override
  String assignmentsProcessedMessage(int count) {
    return '$count assignments processed successfully';
  }

  @override
  String get reportProblemTitle => 'Report Problem';

  @override
  String get myReportedProblemsTitle => 'My Reported Problems';

  @override
  String get fillTitleAndDetailsError => 'Please fill in title and details';

  @override
  String selectReferenceError(String type) {
    return 'Please select a $type';
  }

  @override
  String get problemReportedSuccess => 'Problem reported successfully';

  @override
  String get selectDateRangeLabel => 'Select date range';

  @override
  String get assignClientLabel => 'Assign Client';

  @override
  String get noClientsAssignedMessage => 'No clients assigned to this job.';

  @override
  String get noClientsFoundMessage => 'No clients found with selected filters.';

  @override
  String get changeStatusTooltip => 'Change status';

  @override
  String get editAssignmentTooltip => 'Edit assignment';

  @override
  String get registerActivityLabel => 'Register Activity';

  @override
  String get noActivitiesMessage =>
      'No activities registered for this job yet.';

  @override
  String get unknownTechnicianLabel => 'Unknown technician';

  @override
  String get unspecifiedClientLabel => 'Client not specified';

  @override
  String clientWithIdLabel(String id) {
    return 'Client (ID: $id)';
  }

  @override
  String get businessNamePrefix => 'Business name: ';

  @override
  String get periodPrefix => 'Period: ';

  @override
  String get nextDatePrefix => 'Next date: ';

  @override
  String get nextLabel => 'Next:';

  @override
  String get outOfRangeTitle => 'Out of range';

  @override
  String outOfRangeMessage(String distance, String maxDistance) {
    return 'You are $distance meters from the job. You must be within ${maxDistance}m.';
  }

  @override
  String get gpsRequiredMessage => 'Please activate GPS';

  @override
  String get locationPermissionDeniedMessage => 'Location permission denied';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Location permissions permanently denied';

  @override
  String get okButton => 'OK';

  @override
  String get dateRangePrefix => 'Range: ';

  @override
  String get selectStartDateError => 'Select a start date';

  @override
  String get fileSavedSuccess => '✓ File saved successfully';

  @override
  String get shareAction => 'Share';

  @override
  String exportError(String error) {
    return 'Error exporting: $error';
  }

  @override
  String get incomeVsExpensesTitle => 'Income vs Expenses';

  @override
  String get accumulatedBalanceTitle => 'Accumulated Balance';

  @override
  String get incomeLabelSingular => 'Income';

  @override
  String get expenseLabelSingular => 'Expense';

  @override
  String get selectDatePlaceholder => 'Select date…';

  @override
  String get selectTimePlaceholder => 'Select time…';

  @override
  String get timeLogTitle => 'Time Log';

  @override
  String get breakTimeLabel => 'Break Time';

  @override
  String get totalHoursLabel => 'Total Hours';

  @override
  String get usedMaterialsLabel => 'Used Materials';

  @override
  String get addMaterialButton => 'Add Material';

  @override
  String get jobStatusLabel => 'Job Status';

  @override
  String get minutesLabel => 'minutes';

  @override
  String get editJobTooltip => 'Edit job';

  @override
  String get emptyForBasePriceHint => 'Leave empty to use job base price';

  @override
  String get startDateLabel => 'Start Date:';

  @override
  String get selectStartDateLabel => 'Select Start Date';

  @override
  String get expenseDetailsTitle => 'Expense Details';

  @override
  String get breakMinutesHint => 'Break (minutes)';

  @override
  String get materialLabel => 'Material';

  @override
  String get materialExampleHint => 'E.g: 12 AWG electrical cable';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitPieces => 'pieces';

  @override
  String get unitMeters => 'meters';

  @override
  String get unitLiters => 'liters';

  @override
  String get notesObservationsLabel => 'Notes and Observations';

  @override
  String get dragPhotosHint => 'Drag photos here or click to select';

  @override
  String get selectFilesButton => 'Select Files';

  @override
  String get statusLabel => 'Status';

  @override
  String get roleLabel => 'Role';

  @override
  String get adminRole => 'Administrator';

  @override
  String get financeRole => 'Finance';

  @override
  String get technicianRole => 'Technician';

  @override
  String get assignedFilter => 'Assigned';

  @override
  String get unassignedFilter => 'Unassigned';

  @override
  String get startButton => 'START';

  @override
  String get finishButton => 'FINISH';

  @override
  String get confirmDeleteActivityMessage =>
      'Are you sure you want to delete this activity?';

  @override
  String get expenseDeleted => 'Expense deleted successfully.';

  @override
  String get resetPasswordAction => 'Reset Password';

  @override
  String get resetPasswordSuccessMessage =>
      'Password reset email sent successfully.';

  @override
  String resetPasswordErrorMessage(String error) {
    return 'Error sending password reset email: $error';
  }

  @override
  String get resetPasswordConfirmTitle => 'Reset Password';

  @override
  String resetPasswordConfirmMessage(String email) {
    return 'Are you sure you want to send a reset email to $email?';
  }

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordDescription =>
      'Enter your email to receive a reset link.';

  @override
  String get emailNotFoundError => 'The email doesn\'t exist';
}
