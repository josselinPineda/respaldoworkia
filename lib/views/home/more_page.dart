import 'package:flutter/material.dart';

import 'package:workia/views/expenses/expenses_page.dart';
import 'package:workia/views/expenses/expense_types_view.dart';
import 'package:workia/views/reports/balance_page.dart';
import 'package:workia/views/settings/config_page.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/views/employees/users_page.dart';

/// A simple page that lists links to additional sections of the app
/// not represented directly in the bottom navigation.  Each list
/// item navigates to a new page via [Navigator.push].
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.morePageTitle),
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(AppLocalizations.of(context)!.expensesMenuOption),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExpensesPage(
                      userName: '',
                      role: '',
                      userId: '',
                      empresaId: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(AppLocalizations.of(context)!.balanceMenuOption),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BalancePage(
                      userName: '',
                      role: '',
                      userId: '',
                      empresaId: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              // Provide a clearer description for company settings
              title: Text(AppLocalizations.of(context)!.companyDataMenuOption),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConfigPage(
                      userName: '',
                      role: '',
                      userId: '',
                      empresaId: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(AppLocalizations.of(context)!.usersMenuOption),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UsersPage(
                      userName: '',
                      role: '',
                      userId: '',
                      empresaId: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(AppLocalizations.of(context)!.manageExpenseTypes),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExpenseTypesView(empresaId: ''),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
