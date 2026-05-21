import 'package:flutter/material.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Dashboard page showing a personal agenda overview, metrics,
/// calendar, today’s jobs, quick actions and an activity form.
///
/// This layout is inspired by the high‑fidelity prototypes created
/// earlier in the conversation.  The page is wrapped in a
/// [SingleChildScrollView] so that it scrolls naturally on mobile.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: removed to use global theme
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.agendaTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.agendaSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              _buildMetricsGrid(context),
              const SizedBox(height: 16),
              _buildCalendarSection(context),
              const SizedBox(height: 16),
              _buildTodayJobsSection(context),
              const SizedBox(height: 16),
              _buildQuickActionsSection(context),
              const SizedBox(height: 16),
              _buildRegisterActivityForm(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Top bar with avatar, name, role and icons.
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Text('JP', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Juan Pérez',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Técnico Electricista',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
      ],
    );
  }

  /// Four metric cards laid out in a 2×2 grid.
  Widget _buildMetricsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
        final aspect = w >= 900 ? 2.2 : (w >= 600 ? 2.0 : 1.6);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspect,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              title: AppLocalizations.of(context)!.jobsTodayMetric,
              value: '3',
              color: Colors.blue,
            ),
            _MetricCard(
              title: AppLocalizations.of(context)!.registeredHoursMetric,
              value: '6.5',
              color: Colors.blueGrey, // Semantic neutral for info
            ),
            _MetricCard(
              title: AppLocalizations.of(context)!.completedJobsMetric,
              value: '12',
              color: Colors.green, // Semantic Success
            ),
            _MetricCard(
              title: AppLocalizations.of(context)!.pendingJobsMetric,
              value: '5',
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  /// Calendar heading and a basic placeholder grid for dates.
  Widget _buildCalendarSection(BuildContext context) {
    final TextStyle? headingStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Noviembre 2024', style: headingStyle),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Simple static calendar grid. In a real application you might
        // integrate a calendar widget or package.
        Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.transparent),
          ),
          children: [
            _buildCalendarRow(context, [
              'Dom',
              'Lun',
              'Mar',
              'Mié',
              'Jue',
              'Vie',
              'Sáb',
            ], header: true),
            _buildCalendarRow(context, ['27', '28', '29', '30', '1', '2', '3']),
            _buildCalendarRow(context, ['4', '5', '6', '7', '8', '9', '10']),
            _buildCalendarRow(context, [
              '11',
              '12',
              '13',
              '14',
              '15',
              '16',
              '17',
            ]),
            _buildCalendarRow(context, [
              '18',
              '19',
              '20',
              '21',
              '22',
              '23',
              '24',
            ]),
            _buildCalendarRow(context, [
              '25',
              '26',
              '27',
              '28',
              '29',
              '30',
              '',
            ]),
          ],
        ),
      ],
    );
  }

  /// Helper to build a row for the calendar table.
  TableRow _buildCalendarRow(
    BuildContext context,
    List<String> cells, {
    bool header = false,
  }) {
    return TableRow(
      children: cells
          .map(
            (text) => Container(
              height: header ? 32 : 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: header
                    ? Colors.transparent
                    : (text.isNotEmpty && text == '8'
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: header ? FontWeight.bold : FontWeight.normal,
                  color: header ? Colors.grey[800] : Colors.black,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Section listing today’s jobs with status badges and actions.
  Widget _buildTodayJobsSection(BuildContext context) {
    final TextStyle? sectionTitleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.todayJobsLabel,
          style: sectionTitleStyle,
        ),
        Text(
          'Viernes, 8 de Noviembre',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        _JobCard(
          title: 'Residencial Sur',
          subtitle: 'Instalación eléctrica completa',
          timeRange: '08:00 - 12:00',
          status: AppLocalizations.of(context)!.jobStatusStarted,
          statusColor: Colors.orange, // Iniciado = Naranja
          buttonLabel: 'Registrar Actividad',
        ),
        const SizedBox(height: 8),
        _JobCard(
          title: 'Plaza Comercial',
          subtitle: 'Mantenimiento preventivo',
          timeRange: '13:00 - 16:00',
          status: AppLocalizations.of(context)!.jobStatusOnHold,
          statusColor: Theme.of(context).primaryColor, // En Espera = Primary
          buttonLabel: AppLocalizations.of(context)!.startJobButton,
        ),
        const SizedBox(height: 8),
        _JobCard(
          title: 'Inspección Rutinaria',
          subtitle: 'Revisión de instalaciones',
          timeRange: '16:30 - 18:00',
          status: AppLocalizations.of(context)!.jobStatusOnHold,
          statusColor: Colors.grey,
          buttonLabel: AppLocalizations.of(context)!.viewDetailsButton,
        ),
      ],
    );
  }

  /// Section of quick action buttons.
  Widget _buildQuickActionsSection(BuildContext context) {
    final TextStyle? sectionTitleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActionsTitle,
          style: sectionTitleStyle,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: AppLocalizations.of(context)!.reportProblemAction,
          color: Colors.red,
          onTap: () {},
        ),
        const SizedBox(height: 6),
        _ActionButton(
          label: AppLocalizations.of(context)!.requestMaterialsAction,
          color: Colors.purple,
          onTap: () {},
        ),
        // Removed "Registrar Llegada" and "Ver Historial" actions for Admin.
      ],
    );
  }

  /// Form to register activity.  This is a simplified form containing
  /// only a handful of fields that mirror the design mockups.  In a
  /// real app you’d likely want to extract this form into its own
  /// stateful widget and hook it up to your data layer.
  Widget _buildRegisterActivityForm(BuildContext context) {
    final TextStyle? sectionTitleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.registerJobActivityTitle,
          style: sectionTitleStyle,
        ),
        Text(
          AppLocalizations.of(context)!.registerJobActivityDescription,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        _DropdownField(
          label: AppLocalizations.of(context)!.assignedJobLabel,
          items: const ['Trabajo 1', 'Trabajo 2', 'Trabajo 3'],
        ),
        const SizedBox(height: 12),
        _DateField(label: AppLocalizations.of(context)!.dateLabel),
        const SizedBox(height: 12),
        _DropdownField(
          label: AppLocalizations.of(context)!.jobStatusLabel,
          items: [
            AppLocalizations.of(context)!.jobStatusStarted,
            AppLocalizations.of(context)!.jobStatusFinished,
            AppLocalizations.of(context)!.jobStatusOnHold,
          ],
        ),
        const SizedBox(height: 12),
        _TimeRangeField(),
        const SizedBox(height: 12),
        _MaterialField(),
        const SizedBox(height: 12),
        _NotesField(),
        const SizedBox(height: 12),
        _PhotoUploadField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: Text(AppLocalizations.of(context)!.saveDraftButton),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: Text(
                  AppLocalizations.of(context)!.registerActivityButton,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A reusable card for metric values on the dashboard.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white, // Explicitly lighter than background
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card representing a single job entry.
class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.title,
    required this.subtitle,
    required this.timeRange,
    required this.status,
    required this.statusColor,
    required this.buttonLabel,
  });

  final String title;
  final String subtitle;
  final String timeRange;
  final String status;
  final Color statusColor;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            // Use RGBO for semi‑transparent black shadow
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // Utiliza withAlpha para aplicar un 15% de opacidad al color
                  // de estado sin acceder a las propiedades de canal (red, green, blue).
                  color: statusColor.withAlpha((255 * 0.15).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(timeRange, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable button for quick actions.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Dropdown field widget used in the activity registration form.
class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.items});
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    String? selectedValue = items.isNotEmpty ? items.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              // This simple example doesn’t update selectedValue because
              // StatelessWidget cannot update local state.  In a real
              // app you would use a StatefulWidget or a form key.
            },
          ),
        ),
      ],
    );
  }
}

