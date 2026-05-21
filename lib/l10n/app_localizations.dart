import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get loginButton;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerLink;

  /// No description provided for @credentialsError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get credentialsError;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect credentials'**
  String get authError;

  /// No description provided for @userSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'User Settings'**
  String get userSettingsTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get roleFinance;

  /// No description provided for @roleTech.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get roleTech;

  /// No description provided for @navAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navMyJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get navMyJobs;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get navBalance;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navCompanyData.
  ///
  /// In en, this message translates to:
  /// **'Company Data'**
  String get navCompanyData;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate (USD -> HNL)'**
  String get exchangeRateLabel;

  /// No description provided for @agendaTitle.
  ///
  /// In en, this message translates to:
  /// **'My Work Agenda'**
  String get agendaTitle;

  /// No description provided for @agendaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your assigned jobs and register daily activities'**
  String get agendaSubtitle;

  /// No description provided for @assignTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Task'**
  String get assignTaskTitle;

  /// No description provided for @taskNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionLabel;

  /// No description provided for @assignEmployeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign Employee'**
  String get assignEmployeeLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @assignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignButton;

  /// No description provided for @registerMaterialExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Material Expense'**
  String get registerMaterialExpenseTitle;

  /// No description provided for @expenseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense type'**
  String get expenseTypeLabel;

  /// No description provided for @manageExpenseTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage expense types'**
  String get manageExpenseTypes;

  /// No description provided for @addExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Add expense type'**
  String get addExpenseType;

  /// No description provided for @editExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Edit expense type'**
  String get editExpenseType;

  /// No description provided for @materialsExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsExpenseLabel;

  /// No description provided for @fuelExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuelExpenseLabel;

  /// No description provided for @salariesExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get salariesExpenseLabel;

  /// No description provided for @officeExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get officeExpenseLabel;

  /// No description provided for @expenseDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense Description'**
  String get expenseDescriptionLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @expenseRegisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense registered and pending approval.'**
  String get expenseRegisteredMessage;

  /// No description provided for @viewDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsButton;

  /// No description provided for @startJobButton.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get startJobButton;

  /// No description provided for @registerActivityButton.
  ///
  /// In en, this message translates to:
  /// **'Register activity'**
  String get registerActivityButton;

  /// No description provided for @jobsForDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs for {date}'**
  String jobsForDateTitle(String date);

  /// No description provided for @noJobsFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'No jobs match the filters.'**
  String get noJobsFilterMessage;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientLabel;

  /// No description provided for @technicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @filterByTechnician.
  ///
  /// In en, this message translates to:
  /// **'Filter by Technician'**
  String get filterByTechnician;

  /// No description provided for @noHoursRegistered.
  ///
  /// In en, this message translates to:
  /// **'No hours registered.'**
  String get noHoursRegistered;

  /// No description provided for @technicianPrefix.
  ///
  /// In en, this message translates to:
  /// **'Technician: '**
  String get technicianPrefix;

  /// No description provided for @hoursPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hours: '**
  String get hoursPrefix;

  /// No description provided for @hoursValueShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String hoursValueShort(String hours);

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @assignmentFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by assignment'**
  String get assignmentFilterLabel;

  /// No description provided for @showFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show filters'**
  String get showFiltersTooltip;

  /// No description provided for @hideFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hideFiltersTooltip;

  /// No description provided for @withoutClient.
  ///
  /// In en, this message translates to:
  /// **'(No Client)'**
  String get withoutClient;

  /// No description provided for @techniciansPrefix.
  ///
  /// In en, this message translates to:
  /// **'Technicians: '**
  String get techniciansPrefix;

  /// No description provided for @jobsTodayMetric.
  ///
  /// In en, this message translates to:
  /// **'Jobs Today'**
  String get jobsTodayMetric;

  /// No description provided for @registeredHoursMetric.
  ///
  /// In en, this message translates to:
  /// **'Registered Hours'**
  String get registeredHoursMetric;

  /// No description provided for @completedJobsMetric.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobsMetric;

  /// No description provided for @financialEvolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Evolution'**
  String get financialEvolutionTitle;

  /// No description provided for @chartSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get chartSummaryLabel;

  /// No description provided for @chartDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get chartDailyLabel;

  /// No description provided for @chartCumulativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cumulative'**
  String get chartCumulativeLabel;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginLabel;

  /// No description provided for @pendingJobsMetric.
  ///
  /// In en, this message translates to:
  /// **'Pend. / In Progress'**
  String get pendingJobsMetric;

  /// No description provided for @problemsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get problemsTooltip;

  /// No description provided for @jobNotFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get jobNotFoundLabel;

  /// No description provided for @jobIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'ID: '**
  String get jobIdPrefix;

  /// No description provided for @clientIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'Client ID: '**
  String get clientIdPrefix;

  /// No description provided for @notesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Notes: '**
  String get notesPrefix;

  /// No description provided for @noJobsTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'No jobs assigned for today.'**
  String get noJobsTodayMessage;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @reportProblemAction.
  ///
  /// In en, this message translates to:
  /// **'Report Problem'**
  String get reportProblemAction;

  /// No description provided for @registerMaterialsAction.
  ///
  /// In en, this message translates to:
  /// **'Register Materials'**
  String get registerMaterialsAction;

  /// No description provided for @requestMaterialsAction.
  ///
  /// In en, this message translates to:
  /// **'Request Materials'**
  String get requestMaterialsAction;

  /// No description provided for @viewProblemsAction.
  ///
  /// In en, this message translates to:
  /// **'View Problems'**
  String get viewProblemsAction;

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsTitle;

  /// No description provided for @searchClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Client'**
  String get searchClientLabel;

  /// No description provided for @activeFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeFilter;

  /// No description provided for @inactiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveFilter;

  /// No description provided for @assignJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign jobs to {name}'**
  String assignJobsTitle(String name);

  /// No description provided for @jobsAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'Jobs assigned successfully.'**
  String get jobsAssignedMessage;

  /// No description provided for @contactPrefix.
  ///
  /// In en, this message translates to:
  /// **'Contact: '**
  String get contactPrefix;

  /// No description provided for @phonePrefix.
  ///
  /// In en, this message translates to:
  /// **'Phone: '**
  String get phonePrefix;

  /// No description provided for @emailPrefix.
  ///
  /// In en, this message translates to:
  /// **'Email: '**
  String get emailPrefix;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @costPrefix.
  ///
  /// In en, this message translates to:
  /// **'Cost: '**
  String get costPrefix;

  /// No description provided for @editClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClientTitle;

  /// No description provided for @newClientTitle.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClientTitle;

  /// No description provided for @selectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocationTitle;

  /// No description provided for @searchAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Search Address'**
  String get searchAddressHint;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @socialReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Social Reason'**
  String get socialReasonLabel;

  /// No description provided for @contactPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPersonLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @locationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Location: '**
  String get locationPrefix;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTitle;

  /// No description provided for @activitiesForJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities - {jobTitle}'**
  String activitiesForJobTitle(String jobTitle);

  /// No description provided for @searchJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Search job'**
  String get searchJobLabel;

  /// No description provided for @reportedProblemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported Problems'**
  String get reportedProblemsTitle;

  /// No description provided for @noPendingProblemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No pending problems.'**
  String get noPendingProblemsMessage;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @jobPrefix.
  ///
  /// In en, this message translates to:
  /// **'Job: '**
  String get jobPrefix;

  /// No description provided for @expensePrefix.
  ///
  /// In en, this message translates to:
  /// **'Expense: '**
  String get expensePrefix;

  /// No description provided for @reportedByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reported by: '**
  String get reportedByPrefix;

  /// No description provided for @referencePrefix.
  ///
  /// In en, this message translates to:
  /// **'Reference: '**
  String get referencePrefix;

  /// No description provided for @addressPrefix.
  ///
  /// In en, this message translates to:
  /// **'Address: '**
  String get addressPrefix;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @myProblemsTitle.
  ///
  /// In en, this message translates to:
  /// **'My problems'**
  String get myProblemsTitle;

  /// No description provided for @noReportedProblemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No problems reported.'**
  String get noReportedProblemsMessage;

  /// No description provided for @reportNewProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report new problem'**
  String get reportNewProblemTitle;

  /// No description provided for @referenceTypePrefix.
  ///
  /// In en, this message translates to:
  /// **'Reference type: '**
  String get referenceTypePrefix;

  /// No description provided for @selectJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Select job'**
  String get selectJobLabel;

  /// No description provided for @selectExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Select expense'**
  String get selectExpenseLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @problemDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Problem details'**
  String get problemDetailsLabel;

  /// No description provided for @addressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptionalLabel;

  /// No description provided for @imagePathOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Image path (optional)'**
  String get imagePathOptionalLabel;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @deleteJobTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete job'**
  String get deleteJobTooltip;

  /// No description provided for @deleteJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete job'**
  String get deleteJobTitle;

  /// No description provided for @deleteJobConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the job \"{title}\"?'**
  String deleteJobConfirmMessage(String title);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @pricePrefix.
  ///
  /// In en, this message translates to:
  /// **'Price: '**
  String get pricePrefix;

  /// No description provided for @otherType.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherType;

  /// No description provided for @editJobFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Job'**
  String get editJobFormTitle;

  /// No description provided for @newJobFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New Job'**
  String get newJobFormTitle;

  /// No description provided for @jobInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Job Information'**
  String get jobInformationSection;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionFieldLabel;

  /// No description provided for @costFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (income) of the job'**
  String get costFieldLabel;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @emailFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @userProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfileLabel;

  /// No description provided for @administratorRole.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administratorRole;

  /// No description provided for @registerButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButtonLabel;

  /// No description provided for @emailAlreadyRegisteredError.
  ///
  /// In en, this message translates to:
  /// **'The email is already registered'**
  String get emailAlreadyRegisteredError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @emailVerificationError.
  ///
  /// In en, this message translates to:
  /// **'Error verifying email'**
  String get emailVerificationError;

  /// No description provided for @unexpectedEmailVerificationError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error verifying email'**
  String get unexpectedEmailVerificationError;

  /// No description provided for @accountCreatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccessMessage;

  /// No description provided for @userRegistrationError.
  ///
  /// In en, this message translates to:
  /// **'Error registering user'**
  String get userRegistrationError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmailError;

  /// No description provided for @minimumCharactersError.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters'**
  String get minimumCharactersError;

  /// No description provided for @morePageTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get morePageTitle;

  /// No description provided for @expensesMenuOption.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesMenuOption;

  /// No description provided for @balanceMenuOption.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceMenuOption;

  /// No description provided for @companyDataMenuOption.
  ///
  /// In en, this message translates to:
  /// **'Company Data'**
  String get companyDataMenuOption;

  /// No description provided for @usersMenuOption.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersMenuOption;

  /// No description provided for @companyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Data'**
  String get companyDataTitle;

  /// No description provided for @commercialNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Commercial Name'**
  String get commercialNameLabel;

  /// No description provided for @legalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal Name'**
  String get legalNameLabel;

  /// No description provided for @logoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo URL'**
  String get logoUrlLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @dataSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Data saved'**
  String get dataSavedMessage;

  /// No description provided for @savedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Data'**
  String get savedDataTitle;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @searchUserPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search user'**
  String get searchUserPlaceholder;

  /// No description provided for @statusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusFilterLabel;

  /// No description provided for @allOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allOption;

  /// No description provided for @activeOption.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeOption;

  /// No description provided for @inactiveOption.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveOption;

  /// No description provided for @roleFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleFilterLabel;

  /// No description provided for @editUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUserTooltip;

  /// No description provided for @deleteUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUserTooltip;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to deactivate user \"{userName}\"?'**
  String deleteUserConfirmation(String userName);

  /// No description provided for @problemsReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported problems'**
  String get problemsReportedTitle;

  /// No description provided for @noProblemsMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no pending problems.'**
  String get noProblemsMessage;

  /// No description provided for @addressFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressFieldLabel;

  /// No description provided for @noMyProblemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No problems reported.'**
  String get noMyProblemsMessage;

  /// No description provided for @optionalAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get optionalAddressLabel;

  /// No description provided for @optionalImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image path (optional)'**
  String get optionalImageLabel;

  /// No description provided for @problemsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get problemsPageTitle;

  /// No description provided for @searchProblemPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search problem'**
  String get searchProblemPlaceholder;

  /// No description provided for @reporterRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reporter role'**
  String get reporterRoleLabel;

  /// No description provided for @allStatusOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStatusOption;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @resolvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolvedStatus;

  /// No description provided for @ignoredStatus.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get ignoredStatus;

  /// No description provided for @noProblemsFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'No problems match the selected filters.'**
  String get noProblemsFilterMessage;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get referenceLabel;

  /// No description provided for @assignedJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned job'**
  String get assignedJobLabel;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get jobLabel;

  /// No description provided for @jobIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Job id'**
  String get jobIdLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabel;

  /// No description provided for @expenseIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense id'**
  String get expenseIdLabel;

  /// No description provided for @addressLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabelShort;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @reportedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get reportedByLabel;

  /// No description provided for @clientsTab.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsTab;

  /// No description provided for @activitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesTab;

  /// No description provided for @activitiesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesSectionTitle;

  /// No description provided for @cyclicalJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Cyclical job'**
  String get cyclicalJobLabel;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this job?'**
  String get confirmDeleteMessage;

  /// No description provided for @yesButton.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesButton;

  /// No description provided for @noButton.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @clientNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Name: '**
  String get clientNamePrefix;

  /// No description provided for @legalNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Legal name: '**
  String get legalNamePrefix;

  /// No description provided for @contactPersonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Contact person: '**
  String get contactPersonPrefix;

  /// No description provided for @deleteClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete client'**
  String get deleteClientTitle;

  /// No description provided for @deleteClientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this client?'**
  String get deleteClientConfirmation;

  /// No description provided for @assignJobsButton.
  ///
  /// In en, this message translates to:
  /// **'Assign jobs'**
  String get assignJobsButton;

  /// No description provided for @assignJobsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign jobs'**
  String get assignJobsDialogTitle;

  /// No description provided for @searchJobsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search jobs'**
  String get searchJobsLabel;

  /// No description provided for @jobsLabel.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsLabel;

  /// No description provided for @recurringJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring job'**
  String get recurringJobTitle;

  /// No description provided for @finalPriceOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Final price (optional)'**
  String get finalPriceOptionalLabel;

  /// No description provided for @useBasePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use job base price'**
  String get useBasePriceHint;

  /// No description provided for @selectDateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Select a date range'**
  String get selectDateRangeError;

  /// No description provided for @mustSelectJobError.
  ///
  /// In en, this message translates to:
  /// **'You must select a job'**
  String get mustSelectJobError;

  /// No description provided for @newAssignedJobButton.
  ///
  /// In en, this message translates to:
  /// **'New assigned job'**
  String get newAssignedJobButton;

  /// No description provided for @noAssignedJobsMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no assigned jobs for this client.'**
  String get noAssignedJobsMessage;

  /// No description provided for @viewActivitiesTooltip.
  ///
  /// In en, this message translates to:
  /// **'View activities'**
  String get viewActivitiesTooltip;

  /// No description provided for @unassignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassignTooltip;

  /// No description provided for @unassignConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unassign job \"{title}\" from this client?'**
  String unassignConfirmation(String title);

  /// No description provided for @assignJobsToClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign jobs to client'**
  String get assignJobsToClientTitle;

  /// No description provided for @jobCostPrefix.
  ///
  /// In en, this message translates to:
  /// **'Cost: '**
  String get jobCostPrefix;

  /// No description provided for @assignNewJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign new job'**
  String get assignNewJobTitle;

  /// No description provided for @finalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get finalPriceLabel;

  /// No description provided for @selectDateRangeButton.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRangeButton;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get rangeLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// No description provided for @monthlyOption.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyOption;

  /// No description provided for @quarterlyOption.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterlyOption;

  /// No description provided for @semiannualOption.
  ///
  /// In en, this message translates to:
  /// **'Semiannual'**
  String get semiannualOption;

  /// No description provided for @annualOption.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualOption;

  /// No description provided for @techniciansLabel.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get techniciansLabel;

  /// No description provided for @assignedTechniciansLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned technicians'**
  String get assignedTechniciansLabel;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @searchTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Search technician'**
  String get searchTechnicianLabel;

  /// No description provided for @noTechniciansAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'No technicians assigned'**
  String get noTechniciansAssignedMessage;

  /// No description provided for @mapTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTabLabel;

  /// No description provided for @selectJobAndDateRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a job and a date range'**
  String get selectJobAndDateRangeMessage;

  /// No description provided for @problemTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get problemTitleLabel;

  /// No description provided for @problemAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get problemAddressLabel;

  /// No description provided for @problemImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image path (optional)'**
  String get problemImageLabel;

  /// No description provided for @registerJobActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Register job activity'**
  String get registerJobActivityTitle;

  /// No description provided for @registerJobActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Document the hours worked, materials used, and observations'**
  String get registerJobActivityDescription;

  /// No description provided for @jobStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get jobStatusComplete;

  /// No description provided for @jobStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobStatusInProgress;

  /// No description provided for @jobStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get jobStatusPending;

  /// No description provided for @jobStatusOnHold.
  ///
  /// In en, this message translates to:
  /// **'ON HOLD'**
  String get jobStatusOnHold;

  /// No description provided for @jobStatusStarted.
  ///
  /// In en, this message translates to:
  /// **'STARTED'**
  String get jobStatusStarted;

  /// No description provided for @jobStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get jobStatusFinished;

  /// No description provided for @jobStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get jobStatusClosed;

  /// No description provided for @saveDraftButton.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraftButton;

  /// No description provided for @tapCalendarPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap a day on the calendar to open the panel.'**
  String get tapCalendarPrompt;

  /// No description provided for @commercialNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Commercial name: '**
  String get commercialNamePrefix;

  /// No description provided for @logoUrlPrefix.
  ///
  /// In en, this message translates to:
  /// **'Logo URL: '**
  String get logoUrlPrefix;

  /// No description provided for @jobUnassignedSuccessfullyMessage.
  ///
  /// In en, this message translates to:
  /// **'Job unassigned successfully.'**
  String get jobUnassignedSuccessfullyMessage;

  /// No description provided for @editUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUserTitle;

  /// No description provided for @jobsOfPrefix.
  ///
  /// In en, this message translates to:
  /// **'Jobs of '**
  String get jobsOfPrefix;

  /// No description provided for @searchJobOrClientPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search job or client...'**
  String get searchJobOrClientPlaceholder;

  /// No description provided for @noJobsForRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'No jobs for this range'**
  String get noJobsForRangeMessage;

  /// No description provided for @fromDateLabel.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get fromDateLabel;

  /// No description provided for @toDateLabel.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get toDateLabel;

  /// No description provided for @todayJobsLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Jobs'**
  String get todayJobsLabel;

  /// No description provided for @jobStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobStatusCompleted;

  /// No description provided for @jobStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobStatusCancelled;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @clearFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFiltersButton;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @pendingExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Expenses'**
  String get pendingExpensesTitle;

  /// No description provided for @registeredExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Expenses'**
  String get registeredExpensesTitle;

  /// No description provided for @newExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get newExpenseTitle;

  /// No description provided for @assignAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign amount to expense'**
  String get assignAmountTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @balanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceTitle;

  /// No description provided for @incomesLabel.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get incomesLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @netBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalanceLabel;

  /// No description provided for @noDataMessage.
  ///
  /// In en, this message translates to:
  /// **'No income or expense data for the selected period.'**
  String get noDataMessage;

  /// No description provided for @thisMonthOption.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthOption;

  /// No description provided for @lastMonthOption.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonthOption;

  /// No description provided for @lastYearOption.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYearOption;

  /// No description provided for @searchJobPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search job'**
  String get searchJobPlaceholder;

  /// No description provided for @assignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignmentLabel;

  /// No description provided for @materialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsLabel;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @selectFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Format'**
  String get selectFormatTitle;

  /// No description provided for @selectFormatMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose the format to export the report'**
  String get selectFormatMessage;

  /// No description provided for @csvFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get csvFormatLabel;

  /// No description provided for @csvDescription.
  ///
  /// In en, this message translates to:
  /// **'Simple, opens in Excel'**
  String get csvDescription;

  /// No description provided for @pdfFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdfFormatLabel;

  /// No description provided for @pdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Professional with formatted tables'**
  String get pdfDescription;

  /// No description provided for @excelFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx)'**
  String get excelFormatLabel;

  /// No description provided for @excelDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete and editable'**
  String get excelDescription;

  /// No description provided for @technicianFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianFilterLabel;

  /// No description provided for @clientFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientFilterLabel;

  /// No description provided for @expenseTypeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense type'**
  String get expenseTypeFilterLabel;

  /// No description provided for @assignExpenseSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Amount assigned successfully.'**
  String get assignExpenseSuccessMessage;

  /// No description provided for @expenseAddedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully.'**
  String get expenseAddedSuccessMessage;

  /// No description provided for @openInGoogleMapsButton.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMapsButton;

  /// No description provided for @infoTab.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoTab;

  /// No description provided for @jobsTab.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTab;

  /// No description provided for @editAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit job assignment'**
  String get editAssignmentTitle;

  /// No description provided for @assignmentUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Assignment updated successfully.'**
  String get assignmentUpdatedMessage;

  /// No description provided for @jobAssignedSuccessfullyMessage.
  ///
  /// In en, this message translates to:
  /// **'Job assigned successfully.'**
  String get jobAssignedSuccessfullyMessage;

  /// No description provided for @assignAmountButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign amount'**
  String get assignAmountButtonLabel;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @spanishLanguage.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanishLanguage;

  /// No description provided for @registerCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Company'**
  String get registerCompanyTitle;

  /// No description provided for @companyEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Email'**
  String get companyEmailLabel;

  /// No description provided for @registerAndFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Register and Finish'**
  String get registerAndFinishButton;

  /// No description provided for @selectCompanyError.
  ///
  /// In en, this message translates to:
  /// **'You must select a company'**
  String get selectCompanyError;

  /// No description provided for @invalidCompanyIdError.
  ///
  /// In en, this message translates to:
  /// **'Company ID is not valid'**
  String get invalidCompanyIdError;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyLabel;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @exportSummarySheet.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get exportSummarySheet;

  /// No description provided for @exportIncomeSheet.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get exportIncomeSheet;

  /// No description provided for @exportExpensesSheet.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get exportExpensesSheet;

  /// No description provided for @exportBalanceReport.
  ///
  /// In en, this message translates to:
  /// **'Balance Report'**
  String get exportBalanceReport;

  /// No description provided for @exportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportPeriod;

  /// No description provided for @exportConcept.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get exportConcept;

  /// No description provided for @exportAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportAmount;

  /// No description provided for @exportDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportDate;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get exportDescription;

  /// No description provided for @exportClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get exportClient;

  /// No description provided for @exportJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get exportJob;

  /// No description provided for @exportStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get exportStartDate;

  /// No description provided for @exportEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get exportEndDate;

  /// No description provided for @exportTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get exportTotalIncome;

  /// No description provided for @exportTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get exportTotalExpenses;

  /// No description provided for @exportNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get exportNetBalance;

  /// No description provided for @exportNoIncomeMessage.
  ///
  /// In en, this message translates to:
  /// **'No income in this period'**
  String get exportNoIncomeMessage;

  /// No description provided for @exportNoExpensesMessage.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get exportNoExpensesMessage;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTitle;

  /// No description provided for @markAsResolvedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this problem as resolved?'**
  String get markAsResolvedConfirmation;

  /// No description provided for @markAsResolvedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Resolved'**
  String get markAsResolvedButton;

  /// No description provided for @noHistoryProblemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No resolved problems'**
  String get noHistoryProblemsMessage;

  /// No description provided for @roleReportedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get roleReportedByLabel;

  /// No description provided for @resolvedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved by'**
  String get resolvedByLabel;

  /// No description provided for @referenceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference Type'**
  String get referenceTypeLabel;

  /// No description provided for @selectAssignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Assignment'**
  String get selectAssignmentLabel;

  /// No description provided for @responsibleManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Responsible Management'**
  String get responsibleManagementTitle;

  /// No description provided for @notResolvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Resolved'**
  String get notResolvedStatus;

  /// No description provided for @editProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Problem'**
  String get editProblemTitle;

  /// No description provided for @clientPrefix.
  ///
  /// In en, this message translates to:
  /// **'Client: '**
  String get clientPrefix;

  /// No description provided for @datePrefix.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get datePrefix;

  /// No description provided for @hoursWorkedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hours worked: '**
  String get hoursWorkedPrefix;

  /// No description provided for @materialPrefix.
  ///
  /// In en, this message translates to:
  /// **'Material: '**
  String get materialPrefix;

  /// No description provided for @noDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'(No description)'**
  String get noDescriptionLabel;

  /// No description provided for @activityDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity description *'**
  String get activityDescriptionLabel;

  /// No description provided for @hoursWorkedLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours worked *'**
  String get hoursWorkedLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesLabel;

  /// No description provided for @materialsOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials (Optional)'**
  String get materialsOptionalLabel;

  /// No description provided for @materialNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Material name'**
  String get materialNameLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get unitCostLabel;

  /// No description provided for @activityRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity registered successfully.'**
  String get activityRegisteredSuccess;

  /// No description provided for @materialsRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity and material expense registered.'**
  String get materialsRegisteredSuccess;

  /// No description provided for @descriptionAndHoursRequired.
  ///
  /// In en, this message translates to:
  /// **'Description and hours are required.'**
  String get descriptionAndHoursRequired;

  /// No description provided for @mustSelectClient.
  ///
  /// In en, this message translates to:
  /// **'Must select a client.'**
  String get mustSelectClient;

  /// No description provided for @cleanDatesButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Dates'**
  String get cleanDatesButton;

  /// No description provided for @filterByStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatusLabel;

  /// No description provided for @inProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @searchClientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get searchClientsLabel;

  /// No description provided for @selectTechniciansLabel.
  ///
  /// In en, this message translates to:
  /// **'Select technicians'**
  String get selectTechniciansLabel;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRangeLabel;

  /// No description provided for @monthlyFrequency.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyFrequency;

  /// No description provided for @quarterlyFrequency.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterlyFrequency;

  /// No description provided for @semiannualFrequency.
  ///
  /// In en, this message translates to:
  /// **'Semiannual'**
  String get semiannualFrequency;

  /// No description provided for @annualFrequency.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualFrequency;

  /// No description provided for @manageAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Assignments'**
  String get manageAssignmentsTitle;

  /// No description provided for @assignmentUpdateNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Assignments for all selected clients will be updated. Deselecting does not remove existing assignment (must be done from status).'**
  String get assignmentUpdateNote;

  /// No description provided for @techniciansSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get techniciansSectionTitle;

  /// No description provided for @selectAtLeastOneClientError.
  ///
  /// In en, this message translates to:
  /// **'You must select at least one client'**
  String get selectAtLeastOneClientError;

  /// No description provided for @assignmentsProcessedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} assignments processed successfully'**
  String assignmentsProcessedMessage(int count);

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Problem'**
  String get reportProblemTitle;

  /// No description provided for @myReportedProblemsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reported Problems'**
  String get myReportedProblemsTitle;

  /// No description provided for @fillTitleAndDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in title and details'**
  String get fillTitleAndDetailsError;

  /// No description provided for @selectReferenceError.
  ///
  /// In en, this message translates to:
  /// **'Please select a {type}'**
  String selectReferenceError(String type);

  /// No description provided for @problemReportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Problem reported successfully'**
  String get problemReportedSuccess;

  /// No description provided for @selectDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRangeLabel;

  /// No description provided for @assignClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign Client'**
  String get assignClientLabel;

  /// No description provided for @noClientsAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'No clients assigned to this job.'**
  String get noClientsAssignedMessage;

  /// No description provided for @noClientsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No clients found with selected filters.'**
  String get noClientsFoundMessage;

  /// No description provided for @changeStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatusTooltip;

  /// No description provided for @editAssignmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit assignment'**
  String get editAssignmentTooltip;

  /// No description provided for @registerActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Register Activity'**
  String get registerActivityLabel;

  /// No description provided for @noActivitiesMessage.
  ///
  /// In en, this message translates to:
  /// **'No activities registered for this job yet.'**
  String get noActivitiesMessage;

  /// No description provided for @unknownTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown technician'**
  String get unknownTechnicianLabel;

  /// No description provided for @unspecifiedClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client not specified'**
  String get unspecifiedClientLabel;

  /// No description provided for @clientWithIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client (ID: {id})'**
  String clientWithIdLabel(String id);

  /// No description provided for @businessNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Business name: '**
  String get businessNamePrefix;

  /// No description provided for @periodPrefix.
  ///
  /// In en, this message translates to:
  /// **'Period: '**
  String get periodPrefix;

  /// No description provided for @nextDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Next date: '**
  String get nextDatePrefix;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next:'**
  String get nextLabel;

  /// No description provided for @outOfRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRangeTitle;

  /// No description provided for @outOfRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} meters from the job. You must be within {maxDistance}m.'**
  String outOfRangeMessage(String distance, String maxDistance);

  /// No description provided for @gpsRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please activate GPS'**
  String get gpsRequiredMessage;

  /// No description provided for @locationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDeniedMessage;

  /// No description provided for @locationPermissionDeniedForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permissions permanently denied'**
  String get locationPermissionDeniedForeverMessage;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @dateRangePrefix.
  ///
  /// In en, this message translates to:
  /// **'Range: '**
  String get dateRangePrefix;

  /// No description provided for @selectStartDateError.
  ///
  /// In en, this message translates to:
  /// **'Select a start date'**
  String get selectStartDateError;

  /// No description provided for @fileSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✓ File saved successfully'**
  String get fileSavedSuccess;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting: {error}'**
  String exportError(String error);

  /// No description provided for @incomeVsExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expenses'**
  String get incomeVsExpensesTitle;

  /// No description provided for @accumulatedBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Balance'**
  String get accumulatedBalanceTitle;

  /// No description provided for @incomeLabelSingular.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabelSingular;

  /// No description provided for @expenseLabelSingular.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabelSingular;

  /// No description provided for @selectDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select date…'**
  String get selectDatePlaceholder;

  /// No description provided for @selectTimePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select time…'**
  String get selectTimePlaceholder;

  /// No description provided for @timeLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Log'**
  String get timeLogTitle;

  /// No description provided for @breakTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Break Time'**
  String get breakTimeLabel;

  /// No description provided for @totalHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get totalHoursLabel;

  /// No description provided for @usedMaterialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Used Materials'**
  String get usedMaterialsLabel;

  /// No description provided for @addMaterialButton.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterialButton;

  /// No description provided for @jobStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Status'**
  String get jobStatusLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesLabel;

  /// No description provided for @editJobTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get editJobTooltip;

  /// No description provided for @emptyForBasePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use job base price'**
  String get emptyForBasePriceHint;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date:'**
  String get startDateLabel;

  /// No description provided for @selectStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get selectStartDateLabel;

  /// No description provided for @expenseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetailsTitle;

  /// No description provided for @breakMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get breakMinutesHint;

  /// No description provided for @materialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialLabel;

  /// No description provided for @materialExampleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: 12 AWG electrical cable'**
  String get materialExampleHint;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get unitPieces;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get unitMeters;

  /// No description provided for @unitLiters.
  ///
  /// In en, this message translates to:
  /// **'liters'**
  String get unitLiters;

  /// No description provided for @notesObservationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes and Observations'**
  String get notesObservationsLabel;

  /// No description provided for @dragPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Drag photos here or click to select'**
  String get dragPhotosHint;

  /// No description provided for @selectFilesButton.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFilesButton;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminRole;

  /// No description provided for @financeRole.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeRole;

  /// No description provided for @technicianRole.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianRole;

  /// No description provided for @assignedFilter.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedFilter;

  /// No description provided for @unassignedFilter.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedFilter;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get finishButton;

  /// No description provided for @confirmDeleteActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this activity?'**
  String get confirmDeleteActivityMessage;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted successfully.'**
  String get expenseDeleted;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordAction;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent successfully.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @resetPasswordErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending password reset email: {error}'**
  String resetPasswordErrorMessage(String error);

  /// No description provided for @resetPasswordConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordConfirmTitle;

  /// No description provided for @resetPasswordConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to send a reset email to {email}?'**
  String resetPasswordConfirmMessage(String email);

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link.'**
  String get forgotPasswordDescription;

  /// No description provided for @emailNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'The email doesn\'t exist'**
  String get emailNotFoundError;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'The phone number is not valid'**
  String get invalidPhoneError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
