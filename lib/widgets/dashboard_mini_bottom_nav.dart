import 'package:flutter/material.dart';
import 'package:lend_ledger/models/loan_metrics.dart';
import 'package:lend_ledger/models/loan_overview.dart';
import 'package:lend_ledger/pages/dashboard_page.dart';

enum DashboardMiniNavTab { transactions, overview, loanInsights, reports }

class DashboardMiniBottomNav extends StatelessWidget {
  const DashboardMiniBottomNav({
    super.key,
    required this.activeTab,
    required this.metrics,
    required this.overview,
    required this.transactions,
  });

  final DashboardMiniNavTab activeTab;
  final LoanMetrics? metrics;
  final LoanOverview? overview;
  final List<DashboardTxn> transactions;

  void _navigate(BuildContext context, DashboardMiniNavTab target) {
    switch (target) {
      case DashboardMiniNavTab.transactions:
        DashboardFlowNav.openTransactions(
          context,
          metrics: metrics,
          overview: overview,
          transactions: transactions,
        );
      case DashboardMiniNavTab.overview:
        DashboardFlowNav.openOverview(
          context,
          metrics: metrics,
          overview: overview,
          transactions: transactions,
        );
      case DashboardMiniNavTab.loanInsights:
        DashboardFlowNav.openLoanInsights(
          context,
          metrics: metrics,
          overview: overview,
          transactions: transactions,
          initialOverview: overview,
        );
      case DashboardMiniNavTab.reports:
        DashboardFlowNav.openReports(
          context,
          metrics: metrics,
          overview: overview,
          transactions: transactions,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F0F1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MiniNavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Transactions',
              active: activeTab == DashboardMiniNavTab.transactions,
              onTap: activeTab == DashboardMiniNavTab.transactions
                  ? null
                  : (ctx) => _navigate(ctx, DashboardMiniNavTab.transactions),
            ),
            _MiniNavItem(
              icon: Icons.pie_chart_outline_rounded,
              label: 'Overview',
              active: activeTab == DashboardMiniNavTab.overview,
              onTap: activeTab == DashboardMiniNavTab.overview
                  ? null
                  : (ctx) => _navigate(ctx, DashboardMiniNavTab.overview),
            ),
            _MiniNavItem(
              icon: Icons.show_chart_rounded,
              label: 'Loan Insights',
              active: activeTab == DashboardMiniNavTab.loanInsights,
              onTap: activeTab == DashboardMiniNavTab.loanInsights
                  ? null
                  : (ctx) => _navigate(ctx, DashboardMiniNavTab.loanInsights),
            ),
            _MiniNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              active: activeTab == DashboardMiniNavTab.reports,
              onTap: activeTab == DashboardMiniNavTab.reports
                  ? null
                  : (ctx) => _navigate(ctx, DashboardMiniNavTab.reports),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNavItem extends StatelessWidget {
  const _MiniNavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF4DCDD) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? const Color(0xFFB45A61) : const Color(0xFF6F6F72),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFFB45A61) : const Color(0xFF6F6F72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