/// Date picker field.  It shows a text field with a calendar icon
/// and opens a date picker when tapped.
class _DateField extends StatefulWidget {
  const _DateField({required this.label});
  final String label;
  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? _selectedDate;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 1),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : AppLocalizations.of(context)!.selectDatePlaceholder,
                  style: const TextStyle(color: Colors.black87),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Time range picker for start and end times and break duration.
class _TimeRangeField extends StatefulWidget {
  @override
  State<_TimeRangeField> createState() => _TimeRangeFieldState();
}

class _TimeRangeFieldState extends State<_TimeRangeField> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _breakController = TextEditingController(
    text: '30',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timeLogTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        _buildTimePickerRow(
          label: AppLocalizations.of(context)!.startTimeLabel,
          selected: _startTime,
          onSelect: (TimeOfDay time) {
            setState(() => _startTime = time);
          },
        ),
        const SizedBox(height: 8),
        _buildTimePickerRow(
          label: AppLocalizations.of(context)!.endTimeLabel,
          selected: _endTime,
          onSelect: (TimeOfDay time) {
            setState(() => _endTime = time);
          },
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.breakTimeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _breakController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration.collapsed(
                        hintText: AppLocalizations.of(
                          context,
                        )!.breakMinutesHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.minutesLabel),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTotalHoursDisplay(),
      ],
    );
  }

  /// Builds an individual time picker row with label and selected value.
  Widget _buildTimePickerRow({
    required String label,
    required TimeOfDay? selected,
    required ValueChanged<TimeOfDay> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final now = TimeOfDay.now();
            final picked = await showTimePicker(
              context: context,
              initialTime: selected ?? now,
            );
            if (picked != null) {
              onSelect(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected != null
                      ? selected.format(context)
                      : AppLocalizations.of(context)!.selectTimePlaceholder,
                  style: const TextStyle(color: Colors.black87),
                ),
                const Icon(Icons.access_time, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Calculates and displays the total hours based on start, end and break.
  Widget _buildTotalHoursDisplay() {
    double totalHours = 0;
    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final breakMinutes = int.tryParse(_breakController.text) ?? 0;
      final diff = endMinutes - startMinutes - breakMinutes;
      totalHours = diff / 60.0;
      if (totalHours < 0) totalHours = 0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.totalHoursLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            totalHours.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Form fields for material and quantity.
class _MaterialField extends StatefulWidget {
  @override
  State<_MaterialField> createState() => _MaterialFieldState();
}

class _MaterialFieldState extends State<_MaterialField> {
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _unit = 'piezas';

  @override
  void dispose() {
    _materialController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.usedMaterialsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildMaterialRow(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            // In a full app this would add another set of fields.
          },
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addMaterialButton),
        ),
      ],
    );
  }

  Widget _buildMaterialRow() {
    return Column(
      children: [
        TextField(
          controller: _materialController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.materialLabel,
            hintText: AppLocalizations.of(context)!.materialExampleHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.quantityLabel,
                  hintText: '10',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.unitLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'piezas',
                    child: Text(AppLocalizations.of(context)!.unitPieces),
                  ),
                  DropdownMenuItem(
                    value: 'metros',
                    child: Text(AppLocalizations.of(context)!.unitMeters),
                  ),
                  DropdownMenuItem(
                    value: 'litros',
                    child: Text(AppLocalizations.of(context)!.unitLiters),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _unit = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Notes/observations field.
class _NotesField extends StatefulWidget {
  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  final TextEditingController _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.notesObservationsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Describe el trabajo realizado, problemas encontrados, recomendaciones, etc.',
          ),
        ),
      ],
    );
  }
}

/// Photo upload placeholder.  Since file picking isn’t fully
/// functional in this environment, it simply shows a dashed
/// border and a button to simulate selecting files.
class _PhotoUploadField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos del Trabajo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload, size: 40),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.dragPhotosHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                child: Text(AppLocalizations.of(context)!.selectFilesButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
