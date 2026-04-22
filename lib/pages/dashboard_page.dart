import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/repayments_api_service.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';
import 'customers_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RepaymentsApiService _repaymentsApiService = RepaymentsApiService();
  late Future<void> _dashboardFuture;
  List<_DashboardTxn> _allTransactions = const [];
  String? _transactionsError;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final outstanding = state.dashboardMetrics?.totalOutstandingAmount ?? 0.0;
    final latestTransactions = _allTransactions.take(5).toList();
    final remainingTransactions = _allTransactions.skip(5).toList();

    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<void>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                state.dashboardMetrics == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isStillLoading = snapshot.connectionState == ConnectionState.waiting;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dashboardFuture = _loadDashboardData();
                });
                await _dashboardFuture;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF6E7E3), Color(0xFFF4ECE4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Text(
                                (state.loggedInUserName.isEmpty
                                        ? "U"
                                        : state.loggedInUserName[0])
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hello, ${state.loggedInUserName.isEmpty ? 'User' : state.loggedInUserName}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    "Welcome back",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.notifications_none,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AmountFormatter.compactCurrency(outstanding),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Total Outstanding",
                          style: TextStyle(fontSize: 20, color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _quickActionButton(
                              icon: Icons.arrow_outward,
                              label: "Transfer",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CustomersPage(),
                                  ),
                                );
                              },
                            ),
                            _quickActionButton(
                              icon: Icons.arrow_downward,
                              label: "Withdraw",
                            ),
                            _quickActionButton(icon: Icons.add, label: "Top Up"),
                            _quickActionButton(icon: Icons.grid_view, label: "More"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Transactions",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: remainingTransactions.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _AllTransactionsPage(
                                        transactions: remainingTransactions,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            "See all",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (latestTransactions.isEmpty && isStillLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 26),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_transactionsError != null && latestTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Center(
                        child: Text(
                          _transactionsError!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (latestTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 26),
                      child: Center(child: Text("No transactions yet")),
                    )
                  else
                    ...latestTransactions.map(
                      (tx) => _buildTransactionCard(context, tx),
                    ),
                  const SizedBox(height: 90),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    _DashboardTxn transaction,
  ) {
    final isLoan = transaction.isLoan;
    final amountLabel = isLoan
        ? "+${AmountFormatter.compactNumber(transaction.amount)}"
        : "-${AmountFormatter.compactNumber(transaction.amount)}";

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
          child: _txnAvatarWidget(transaction),
        ),
        title: Text(
          transaction.customerName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "${transaction.label} • ${_formatDate(transaction.date)}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          "GHS $amountLabel",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isLoan ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    final state = context.read<AppState>();
    _transactionsError = null;
    await state.loadDashboardMetricsFromApi();

    try {
      final transactions = await _repaymentsApiService.fetchAllTransactions();
      final tx = <_DashboardTxn>[];

      for (final item in transactions) {
        final loanType = (item['loanType'] ?? '').toString().trim();
        final customerName = (item['customerName'] ?? '').toString().trim();
        final notes = (item['notes'] ?? '').toString().trim();
        final label = loanType.isEmpty ? 'Transaction' : '$loanType Repayment';
        final lowerNotes = notes.toLowerCase();
        final isLoan = lowerNotes.contains('loan disbursed') ||
            lowerNotes.contains('new loan');

        tx.add(
          _DashboardTxn(
            customerId: (item['customerId'] ?? '').toString(),
            customerName: customerName.isEmpty ? 'Unknown customer' : customerName,
            customerProfileImage: item['customerProfileImage']?.toString(),
            amount: _numFrom(item, const ['amountPaid', 'amount', 'paymentAmount']),
            date: _dateFrom(
              item,
              const ['paymentDate', 'date', 'createdAt', 'transactionDate'],
            ),
            isLoan: isLoan,
            label: label,
          ),
        );
      }

      tx.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
      if (!mounted) return;
      setState(() {
        _allTransactions = tx;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allTransactions = const [];
        _transactionsError = 'Failed to load transactions.';
      });
    }
  }

  double _numFrom(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  String _dateFrom(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return DateTime.now().toIso8601String();
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return "${parsed.year}-$m-$d";
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllTransactionsPage extends StatelessWidget {
  const _AllTransactionsPage({required this.transactions});

  final List<_DashboardTxn> transactions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Transactions")),
      body: transactions.isEmpty
          ? const Center(child: Text("No transactions available"))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isLoan = transaction.isLoan;
                final amountLabel = isLoan
                    ? "+${AmountFormatter.compactNumber(transaction.amount)}"
                    : "-${AmountFormatter.compactNumber(transaction.amount)}";

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.35),
                      child: _txnAvatarWidget(transaction),
                    ),
                    title: Text(
                      transaction.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${transaction.label} • ${_readableDateTime(transaction.date)}",
                    ),
                    trailing: Text(
                      "GHS $amountLabel",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isLoan ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DashboardTxn {
  const _DashboardTxn({
    required this.customerId,
    required this.customerName,
    required this.customerProfileImage,
    required this.amount,
    required this.date,
    required this.isLoan,
    required this.label,
  });

  final String customerId;
  final String customerName;
  final String? customerProfileImage;
  final double amount;
  final String date;
  final bool isLoan;
  final String label;
}

Widget _txnAvatarWidget(_DashboardTxn transaction) {
  final bytes = _profileImageBytes(transaction.customerProfileImage);
  if (bytes != null) {
    return ClipOval(
      child: Image.memory(
        bytes,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Text(
            _initialForName(transaction.customerName),
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }

  return Text(
    _initialForName(transaction.customerName),
    style: const TextStyle(fontWeight: FontWeight.bold),
  );
}

Uint8List? _profileImageBytes(String? rawValue) {
  if (rawValue == null || rawValue.trim().isEmpty) return null;
  var base64Value = rawValue.trim();
  final commaIndex = base64Value.indexOf(',');
  if (base64Value.startsWith('data:image') && commaIndex != -1) {
    base64Value = base64Value.substring(commaIndex + 1);
  }
  try {
    return base64Decode(base64Value);
  } catch (_) {
    return null;
  }
}

String _initialForName(String? name) {
  if (name == null || name.trim().isEmpty) return "U";
  return name.trim()[0].toUpperCase();
}

String _readableDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[parsed.month - 1];
  final day = parsed.day;
  final year = parsed.year;
  final hour24 = parsed.hour;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = (hour24 % 12 == 0) ? 12 : hour24 % 12;

  return '$month $day, $year • $hour12:$minute $period';
}
