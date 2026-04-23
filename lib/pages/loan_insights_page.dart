import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_overview.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';

class LoanInsightsPage extends StatefulWidget {
  const LoanInsightsPage({super.key, this.initialOverview});

  final LoanOverview? initialOverview;

  @override
  State<LoanInsightsPage> createState() => _LoanInsightsPageState();
}

class _LoanInsightsPageState extends State<LoanInsightsPage> {
  LoanOverview? _overview;
  bool _loading = false;
  int _months = 6;

  @override
  void initState() {
    super.initState();
    _overview = widget.initialOverview;
    if (_overview == null) {
      _reload();
    }
  }

  Future<void> _reload([int? months]) async {
    final targetMonths = months ?? _months;
    setState(() {
      _months = targetMonths;
      _loading = true;
    });
    await context.read<AppState>().loadDashboardOverviewFromApi(months: targetMonths);
    if (!mounted) return;
    setState(() {
      _overview = context.read<AppState>().dashboardOverview;
      _loading = false;
    });
  }

  String _monthsLabel() {
    switch (_months) {
      case 1:
        return 'This Month';
      case 3:
        return 'Last 3 Months';
      case 6:
        return 'Last 6 Months';
      case 12:
        return 'Last 12 Months';
      default:
        return 'Last $_months Months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ov = _overview;
    final breakdown = ov?.loanTypeBreakdown;
    final dailyOutstanding = breakdown?.dailyOutstanding ?? 0.0;
    final softOutstanding = breakdown?.softOutstanding ?? 0.0;
    final totalOutstanding = ov?.stats.totalOutstanding ?? dailyOutstanding + softOutstanding;
    final dailyPercent = breakdown?.dailyPercent ??
        (totalOutstanding <= 0 ? 0.0 : dailyOutstanding / totalOutstanding);
    final softPercent = breakdown?.softPercent ??
        (totalOutstanding <= 0 ? 0.0 : softOutstanding / totalOutstanding);
    final totalBorrowed = ov?.stats.totalBorrowedThisMonth ?? 0.0;
    final totalRepaid = ov?.stats.totalRepaidThisMonth ?? 0.0;

    final dailyBorrowed = totalBorrowed * dailyPercent;
    final softBorrowed = totalBorrowed * softPercent;
    final dailyRepaid = totalRepaid * dailyPercent;
    final softRepaid = totalRepaid * softPercent;

    final status = ov?.statusBreakdown;
    final totalLoans = (status?.onTrackCount ?? 0) + (status?.dueSoonCount ?? 0) + (status?.overdueCount ?? 0);
    final dailyCount = (totalLoans * dailyPercent).round();
    final softCount = math.max(0, totalLoans - dailyCount).toInt();
    final dailyAvg = dailyCount == 0 ? 0.0 : dailyOutstanding / dailyCount;
    final softAvg = softCount == 0 ? 0.0 : softOutstanding / softCount;

    final trend = ov?.repaymentTrend ?? const <LoanOverviewTrendPoint>[];
    final topCustomers = (ov?.topCustomers ?? const <OverviewTopCustomer>[])
      ..sort((a, b) => b.outstanding.compareTo(a.outstanding));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECECEF)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Insights',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Detailed insights by loan type',
                        style: TextStyle(color: Colors.black54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  onSelected: _reload,
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
                        const Icon(Icons.calendar_today_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(_monthsLabel(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2ECEE),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: const [
                  Expanded(
                    child: _InsightsTab(label: 'By Loan Type', active: true, icon: Icons.pie_chart_outline_rounded),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _InsightsTab(label: 'By Time', active: false, icon: Icons.show_chart_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final asColumn = constraints.maxWidth < 700;
                final cards = [
                  _loanTypeCard(
                    title: 'Daily Loans',
                    subtitle: 'Short-term loans',
                    chip: '${(dailyPercent * 100).toStringAsFixed(0)}% of total',
                    color: const Color(0xFF4BAF5E),
                    outstanding: dailyOutstanding,
                    repaid: dailyRepaid,
                    borrowed: dailyBorrowed,
                    customers: dailyCount,
                  ),
                  _loanTypeCard(
                    title: 'Soft Loans',
                    subtitle: 'Long-term loans',
                    chip: '${(softPercent * 100).toStringAsFixed(0)}% of total',
                    color: const Color(0xFF4A79C9),
                    outstanding: softOutstanding,
                    repaid: softRepaid,
                    borrowed: softBorrowed,
                    customers: softCount,
                  ),
                ];
                if (asColumn) {
                  return Column(children: [cards[0], const SizedBox(height: 8), cards[1]]);
                }
                return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1])]);
              },
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Performance Comparison', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFECECEF)),
                          ),
                          child: Text(_monthsLabel(), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Text('Daily Loans vs Soft Loans', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _LegendDot(color: Color(0xFF4BAF5E), label: 'Daily Repaid'),
                        _LegendDot(color: Color(0xFF4A79C9), label: 'Soft Repaid'),
                        _LegendDot(color: Color(0xFFD57B8A), label: 'Daily Outstanding'),
                        _LegendDot(color: Color(0xFF8C76C8), label: 'Soft Outstanding'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _InsightsTrendPainter(
                          points: trend.map((p) => _SplitTrendPoint(
                            label: p.month,
                            dailyRepaid: p.repaid * dailyPercent,
                            softRepaid: p.repaid * softPercent,
                            dailyOutstanding: p.outstanding * dailyPercent,
                            softOutstanding: p.outstanding * softPercent,
                          )).toList(),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final asColumn = constraints.maxWidth < 760;
                final children = [
                  _miniDonutCard(
                    title: 'Outstanding by Loan Type',
                    centerTop: AmountFormatter.compactCurrency(totalOutstanding).replaceFirst('GHS ', ''),
                    centerBottom: 'Total',
                    values: [dailyPercent, softPercent],
                    colors: const [Color(0xFF4BAF5E), Color(0xFF4A79C9)],
                    labels: [
                      'Daily Loans ${AmountFormatter.compactCurrency(dailyOutstanding)}',
                      'Soft Loans ${AmountFormatter.compactCurrency(softOutstanding)}',
                    ],
                  ),
                  _miniDonutCard(
                    title: 'Loan Count by Type',
                    centerTop: '$totalLoans',
                    centerBottom: 'Total',
                    values: [
                      totalLoans == 0 ? 0.0 : dailyCount / totalLoans,
                      totalLoans == 0 ? 0.0 : softCount / totalLoans,
                    ],
                    colors: const [Color(0xFFC46AA0), Color(0xFF7B5BC8)],
                    labels: [
                      'Daily Loans $dailyCount',
                      'Soft Loans $softCount',
                    ],
                  ),
                  _avgCard(dailyAvg: dailyAvg, softAvg: softAvg),
                ];
                if (asColumn) {
                  return Column(
                    children: [
                      children[0],
                      const SizedBox(height: 8),
                      children[1],
                      const SizedBox(height: 8),
                      children[2],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: 8),
                    Expanded(child: children[1]),
                    const SizedBox(width: 8),
                    Expanded(child: children[2]),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Customers by Outstanding', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                    const SizedBox(height: 10),
                    if (topCustomers.isEmpty)
                      const Text('No top customers yet.')
                    else
                      ...topCustomers.take(5).toList().asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final c = entry.value;
                        final max = topCustomers.first.outstanding <= 0 ? 1.0 : topCustomers.first.outstanding;
                        final ratio = (c.outstanding / max).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFEAF4EC),
                                child: Text('$idx', style: const TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    value: ratio,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4BAF5E)),
                                    backgroundColor: const Color(0xFFE9E9E9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AmountFormatter.compactCurrency(c.outstanding),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4BAF5E)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanTypeCard({
    required String title,
    required String subtitle,
    required String chip,
    required Color color,
    required double outstanding,
    required double repaid,
    required double borrowed,
    required int customers,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Icon(Icons.calendar_today_outlined, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(chip, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            _metricRow('Outstanding', AmountFormatter.compactCurrency(outstanding), color),
            _metricRow('Repaid', AmountFormatter.compactCurrency(repaid), const Color(0xFF2CA95F)),
            _metricRow('Borrowed', AmountFormatter.compactCurrency(borrowed), const Color(0xFF4A79C9)),
            _metricRow('Customers', '$customers', const Color(0xFF4A4A4A)),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.black54))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _miniDonutCard({
    required String title,
    required String centerTop,
    required String centerBottom,
    required List<double> values,
    required List<Color> colors,
    required List<String> labels,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(90, 90),
                        painter: _DonutPainter(values: values, colors: colors),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(centerTop, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                          Text(centerBottom, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(labels.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Expanded(child: Text(labels[i], style: const TextStyle(fontSize: 11.5))),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avgCard({required double dailyAvg, required double softAvg}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avg. Loan Amount', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('Daily Loans', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            Text(
              AmountFormatter.compactCurrency(dailyAvg),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4BAF5E), fontSize: 30),
            ),
            const SizedBox(height: 8),
            const Text('Soft Loans', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            Text(
              AmountFormatter.compactCurrency(softAvg),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A79C9), fontSize: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.label,
    required this.active,
    required this.icon,
  });

  final String label;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: active ? const Color(0xFFB45A61) : Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? const Color(0xFFB45A61) : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _SplitTrendPoint {
  _SplitTrendPoint({
    required this.label,
    required this.dailyRepaid,
    required this.softRepaid,
    required this.dailyOutstanding,
    required this.softOutstanding,
  });
  final String label;
  final double dailyRepaid;
  final double softRepaid;
  final double dailyOutstanding;
  final double softOutstanding;
}

class _InsightsTrendPainter extends CustomPainter {
  _InsightsTrendPainter({required this.points});
  final List<_SplitTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    var maxVal = 1.0;
    for (final p in points) {
      maxVal = math.max(maxVal, math.max(p.dailyRepaid, math.max(p.softRepaid, math.max(p.dailyOutstanding, p.softOutstanding))));
    }

    final gridPaint = Paint()..color = const Color(0xFFE8E8EA)..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = ((size.height - 18) / 4) * i + 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointAt(int i, double val) {
      final x = points.length == 1 ? 0.0 : (size.width / (points.length - 1)) * i;
      final y = (size.height - 18) - ((val / maxVal) * (size.height - 28)) + 2;
      return Offset(x, y);
    }

    void draw(List<double> series, Color color, {bool dashed = false}) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final p = pointAt(i, series[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (dashed) {
        final metrics = path.computeMetrics().toList();
        for (final metric in metrics) {
          double distance = 0;
          while (distance < metric.length) {
            const dash = 6.0;
            const gap = 4.0;
            final extracted = metric.extractPath(distance, distance + dash);
            canvas.drawPath(extracted, paint);
            distance += dash + gap;
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }

    draw(points.map((e) => e.dailyRepaid).toList(), const Color(0xFF4BAF5E));
    draw(points.map((e) => e.softRepaid).toList(), const Color(0xFF4A79C9));
    draw(points.map((e) => e.dailyOutstanding).toList(), const Color(0xFFD57B8A), dashed: true);
    draw(points.map((e) => e.softOutstanding).toList(), const Color(0xFF8C76C8), dashed: true);
  }

  @override
  bool shouldRepaint(covariant _InsightsTrendPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final basePaint = Paint()
      ..color = const Color(0xFFEFEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final sweep = (math.pi * 2) * v;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
