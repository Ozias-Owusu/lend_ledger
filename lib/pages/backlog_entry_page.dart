import 'package:flutter/material.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/transactionRecord.dart';

import 'add_transaction_page.dart';

class BacklogEntryPage extends StatelessWidget {
  const BacklogEntryPage({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Back Log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _optionTile(
            context: context,
            title: 'Back Log Daily Loan',
            subtitle: 'Record old daily loan with custom date and time',
            icon: Icons.calendar_today_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(
                  customer: customer,
                  preselectedType: TransactionType.loan,
                  preselectedLoanKind: 'Daily Loan',
                  enableCustomDateTime: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _optionTile(
            context: context,
            title: 'Back Log Soft Loan',
            subtitle: 'Record old soft loan with custom date and time',
            icon: Icons.handshake_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(
                  customer: customer,
                  preselectedType: TransactionType.loan,
                  preselectedLoanKind: 'Soft Loan',
                  enableCustomDateTime: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _optionTile(
            context: context,
            title: 'Back Log Repayment',
            subtitle: 'Record old repayment with custom payment date and time',
            icon: Icons.arrow_upward_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(
                  customer: customer,
                  preselectedType: TransactionType.repayment,
                  enableCustomDateTime: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
