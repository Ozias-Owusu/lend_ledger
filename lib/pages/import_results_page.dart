import 'package:flutter/material.dart';
import 'package:lend_ledger/models/bulk_import_models.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';

class ImportResultsPage extends StatelessWidget {
  const ImportResultsPage({
    super.key,
    required this.title,
    required this.result,
  });

  final String title;
  final BulkImportResult result;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: AuthAnimatedBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '$title import results',
                          style: AppTheme.display(fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryCards(result: result),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    child: TabBar(
                      labelColor: AppTheme.textPrimary,
                      unselectedLabelColor: AppTheme.textMuted,
                      indicatorColor: AppTheme.softRose,
                      indicatorWeight: 3,
                      labelStyle: AppTheme.body(fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: 'All (${result.totalRows})'),
                        Tab(text: 'Failed (${result.failedRows})'),
                        Tab(text: 'OK (${result.successfulRows})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ResultList(rows: result.results),
                      _ResultList(rows: result.failed),
                      _ResultList(rows: result.succeeded),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.softRose,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Done',
                      style: AppTheme.body(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.result});

  final BulkImportResult result;

  @override
  Widget build(BuildContext context) {
    final headline = result.allSucceeded
        ? 'All rows imported successfully'
        : result.allFailed
            ? 'Import failed — no rows were added'
            : 'Import finished with some errors';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: AppTheme.body(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (result.hasFailures && result.successfulRows > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Valid rows were saved. Fix the failed rows in your file and upload again if needed.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '${result.totalRows}',
                color: AppTheme.textPrimary,
                icon: Icons.table_rows_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Imported',
                value: '${result.successfulRows}',
                color: const Color(0xFF2E7D52),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Failed',
                value: '${result.failedRows}',
                color: result.failedRows > 0
                    ? Colors.red.shade700
                    : AppTheme.textMuted,
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.mintGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.display(fontSize: 22, color: color),
          ),
          Text(label, style: AppTheme.body(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.rows});

  final List<BulkImportRowResult> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No rows in this tab.',
          style: AppTheme.body(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _ResultTile(row: row);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.row});

  final BulkImportRowResult row;

  @override
  Widget build(BuildContext context) {
    final ok = row.success;
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ok
                    ? const Color(0xFFE8F5E9)
                    : Colors.red.shade50,
              ),
              child: Icon(
                ok ? Icons.check_rounded : Icons.close_rounded,
                color: ok ? const Color(0xFF2E7D52) : Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Row ${row.rowNumber}',
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (row.detail != null && row.detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      row.detail!,
                      style: AppTheme.body(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    row.message,
                    style: AppTheme.body(
                      fontSize: 13,
                      color: ok ? AppTheme.textSecondary : Colors.red.shade800,
                      fontWeight: ok ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
