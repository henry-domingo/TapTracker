import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app.dart';
import '../cubits/analytics_cubit.dart';
import '../cubits/card_cubit.dart';
import '../cubits/reminder_cubit.dart';
import '../cubits/security_cubit.dart';
import '../cubits/statement_cubit.dart';
import '../models/entities.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TapTracker PH')),
      body: IndexedStack(
        index: index,
        children: const [
          SecurityTab(),
          IngestionTab(),
          CardsTab(),
          TransactionsTab(),
          AnalyticsTab(),
          ReminderTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock), label: 'Security'),
          NavigationDestination(icon: Icon(Icons.picture_as_pdf), label: 'Import'),
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Onboarding & Security Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              value: state.pinEnabled,
              onChanged: context.read<SecurityCubit>().setPinEnabled,
              title: const Text('Enable PIN lock'),
            ),
            SwitchListTile(
              value: state.biometricEnabled,
              onChanged: context.read<SecurityCubit>().setBiometricEnabled,
              title: const Text('Enable biometric lock'),
            ),
            DropdownButtonFormField<AutoLockTimeout>(
              value: state.autoLockTimeout,
              onChanged: (value) {
                if (value != null) {
                  context.read<SecurityCubit>().setAutoLockTimeout(value);
                }
              },
              decoration: const InputDecoration(labelText: 'Auto-lock timeout'),
              items: AutoLockTimeout.values
                  .map((value) => DropdownMenuItem(value: value, child: Text(value.name)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text('Saved PDF Passwords'),
            ...state.savedPdfPasswords.entries.map(
              (entry) => ListTile(
                title: Text(entry.key),
                subtitle: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => context.read<SecurityCubit>().deletePdfPassword(entry.key),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _showAddPasswordDialog(context),
              child: const Text('Add bank PDF password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPasswordDialog(BuildContext context) async {
    final bankController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save bank PDF password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bankController, decoration: const InputDecoration(labelText: 'Bank')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<SecurityCubit>().savePdfPassword(
                    bankController.text.trim(),
                    passwordController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class IngestionTab extends StatelessWidget {
  const IngestionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatementCubit, StatementState>(
      builder: (context, state) {
        final summary = state.parseSummary;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Statement Ingestion & Parsing', style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                context.read<StatementCubit>().setParseSummary(
                      ParseSummary(
                        bankDetected: 'BDO',
                        statementDate: DateTime.now(),
                        dueDate: DateTime.now().add(const Duration(days: 20)),
                        totalAmountDue: 18000,
                        minimumDue: 1800,
                        transactionCount: 24,
                      ),
                    );
              },
              child: const Text('Import PDF (simulated)'),
            ),
            const ListTile(
              title: Text('Share extension support'),
              subtitle: Text('Use platform share sheet to send SOA PDF directly into app.'),
            ),
            if (summary != null) ...[
              TextFormField(
                initialValue: summary.bankDetected,
                decoration: const InputDecoration(labelText: 'Bank detected'),
                onChanged: (value) => context
                    .read<StatementCubit>()
                    .setParseSummary(summary.copyWith(bankDetected: value)),
              ),
              TextFormField(
                initialValue: summary.totalAmountDue.toStringAsFixed(2),
                decoration: const InputDecoration(labelText: 'Total amount due'),
                onChanged: (value) => context.read<StatementCubit>().setParseSummary(
                      summary.copyWith(totalAmountDue: double.tryParse(value) ?? summary.totalAmountDue),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardCubit, CardState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Credit Card Profile Management', style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                context.read<CardCubit>().addCard(
                      bankName: 'BPI',
                      nickname: 'BPI Blue',
                      network: CardNetwork.mastercard,
                      creditLimit: 120000,
                      statementDay: 10,
                      dueDay: 5,
                      colorHex: '#1976D2',
                    );
              },
              child: const Text('Add card (sample)'),
            ),
            ...state.cards.map(
              (card) => Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: hexToColor(card.colorHex)),
                  title: Text('${card.nickname} • ${card.bankName}'),
                  subtitle: Text('₱${card.creditLimit.toStringAsFixed(2)} • ${card.network.name}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'archive') {
                        context.read<CardCubit>().archiveCard(card.id);
                      }
                      if (action == 'delete') {
                        context.read<CardCubit>().deleteCard(card.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'archive', child: Text('Archive')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatementCubit, StatementState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Statements & Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: 'Search merchant or keyword'),
              onChanged: context.read<StatementCubit>().setSearchQuery,
            ),
            ElevatedButton(
              onPressed: () => context.read<StatementCubit>().addManualTransaction(
                    cardId: state.selectedCardId ?? 'manual-card',
                    merchant: 'Grab',
                    category: 'Transport',
                    date: DateTime.now(),
                    amount: 425,
                  ),
              child: const Text('Add manual transaction'),
            ),
            ...state.filteredTransactions.map(
              (tx) => ListTile(
                title: Text(tx.merchant),
                subtitle: Text('${tx.category} • ${tx.date.toIso8601String().split('T').first}'),
                trailing: Text('₱${tx.amount.toStringAsFixed(2)}'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        final cardState = context.watch<CardCubit>().state;
        final statementState = context.watch<StatementCubit>().state;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Analytics, Insights & Budgeting', style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => context.read<AnalyticsCubit>().compute(
                    cards: cardState.cards,
                    transactions: statementState.transactions,
                  ),
              child: const Text('Refresh analytics'),
            ),
            Text('Aggregate utilization: ${state.aggregateUtilization.toStringAsFixed(1)}%'),
            ...state.perCardUtilization.entries.map(
              (entry) => Text(
                '${entry.key}: ${entry.value.toStringAsFixed(1)}% (${utilizationBand(entry.value)})',
              ),
            ),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: state.categoryTotals.entries
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) => PieChartSectionData(
                          value: entry.value.value,
                          title: entry.value.key,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const Text('Financial insights'),
            ...state.insights.map((insight) => ListTile(title: Text(insight))),
          ],
        );
      },
    );
  }
}

class ReminderTab extends StatelessWidget {
  const ReminderTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Payment Reminders & Settlement', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [7, 3, 0]
                  .map(
                    (value) => FilterChip(
                      label: Text('$value day(s) before'),
                      selected: state.offsetDays.contains(value),
                      onSelected: (selected) {
                        final updated = [...state.offsetDays];
                        if (selected) {
                          updated.add(value);
                        } else {
                          updated.remove(value);
                        }
                        context.read<ReminderCubit>().setOffsets(updated.toSet().toList()..sort());
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: context.read<ReminderCubit>().snooze,
              child: const Text('Snooze active reminder'),
            ),
            if (state.snoozed) const Text('Reminder snoozed.'),
          ],
        );
      },
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Data Management, Export & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('Data export'),
          subtitle: Text('Export transactions as CSV, JSON, Excel, and monthly summary PDF.'),
        ),
        ListTile(
          title: Text('Backup & restore'),
          subtitle: Text('Export encrypted local database backup and import restore file.'),
        ),
        ListTile(
          title: Text('Factory reset'),
          subtitle: Text('Clear all local records and saved keychain/keystore credentials.'),
        ),
        ListTile(
          title: Text('Customization'),
          subtitle: Text('Theme: Light/Dark/System • Currency: PHP ₱'),
        ),
      ],
    );
  }
}
