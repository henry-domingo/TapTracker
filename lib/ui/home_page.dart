import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app.dart';
import '../core/philippine_banks.dart';
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
          NavigationDestination(
              icon: Icon(Icons.picture_as_pdf), label: 'Import'),
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'Cards'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(
              icon: Icon(Icons.notifications), label: 'Reminders'),
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
            const Text('Onboarding & Security Setup',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              value: state.pinEnabled,
              onChanged: (value) {
                unawaited(context.read<SecurityCubit>().setPinEnabled(value));
              },
              title: const Text('Enable PIN lock'),
            ),
            SwitchListTile(
              value: state.biometricEnabled,
              onChanged: (value) {
                unawaited(
                  context.read<SecurityCubit>().setBiometricEnabled(value),
                );
              },
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
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value.name)))
                  .toList(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                state.biometricsAvailable
                    ? 'Biometric / device authentication available'
                    : 'Biometric / device authentication not available',
              ),
              subtitle: state.lastAuthenticationMessage == null
                  ? null
                  : Text(state.lastAuthenticationMessage!),
              trailing: ElevatedButton(
                onPressed:
                    state.authenticationInProgress || !state.biometricsAvailable
                        ? null
                        : context.read<SecurityCubit>().authenticateBiometrics,
                child: const Text('Authenticate'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Saved PDF Passwords'),
            ...state.savedPdfPasswordBanks.map(
              (bank) => ListTile(
                title: Text(bank),
                subtitle: const Text('••••••••'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      context.read<SecurityCubit>().deletePdfPassword(bank),
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
    await showDialog<void>(
      context: context,
      builder: (context) => const _AddPasswordDialog(),
    );
  }
}

class IngestionTab extends StatefulWidget {
  const IngestionTab({super.key});

  @override
  State<IngestionTab> createState() => _IngestionTabState();
}

class _IngestionTabState extends State<IngestionTab> {
  String? selectedCardId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatementCubit, StatementState>(
      builder: (context, statementState) {
        final cardState = context.watch<CardCubit>().state;
        final activeCards =
            cardState.cards.where((card) => !card.isArchived).toList();
        final effectiveSelectedCardId = selectedCardId != null &&
                activeCards.any((card) => card.id == selectedCardId)
            ? selectedCardId
            : (activeCards.isNotEmpty ? activeCards.first.id : null);

        final summary = statementState.parseSummary;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Statement Ingestion & Parsing',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () async {
                final prompt = await _showImportPrompt(context);
                if (prompt == null) {
                  return;
                }
                if (!context.mounted) {
                  return;
                }
                await context.read<StatementCubit>().importPdf(
                      bankName: prompt.bank,
                      password: prompt.password,
                      rememberPassword: prompt.rememberPassword,
                      onRememberPassword:
                          context.read<SecurityCubit>().savePdfPassword,
                    );
              },
              child: const Text('Import PDF'),
            ),
            if (statementState.importedFileName != null)
              ListTile(
                title: const Text('Imported file'),
                subtitle: Text(statementState.importedFileName!),
              ),
            if (statementState.importStatus == ImportStatus.importing)
              const ListTile(title: Text('Importing and parsing PDF...')),
            if (statementState.importError != null)
              ListTile(
                title: const Text('Import error'),
                subtitle: Text(statementState.importError!),
              ),
            if (statementState.usedFallbackParser)
              const ListTile(
                title: Text('Fallback parser used'),
                subtitle: Text('Please verify parsed metadata before saving.'),
              ),
            if (summary != null) ...[
              const Divider(),
              const Text('Parse Verification',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ListTile(
                title: const Text('Bank'),
                subtitle: Text(summary.bankDetected),
              ),
              ListTile(
                title: const Text('Statement Date'),
                subtitle: Text(_dateText(summary.statementDate)),
              ),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(_dateText(summary.dueDate)),
              ),
              ListTile(
                title: const Text('Total Amount Due'),
                subtitle: Text('₱${summary.totalAmountDue.toStringAsFixed(2)}'),
              ),
              ListTile(
                title: const Text('Minimum Due'),
                subtitle: Text('₱${summary.minimumDue.toStringAsFixed(2)}'),
              ),
              ListTile(
                title: const Text('Transaction Count'),
                subtitle: Text('${summary.transactionCount}'),
              ),
              ElevatedButton(
                onPressed: () => _showEditSummaryDialog(context, summary),
                child: const Text('Edit parsed metadata'),
              ),
              DropdownButtonFormField<String>(
                value: effectiveSelectedCardId,
                decoration: const InputDecoration(labelText: 'Save to card'),
                items: activeCards
                    .map(
                      (card) => DropdownMenuItem(
                        value: card.id,
                        child: Text('${card.nickname} • ${card.bankName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedCardId = value),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: effectiveSelectedCardId == null
                    ? null
                    : () {
                        context
                            .read<StatementCubit>()
                            .saveCorrectedParseSummary(
                                effectiveSelectedCardId!);
                      },
                child: const Text('Save statement'),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<_ImportPrompt?> _showImportPrompt(BuildContext context) async {
    return showDialog<_ImportPrompt>(
      context: context,
      builder: (context) => const _ImportPromptDialog(),
    );
  }

  Future<void> _showEditSummaryDialog(
      BuildContext context, ParseSummary summary) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditSummaryDialog(summary: summary),
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
            const Text('Credit Card Profile Management',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => _showCardDialog(context),
              child: const Text('Add card profile'),
            ),
            ...state.cards.map(
              (card) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hexToColor(card.colorHex),
                    child: Icon(networkIcon(card.network), color: Colors.white),
                  ),
                  title: Text('${card.nickname} • ${card.bankName}'),
                  subtitle: Text(
                    '₱${card.creditLimit.toStringAsFixed(2)} • ${card.network.name} • statement ${card.statementDay} • due ${card.dueDay}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showCardDialog(context, existing: card);
                      }
                      if (action == 'archive') {
                        context.read<CardCubit>().archiveCard(card.id);
                      }
                      if (action == 'delete') {
                        context.read<CardCubit>().deleteCard(card.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(card.isArchived ? 'Archived' : 'Archive'),
                        enabled: !card.isArchived,
                      ),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
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

  Future<void> _showCardDialog(
    BuildContext context, {
    CardProfile? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CardDialog(existing: existing),
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
            const Text('Statements & Transactions',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Search merchant or keyword'),
              onChanged: context.read<StatementCubit>().setSearchQuery,
            ),
            ElevatedButton(
              onPressed: () =>
                  context.read<StatementCubit>().addManualTransaction(
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
                subtitle: Text(
                    '${tx.category} • ${tx.date.toIso8601String().split('T').first}'),
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
            const Text('Analytics, Insights & Budgeting',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => context.read<AnalyticsCubit>().compute(
                    cards: cardState.cards,
                    transactions: statementState.transactions,
                  ),
              child: const Text('Refresh analytics'),
            ),
            Text(
                'Aggregate utilization: ${state.aggregateUtilization.toStringAsFixed(1)}%'),
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
            const Text('Payment Reminders & Settlement',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                        context
                            .read<ReminderCubit>()
                            .setOffsets(updated.toSet().toList()..sort());
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
        Text('Data Management, Export & Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('Data export'),
          subtitle: Text(
              'Export transactions as CSV, JSON, Excel, and monthly summary PDF.'),
        ),
        ListTile(
          title: Text('Backup & restore'),
          subtitle: Text(
              'Export encrypted local database backup and import restore file.'),
        ),
        ListTile(
          title: Text('Factory reset'),
          subtitle: Text(
              'Clear all local records and saved keychain/keystore credentials.'),
        ),
        ListTile(
          title: Text('Customization'),
          subtitle: Text('Theme: Light/Dark/System • Currency: PHP ₱'),
        ),
      ],
    );
  }
}

class _ImportPrompt {
  const _ImportPrompt({
    required this.bank,
    required this.password,
    required this.rememberPassword,
  });

  final String bank;
  final String password;
  final bool rememberPassword;
}

String _dateText(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime? _tryDate(String text) {
  final parts = text.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

const List<String> cardColorOptions = [
  '#1976D2',
  '#2E7D32',
  '#6A1B9A',
  '#EF6C00',
  '#C62828',
  '#00838F',
];

IconData networkIcon(CardNetwork network) {
  switch (network) {
    case CardNetwork.visa:
      return Icons.credit_card;
    case CardNetwork.mastercard:
      return Icons.payment;
    case CardNetwork.jcb:
      return Icons.account_balance_wallet;
    case CardNetwork.amex:
      return Icons.business_center;
    case CardNetwork.unionpay:
      return Icons.currency_exchange;
    case CardNetwork.diners:
      return Icons.restaurant;
  }
}

bool _isKnownBank(String bank) {
  final normalized = bank.trim().toLowerCase();
  return philippineBanks.any((item) => item.toLowerCase() == normalized);
}

class _AddPasswordDialog extends StatefulWidget {
  const _AddPasswordDialog({super.key});

  @override
  State<_AddPasswordDialog> createState() => _AddPasswordDialogState();
}

class _AddPasswordDialogState extends State<_AddPasswordDialog> {
  late final TextEditingController _bankController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _bankController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save bank PDF password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu<String>(
            controller: _bankController,
            requestFocusOnTap: true,
            enableFilter: true,
            enableSearch: true,
            label: const Text('Bank (searchable)'),
            dropdownMenuEntries: philippineBanks
                .map((bank) =>
                    DropdownMenuEntry<String>(value: bank, label: bank))
                .toList(),
          ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final bank = _bankController.text.trim();
            final password = _passwordController.text;
            if (!_isKnownBank(bank) || password.isEmpty) {
              return;
            }
            context.read<SecurityCubit>().savePdfPassword(bank, password);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ImportPromptDialog extends StatefulWidget {
  const _ImportPromptDialog({super.key});

  @override
  State<_ImportPromptDialog> createState() => _ImportPromptDialogState();
}

class _ImportPromptDialogState extends State<_ImportPromptDialog> {
  late final TextEditingController _bankController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberPassword = false;

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _bankController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unlock statement PDF'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu<String>(
            controller: _bankController,
            requestFocusOnTap: true,
            enableFilter: true,
            enableSearch: true,
            label: const Text('Bank (searchable)'),
            dropdownMenuEntries: philippineBanks
                .map((bank) =>
                    DropdownMenuEntry<String>(value: bank, label: bank))
                .toList(),
          ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'PDF password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _rememberPassword,
            onChanged: (value) {
              setState(() {
                _rememberPassword = value ?? false;
              });
            },
            title: const Text('Remember password for this bank'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final bank = _bankController.text.trim();
                if (bank.isEmpty) {
                  return;
                }
                final securityCubit = context.read<SecurityCubit>();
                final saved = await securityCubit.getPdfPassword(bank);
                if (!context.mounted || saved == null) {
                  return;
                }
                setState(() {
                  _passwordController.text = saved;
                });
              },
              child: const Text('Use saved password'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final bank = _bankController.text.trim();
            final password = _passwordController.text;
            if (!_isKnownBank(bank) || password.isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _ImportPrompt(
                bank: bank,
                password: password,
                rememberPassword: _rememberPassword,
              ),
            );
          },
          child: const Text('Continue import'),
        ),
      ],
    );
  }
}

class _EditSummaryDialog extends StatefulWidget {
  final ParseSummary summary;
  const _EditSummaryDialog({super.key, required this.summary});

  @override
  State<_EditSummaryDialog> createState() => _EditSummaryDialogState();
}

class _EditSummaryDialogState extends State<_EditSummaryDialog> {
  late final TextEditingController _bankController;
  late final TextEditingController _statementDateController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _totalController;
  late final TextEditingController _minimumController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController(text: widget.summary.bankDetected);
    _statementDateController =
        TextEditingController(text: _dateText(widget.summary.statementDate));
    _dueDateController =
        TextEditingController(text: _dateText(widget.summary.dueDate));
    _totalController =
        TextEditingController(text: widget.summary.totalAmountDue.toStringAsFixed(2));
    _minimumController =
        TextEditingController(text: widget.summary.minimumDue.toStringAsFixed(2));
    _countController =
        TextEditingController(text: '${widget.summary.transactionCount}');
  }

  @override
  void dispose() {
    _bankController.dispose();
    _statementDateController.dispose();
    _dueDateController.dispose();
    _totalController.dispose();
    _minimumController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit parsed metadata'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Bank')),
            TextField(
              controller: _statementDateController,
              decoration: const InputDecoration(
                  labelText: 'Statement date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _dueDateController,
              decoration: const InputDecoration(
                  labelText: 'Due date (YYYY-MM-DD)'),
            ),
            TextField(
                controller: _totalController,
                decoration: const InputDecoration(labelText: 'Total due')),
            TextField(
                controller: _minimumController,
                decoration: const InputDecoration(labelText: 'Minimum due')),
            TextField(
                controller: _countController,
                decoration: const InputDecoration(labelText: 'Transaction count')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<StatementCubit>().setParseSummary(
                  widget.summary.copyWith(
                    bankDetected: _bankController.text.trim(),
                    statementDate: _tryDate(_statementDateController.text) ??
                        widget.summary.statementDate,
                    dueDate: _tryDate(_dueDateController.text) ??
                        widget.summary.dueDate,
                    totalAmountDue: double.tryParse(_totalController.text) ??
                        widget.summary.totalAmountDue,
                    minimumDue: double.tryParse(_minimumController.text) ??
                        widget.summary.minimumDue,
                    transactionCount: int.tryParse(_countController.text) ??
                        widget.summary.transactionCount,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _CardDialog extends StatefulWidget {
  final CardProfile? existing;
  const _CardDialog({super.key, this.existing});

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  late final TextEditingController _bankController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _statementDayController;
  late final TextEditingController _dueDayController;
  late String _selectedColorHex;
  late CardNetwork _selectedNetwork;

  @override
  void initState() {
    super.initState();
    _bankController =
        TextEditingController(text: widget.existing?.bankName ?? '');
    _nicknameController =
        TextEditingController(text: widget.existing?.nickname ?? '');
    _creditLimitController = TextEditingController(
        text: widget.existing?.creditLimit.toStringAsFixed(2) ?? '50000.00');
    _statementDayController = TextEditingController(
        text: widget.existing?.statementDay.toString() ?? '10');
    _dueDayController =
        TextEditingController(text: widget.existing?.dueDay.toString() ?? '5');
    _selectedColorHex = widget.existing?.colorHex ?? cardColorOptions.first;
    _selectedNetwork = widget.existing?.network ?? CardNetwork.visa;
  }

  @override
  void dispose() {
    _bankController.dispose();
    _nicknameController.dispose();
    _creditLimitController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Add credit card' : 'Edit credit card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownMenu<String>(
              controller: _bankController,
              requestFocusOnTap: true,
              enableFilter: true,
              enableSearch: true,
              label: const Text('Bank name'),
              dropdownMenuEntries: philippineBanks
                  .map((bank) =>
                      DropdownMenuEntry<String>(value: bank, label: bank))
                  .toList(),
            ),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: 'Card nickname'),
            ),
            DropdownButtonFormField<CardNetwork>(
              value: _selectedNetwork,
              items: CardNetwork.values
                  .map((network) => DropdownMenuItem(
                        value: network,
                        child: Row(
                          children: [
                            Icon(networkIcon(network), size: 18),
                            const SizedBox(width: 8),
                            Text(network.name.toUpperCase()),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNetwork = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Network'),
            ),
            TextField(
              controller: _creditLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Credit limit'),
            ),
            TextField(
              controller: _statementDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Statement day'),
            ),
            TextField(
              controller: _dueDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Due day'),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Card color'),
            ),
            Wrap(
              spacing: 8,
              children: cardColorOptions
                  .map(
                    (hex) => ChoiceChip(
                      selected: _selectedColorHex == hex,
                      onSelected: (_) {
                        setState(() {
                          _selectedColorHex = hex;
                        });
                      },
                      label: CircleAvatar(
                        radius: 10,
                        backgroundColor: hexToColor(hex),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final bank = _bankController.text.trim();
            final nickname = _nicknameController.text.trim();
            if (!_isKnownBank(bank) || nickname.isEmpty) {
              return;
            }
            final creditLimit =
                double.tryParse(_creditLimitController.text) ?? 0;
            final statementDay =
                int.tryParse(_statementDayController.text) ?? 1;
            final dueDay = int.tryParse(_dueDayController.text) ?? 1;
            final colorHex = _selectedColorHex;

            if (widget.existing == null) {
              context.read<CardCubit>().addCard(
                    bankName: bank,
                    nickname: nickname,
                    network: _selectedNetwork,
                    creditLimit: creditLimit,
                    statementDay: statementDay,
                    dueDay: dueDay,
                    colorHex: colorHex,
                  );
            } else {
              context.read<CardCubit>().updateCard(
                    widget.existing!.copyWith(
                      bankName: bank,
                      nickname: nickname,
                      network: _selectedNetwork,
                      creditLimit: creditLimit,
                      statementDay: statementDay,
                      dueDay: dueDay,
                      colorHex: colorHex,
                    ),
                  );
            }
            Navigator.pop(context);
          },
          child: Text(widget.existing == null ? 'Add' : 'Save changes'),
        ),
      ],
    );
  }
}
