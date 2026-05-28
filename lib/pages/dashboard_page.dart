import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_metrics.dart';
import '../models/loan_overview.dart';
import 'loan_insights_page.dart';
import 'reports_coming_soon_page.dart';
import '../widgets/dashboard_mini_bottom_nav.dart';
import '../core/service_locator.dart';
import '../services/repayments_api_service.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  RepaymentsApiService get _repaymentsApiService => ServiceLocator.repaymentsApi;
  late Future<void> _dashboardFuture;
  List<DashboardTxn> _allTransactions = const [];
  String? _transactionsError;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final outstanding = state.dashboardMetrics?.totalOutstandingAmount ??
        state.dashboardOverview?.stats.totalOutstanding ??
        0.0;
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
                          children: [
                            Expanded(
                              child: _quickActionButton(
                                icon: Icons.description_outlined,
                                label: "Transactions",
                                subtitle: "Record & View",
                                iconBg: const Color(0xFFF8ECEB),
                                iconColor: const Color(0xFFB26D6C),
                                onTap: _allTransactions.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AllTransactionsPage(
                                              transactions: _allTransactions,
                                              metrics: state.dashboardMetrics,
                                              overview: state.dashboardOverview,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickActionButton(
                                icon: Icons.pie_chart_outline_rounded,
                                label: "Overview",
                                subtitle: "All Insights",
                                iconBg: const Color(0xFFF0F0FF),
                                iconColor: const Color(0xFF6A6FD2),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OverviewPage(
                                        metrics: state.dashboardMetrics,
                                        overview: state.dashboardOverview,
                                        transactions: _allTransactions,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickActionButton(
                                icon: Icons.show_chart_rounded,
                                label: "Loan Insights",
                                subtitle: "By Loan Type",
                                iconBg: const Color(0xFFECF7F0),
                                iconColor: const Color(0xFF4EA573),
                                onTap: () {
                                  DashboardFlowNav.openLoanInsights(
                                    context,
                                    metrics: state.dashboardMetrics,
                                    overview: state.dashboardOverview,
                                    transactions: _allTransactions,
                                    initialOverview: state.dashboardOverview,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickActionButton(
                                icon: Icons.bar_chart_rounded,
                                label: "Reports",
                                subtitle: "Detailed Stats",
                                iconBg: const Color(0xFFF3ECFB),
                                iconColor: const Color(0xFF8F6BC6),
                                onTap: () {
                                  DashboardFlowNav.openReports(
                                    context,
                                    metrics: state.dashboardMetrics,
                                    overview: state.dashboardOverview,
                                    transactions: _allTransactions,
                                  );
                                },
                              ),
                            ),
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
                                      builder: (_) => AllTransactionsPage(
                                        transactions: remainingTransactions,
                                        metrics: state.dashboardMetrics,
                                        overview: state.dashboardOverview,
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
    DashboardTxn transaction,
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
    await state.loadDashboardOverviewFromApi(months: 6);

    try {
      final transactions = await _repaymentsApiService.fetchAllTransactions();
      final tx = <DashboardTxn>[];

      for (final item in transactions) {
        final loanType = (item['loanType'] ?? '').toString().trim();
        final customerName = (item['customerName'] ?? '').toString().trim();
        final notes = (item['notes'] ?? '').toString().trim();
        final label = loanType.isEmpty ? 'Transaction' : '$loanType Repayment';
        final lowerNotes = notes.toLowerCase();
        final isLoan = lowerNotes.contains('loan disbursed') ||
            lowerNotes.contains('new loan');

        tx.add(
          DashboardTxn(
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
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({
    required this.transactions,
    this.metrics,
    this.overview,
  });

  final List<DashboardTxn> transactions;
  final LoanMetrics? metrics;
  final LoanOverview? overview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Transactions")),
      bottomNavigationBar: DashboardFlowNav.miniBottomNav(
        activeTab: DashboardMiniNavTab.transactions,
        metrics: metrics,
        overview: overview,
        transactions: transactions,
      ),
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

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    required this.metrics,
    required this.overview,
    required this.transactions,
  });

  final LoanMetrics? metrics;
  final LoanOverview? overview;
  final List<DashboardTxn> transactions;

  @override
  State<OverviewPage> createState() => OverviewPageState();
}

class OverviewPageState extends State<OverviewPage> {
  late LoanOverview? _overview;
  int _selectedMonths = 6;
  bool _isLoadingOverview = false;

  @override
  void initState() {
    super.initState();
    _overview = widget.overview;
    if (_overview == null) {
      _reloadOverview();
    }
  }

  Future<void> _reloadOverview([int? months]) async {
    final targetMonths = months ?? _selectedMonths;
    setState(() {
      _selectedMonths = targetMonths;
      _isLoadingOverview = true;
    });
    await context.read<AppState>().loadDashboardOverviewFromApi(
          months: targetMonths,
        );
    if (!mounted) return;
    setState(() {
      _overview = context.read<AppState>().dashboardOverview;
      _isLoadingOverview = false;
    });
  }

  String _monthsLabel() {
    switch (_selectedMonths) {
      case 1:
        return 'This Month';
      case 3:
        return 'Last 3 Months';
      case 6:
        return 'Last 6 Months';
      case 12:
        return 'Last 12 Months';
      default:
        return 'Last $_selectedMonths Months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outstanding = _overview?.stats.totalOutstanding ??
        widget.metrics?.totalOutstandingAmount ??
        0.0;
    final borrowed = _overview?.stats.totalBorrowedThisMonth ??
        widget.metrics?.totalActivePrincipalAmount ??
        0.0;
    final repaid = _overview?.stats.totalRepaidThisMonth ??
        math.max(0.0, borrowed - outstanding);
    final totalCustomers = _overview?.stats.totalCustomers ??
        widget.metrics?.totalCustomers ??
        _countCustomers(widget.transactions);
    final activeBorrowers =
        _overview?.stats.activeBorrowers ?? _countCustomers(widget.transactions);
    final topCustomers = _topOutstandingCustomers(
      fallbackTxs: widget.transactions,
      overviewItems: _overview?.topCustomers ?? const [],
    ).take(5).toList();
    final trendPoints = _buildTrendPoints(
      fallbackTxs: widget.transactions,
      overviewPoints: _overview?.repaymentTrend ?? const [],
    );
    final trendScale = _trendScale(trendPoints);

    final dailyOutstanding = _overview?.loanTypeBreakdown.dailyOutstanding ??
        widget.metrics?.activeDailyRepayableAmount ??
        0.0;
    final softOutstanding = _overview?.loanTypeBreakdown.softOutstanding ??
        widget.metrics?.activeSoftRepayableAmount ??
        0.0;
    final totalLoanType = dailyOutstanding + softOutstanding;
    final apiDailyPercent = _overview?.loanTypeBreakdown.dailyPercent;
    final apiSoftPercent = _overview?.loanTypeBreakdown.softPercent;
    final hasUsableApiPercents = (apiDailyPercent != null && apiDailyPercent > 0) ||
        (apiSoftPercent != null && apiSoftPercent > 0);
    final dailyPercent = hasUsableApiPercents
        ? (apiDailyPercent ?? 0.0)
        : (totalLoanType <= 0 ? 0.0 : (dailyOutstanding / totalLoanType));
    final softPercent = hasUsableApiPercents
        ? (apiSoftPercent ?? 0.0)
        : (totalLoanType <= 0 ? 0.0 : (softOutstanding / totalLoanType));

    final totalActiveLoans = _overview == null
        ? (widget.metrics?.totalActiveLoansCount ?? 0)
        : (_overview!.statusBreakdown.onTrackCount +
            _overview!.statusBreakdown.dueSoonCount +
            _overview!.statusBreakdown.overdueCount);
    final onTrackCount = _overview?.statusBreakdown.onTrackCount ??
        (totalActiveLoans * 0.56).round();
    final dueSoonCount = _overview?.statusBreakdown.dueSoonCount ??
        (totalActiveLoans * 0.22).round();
    final overdueCount = _overview?.statusBreakdown.overdueCount ??
        math.max(0, totalActiveLoans - onTrackCount - dueSoonCount);

    final monthlyRepaymentGrowth = _repaymentGrowth(trendPoints);
    final growthPercent = _overview?.insight?.changePercent ?? monthlyRepaymentGrowth;
    final growthLabel = growthPercent.isFinite
        ? '${(growthPercent * 100).abs().toStringAsFixed(0)}%'
        : '0%';
    final isGrowthPositive = _overview?.insight?.isPositive ?? monthlyRepaymentGrowth >= 0;
    final insightText = (_overview?.insight?.message ?? '').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      bottomNavigationBar: DashboardFlowNav.miniBottomNav(
        activeTab: DashboardMiniNavTab.overview,
        metrics: widget.metrics,
        overview: _overview,
        transactions: widget.transactions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                onSelected: _reloadOverview,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 1, child: Text('This Month')),
                  PopupMenuItem(value: 3, child: Text('Last 3 Months')),
                  PopupMenuItem(value: 6, child: Text('Last 6 Months')),
                  PopupMenuItem(value: 12, child: Text('Last 12 Months')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECECEF)),
                  ),
                  child: Row(
                    children: [
                      Text(_monthsLabel(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Summary of your loan records',
            style: TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
          if (_isLoadingOverview)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _overviewStatCard(
                  title: "Total Outstanding",
                  value: AmountFormatter.compactCurrency(outstanding),
                  subtitle: "From ${topCustomers.length} customers",
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFFCB6262),
                  titleFontSize: 10.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _overviewStatCard(
                  title: "Total Repaid",
                  value: AmountFormatter.compactCurrency(repaid),
                  subtitle: "This month",
                  icon: Icons.north_rounded,
                  accent: const Color(0xFF2CA95F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _overviewStatCard(
                  title: "Total Borrowed",
                  value: AmountFormatter.compactCurrency(borrowed),
                  subtitle: "Principal",
                  icon: Icons.south_rounded,
                  accent: const Color(0xFF4A79C9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _overviewStatCard(
                  title: "Total Customers",
                  value: '$totalCustomers',
                  subtitle: "$activeBorrowers active",
                  icon: Icons.groups_2_outlined,
                  accent: const Color(0xFF7D59C9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Repayment Trend",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFECECEF)),
                        ),
                        child: Row(
                          children: [
                            Text(_monthsLabel(), style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      _LegendDot(color: Color(0xFF2CA95F), label: 'Repaid'),
                      SizedBox(width: 16),
                      _LegendDot(color: Color(0xFFCB6262), label: 'Outstanding'),
                      SizedBox(width: 16),
                      _LegendDot(color: Color(0xFF4A79C9), label: 'Borrowed'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 148,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _buildTrendScaleLabels(trendScale),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: CustomPaint(
                            painter: _TrendPainter(
                              colorScheme: colorScheme,
                              points: trendPoints,
                              maxValue: trendScale,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: trendPoints
                        .map((e) => Text(
                              e.label,
                              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ringCard(
                  title: "By Loan Type",
                  centerValue: AmountFormatter.compactCurrency(outstanding).replaceFirst('GHS ', ''),
                  centerLabel: "Outstanding",
                  segments: [
                    _RingSegment(value: dailyPercent, color: const Color(0xFF2CA95F)),
                    _RingSegment(value: softPercent, color: const Color(0xFF4A79C9)),
                  ],
                  labels: [
                    _LegendLine(
                      color: const Color(0xFF2CA95F),
                      label: "Daily Loans",
                      value:
                          "${AmountFormatter.compactCurrency(dailyOutstanding)} (${(dailyPercent * 100).toStringAsFixed(0)}%)",
                    ),
                    _LegendLine(
                      color: const Color(0xFF4A79C9),
                      label: "Soft Loans",
                      value:
                          "${AmountFormatter.compactCurrency(softOutstanding)} (${(softPercent * 100).toStringAsFixed(0)}%)",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ringCard(
                  title: "By Status",
                  centerValue: '$totalActiveLoans',
                  centerLabel: "Borrowers",
                  segments: [
                    _RingSegment(
                      value: totalActiveLoans == 0 ? 0 : onTrackCount / totalActiveLoans,
                      color: const Color(0xFF4CB05A),
                    ),
                    _RingSegment(
                      value: totalActiveLoans == 0 ? 0 : dueSoonCount / totalActiveLoans,
                      color: const Color(0xFFF0A325),
                    ),
                    _RingSegment(
                      value: totalActiveLoans == 0 ? 0 : overdueCount / totalActiveLoans,
                      color: const Color(0xFFCF5A5A),
                    ),
                  ],
                  labels: [
                    _LegendLine(
                      color: const Color(0xFF4CB05A),
                      label: "On Track",
                      value:
                          "$onTrackCount (${totalActiveLoans == 0 ? 0 : (((_overview?.statusBreakdown.onTrackPercent ?? (onTrackCount / totalActiveLoans)) * 100).toStringAsFixed(0))}%)",
                    ),
                    _LegendLine(
                      color: const Color(0xFFF0A325),
                      label: "Due Soon",
                      value:
                          "$dueSoonCount (${totalActiveLoans == 0 ? 0 : (((_overview?.statusBreakdown.dueSoonPercent ?? (dueSoonCount / totalActiveLoans)) * 100).toStringAsFixed(0))}%)",
                    ),
                    _LegendLine(
                      color: const Color(0xFFCF5A5A),
                      label: "Overdue",
                      value:
                          "$overdueCount (${totalActiveLoans == 0 ? 0 : (((_overview?.statusBreakdown.overduePercent ?? (overdueCount / totalActiveLoans)) * 100).toStringAsFixed(0))}%)",
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Top 5 Customers (Highest Outstanding)",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                      TextButton(
                        onPressed: null,
                        child: Text(
                          "View all",
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (topCustomers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text("No customer data available."),
                    )
                  else
                    ...topCustomers.map((c) {
                      final maxAmount = topCustomers.first.amount <= 0 ? 1.0 : topCustomers.first.amount;
                      final ratio = (c.amount / maxAmount).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: colorScheme.secondary.withValues(alpha: 0.20),
                              child: Text(
                                c.name.isEmpty ? 'U' : c.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: ratio,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(Color(0xFFB24D57)),
                                  backgroundColor: const Color(0xFFE9E9E9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AmountFormatter.compactCurrency(c.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB24D57),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black45),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE8F7ED),
                  child: Icon(
                    isGrowthPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isGrowthPositive ? const Color(0xFF2CA95F) : const Color(0xFFCB6262),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontSize: 14.5),
                      children: [
                        const TextSpan(text: 'Great job! Total repayments '),
                        TextSpan(
                          text: insightText.isNotEmpty
                              ? '$insightText '
                              : (isGrowthPositive ? 'increased by ' : 'decreased by '),
                        ),
                        TextSpan(
                          text: growthLabel,
                          style: TextStyle(
                            color: isGrowthPositive
                                ? const Color(0xFF2CA95F)
                                : const Color(0xFFCB6262),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' compared to last month.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  int _countCustomers(List<DashboardTxn> txs) {
    return txs.map((t) => t.customerId).toSet().length;
  }

  List<_OutstandingCustomer> _topOutstandingCustomers({
    required List<DashboardTxn> fallbackTxs,
    required List<OverviewTopCustomer> overviewItems,
  }) {
    if (overviewItems.isNotEmpty) {
      final list = overviewItems
          .map((e) => _OutstandingCustomer(name: e.customerName, amount: e.outstanding))
          .where((e) => e.amount > 0)
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      if (list.isNotEmpty) return list;
    }

    final totals = <String, _OutstandingCustomer>{};
    for (final tx in fallbackTxs) {
      final existing = totals[tx.customerId] ??
          _OutstandingCustomer(name: tx.customerName, amount: 0);
      final next = tx.isLoan ? existing.amount + tx.amount : existing.amount - tx.amount;
      totals[tx.customerId] = _OutstandingCustomer(name: tx.customerName, amount: next);
    }
    final list = totals.values.where((e) => e.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  Widget _overviewStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    double titleFontSize = 11.2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12.5,
              backgroundColor: accent.withValues(alpha: 0.14),
              child: Icon(icon, color: accent, size: 15),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: titleFontSize, color: Colors.black54)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w800, color: accent, fontSize: 22),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.black54, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _ringCard({
    required String title,
    required String centerValue,
    required String centerLabel,
    required List<_RingSegment> segments,
    required List<_LegendLine> labels,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(124, 124),
                      painter: _RingPainter(segments: segments),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerValue,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
                        ),
                        Text(centerLabel, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...labels.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: line.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        line.label,
                        style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      line.value,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TrendPoint> _buildTrendPoints({
    required List<DashboardTxn> fallbackTxs,
    required List<LoanOverviewTrendPoint> overviewPoints,
  }) {
    if (overviewPoints.isNotEmpty) {
      return overviewPoints
          .map(
            (p) => _TrendPoint(
              label: p.month,
              repaid: p.repaid,
              borrowed: p.borrowed,
              outstanding: p.outstanding,
            ),
          )
          .toList();
    }

    final now = DateTime.now();
    final monthStarts = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
    final monthStats = <String, _MonthStats>{};
    for (final m in monthStarts) {
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      monthStats[key] = _MonthStats();
    }

    for (final tx in fallbackTxs) {
      final date = DateTime.tryParse(tx.date);
      if (date == null) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final stats = monthStats[key];
      if (stats == null) continue;
      if (tx.isLoan) {
        stats.borrowed += tx.amount;
      } else {
        stats.repaid += tx.amount;
      }
    }

    var rollingOutstanding = 0.0;
    final labels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthStarts.map((m) {
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      final stats = monthStats[key]!;
      rollingOutstanding = math.max(0.0, rollingOutstanding + stats.borrowed - stats.repaid);
      return _TrendPoint(
        label: labels[m.month - 1],
        repaid: stats.repaid,
        borrowed: stats.borrowed,
        outstanding: rollingOutstanding,
      );
    }).toList();
  }

  double _trendScale(List<_TrendPoint> points) {
    var maxValue = 0.0;
    for (final p in points) {
      maxValue = math.max(maxValue, math.max(p.borrowed, math.max(p.repaid, p.outstanding)));
    }
    return maxValue <= 0 ? 1.0 : maxValue;
  }

  double _repaymentGrowth(List<_TrendPoint> points) {
    if (points.length < 2) return 0;
    final prev = points[points.length - 2].repaid;
    final current = points.last.repaid;
    if (prev == 0) return current == 0 ? 0 : 1;
    return (current - prev) / prev;
  }

  List<Widget> _buildTrendScaleLabels(double maxValue) {
    final step = maxValue / 4;
    return List.generate(5, (index) {
      final value = step * (4 - index);
      final label = value <= 0 ? '0' : AmountFormatter.compactNumber(value);
      return Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
        textAlign: TextAlign.right,
      );
    });
  }
}

class _OutstandingCustomer {
  _OutstandingCustomer({required this.name, required this.amount});
  final String name;
  final double amount;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.colorScheme,
    required this.points,
    required this.maxValue,
  });
  final ColorScheme colorScheme;
  final List<_TrendPoint> points;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E8EA)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = ((size.height - 18) / 4) * i + 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointOffset(int index, double value) {
      final x = (size.width / (points.length - 1)) * index;
      final y = (size.height - 18) - ((value / maxValue) * (size.height - 28)) + 2;
      return Offset(x, y);
    }

    void drawSeries(List<double> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final point = pointOffset(i, values[i]);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
      final dot = Paint()..color = color;
      for (var i = 0; i < values.length; i++) {
        final p = pointOffset(i, values[i]);
        canvas.drawCircle(p, 3.4, dot);
        canvas.drawCircle(p, 1.7, Paint()..color = Colors.white);
      }
    }

    drawSeries(points.map((p) => p.borrowed).toList(), const Color(0xFF4A79C9));
    drawSeries(points.map((p) => p.repaid).toList(), const Color(0xFF2CA95F));
    drawSeries(points.map((p) => p.outstanding).toList(), const Color(0xFFCB6262));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments});
  final List<_RingSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final basePaint = Paint()
      ..color = const Color(0xFFEFEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (math.pi * 2) * segment.value;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.segments != segments;
}

class _RingSegment {
  _RingSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

class _LegendLine {
  _LegendLine({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;
}

class _MonthStats {
  double borrowed = 0;
  double repaid = 0;
}

class _TrendPoint {
  _TrendPoint({
    required this.label,
    required this.repaid,
    required this.borrowed,
    required this.outstanding,
  });

  final String label;
  final double repaid;
  final double borrowed;
  final double outstanding;
}

class DashboardTxn {
  const DashboardTxn({
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

Widget _txnAvatarWidget(DashboardTxn transaction) {
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

class DashboardFlowNav {
  DashboardFlowNav._();

  static void openTransactions(
    BuildContext context, {
    required LoanMetrics? metrics,
    required LoanOverview? overview,
    required List<DashboardTxn> transactions,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AllTransactionsPage(
          transactions: transactions,
          metrics: metrics,
          overview: overview,
        ),
      ),
    );
  }

  static void openOverview(
    BuildContext context, {
    required LoanMetrics? metrics,
    required LoanOverview? overview,
    required List<DashboardTxn> transactions,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OverviewPage(
          metrics: metrics,
          overview: overview,
          transactions: transactions,
        ),
      ),
    );
  }

  static void openLoanInsights(
    BuildContext context, {
    required LoanMetrics? metrics,
    required LoanOverview? overview,
    required List<DashboardTxn> transactions,
    LoanOverview? initialOverview,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoanInsightsPage(
          initialOverview: initialOverview ?? overview,
          bottomNavigationBar: miniBottomNav(
            activeTab: DashboardMiniNavTab.loanInsights,
            metrics: metrics,
            overview: overview,
            transactions: transactions,
          ),
        ),
      ),
    );
  }

  static void openReports(
    BuildContext context, {
    required LoanMetrics? metrics,
    required LoanOverview? overview,
    required List<DashboardTxn> transactions,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsComingSoonPage(
          showBackButton: false,
          bottomNavigationBar: miniBottomNav(
            activeTab: DashboardMiniNavTab.reports,
            metrics: metrics,
            overview: overview,
            transactions: transactions,
          ),
        ),
      ),
    );
  }

  static Widget miniBottomNav({
    required DashboardMiniNavTab activeTab,
    required LoanMetrics? metrics,
    required LoanOverview? overview,
    required List<DashboardTxn> transactions,
  }) {
    return DashboardMiniBottomNav(
      activeTab: activeTab,
      metrics: metrics,
      overview: overview,
      transactions: transactions,
    );
  }
}

Future<List<DashboardTxn>> fetchDashboardTransactions() async {
  try {
    final transactions = await ServiceLocator.repaymentsApi.fetchAllTransactions();
    final tx = <DashboardTxn>[];

    for (final item in transactions) {
      final loanType = (item['loanType'] ?? '').toString().trim();
      final customerName = (item['customerName'] ?? '').toString().trim();
      final notes = (item['notes'] ?? '').toString().trim();
      final label = loanType.isEmpty ? 'Transaction' : '$loanType Repayment';
      final lowerNotes = notes.toLowerCase();
      final isLoan = lowerNotes.contains('loan disbursed') ||
          lowerNotes.contains('new loan');

      tx.add(
        DashboardTxn(
          customerId: (item['customerId'] ?? '').toString(),
          customerName:
              customerName.isEmpty ? 'Unknown customer' : customerName,
          customerProfileImage: item['customerProfileImage']?.toString(),
          amount: _numFromStatic(item, const ['amountPaid', 'amount', 'paymentAmount']),
          date: _dateFromStatic(
            item,
            const ['paymentDate', 'date', 'createdAt', 'transactionDate'],
          ),
          isLoan: isLoan,
          label: label,
        ),
      );
    }

    tx.sort((a, b) => _parseDateStatic(b.date).compareTo(_parseDateStatic(a.date)));
    return tx;
  } catch (_) {
    return const [];
  }
}

double _numFromStatic(Map<String, dynamic> map, List<String> keys) {
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

String _dateFromStatic(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return DateTime.now().toIso8601String();
}

DateTime _parseDateStatic(String value) {
  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// Reports tab for [AppShellPage] with dashboard mini navigation.
class DashboardReportsTab extends StatefulWidget {
  const DashboardReportsTab({super.key});

  @override
  State<DashboardReportsTab> createState() => _DashboardReportsTabState();
}

class _DashboardReportsTabState extends State<DashboardReportsTab> {
  List<DashboardTxn> _transactions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    await state.loadDashboardMetricsFromApi();
    await state.loadDashboardOverviewFromApi(months: 6);
    final txs = await fetchDashboardTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = context.watch<AppState>();
    return ReportsComingSoonPage(
      showBackButton: false,
      bottomNavigationBar: DashboardFlowNav.miniBottomNav(
        activeTab: DashboardMiniNavTab.reports,
        metrics: state.dashboardMetrics,
        overview: state.dashboardOverview,
        transactions: _transactions,
      ),
    );
  }
}
