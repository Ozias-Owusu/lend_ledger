import 'package:flutter/material.dart';

class ReportsComingSoonPage extends StatelessWidget {
  const ReportsComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5E9E3), Color(0xFFF0EEF9), Color(0xFFEAF7EF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Row(
                children: [
                  _roundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Reports',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: const Color(0xFFEFEFF1),
                          alignment: Alignment.center,
                          child: const Icon(Icons.bar_chart_rounded, size: 52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3ECFB),
                        border: Border.all(color: const Color(0xFFE2D4F7)),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF8F6BC6),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Reports will be added soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Beautiful charts, advanced analytics, and downloadable summaries are on the way.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.auto_graph_rounded,
                      iconColor: Color(0xFF4A79C9),
                      title: 'Trend Analytics',
                      subtitle: 'Monthly and weekly performance snapshots',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: Color(0xFFCB6262),
                      title: 'Exportable Reports',
                      subtitle: 'PDF and CSV report downloads',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.groups_rounded,
                      iconColor: Color(0xFF4BAF5E),
                      title: 'Customer Insights',
                      subtitle: 'Outstanding and repayment behavior',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: Color(0xFFF0A325),
                      title: 'Smart Alerts',
                      subtitle: 'Overdue and due-soon report triggers',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=1200&q=80',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: const Color(0xFFEFEFF1),
                    alignment: Alignment.center,
                    child: const Icon(Icons.insert_chart_rounded, size: 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6EA)),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: iconColor.withValues(alpha: 0.14),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
