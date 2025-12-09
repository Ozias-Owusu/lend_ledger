// import 'package:flutter/material.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'package:lend_ledger/models/customer.dart';
// import 'package:lend_ledger/models/transactionRecord.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';
// import 'add_transaction_page.dart';
//
// class CustomerLedgerPage extends StatelessWidget {
//   final Customer customer;
//
//   const CustomerLedgerPage({super.key, required this.customer});
//
//   @override
//   Widget build(BuildContext context) {
//     final state = Provider.of<AppState>(context);
//     final transactions = state.transactionsForCustomer(customer.id);
//
//     final borrowed = state.totalBorrowed(customer.id);
//     final repaid = state.totalRepaid(customer.id);
//     final balance = state.computeBalance(customer.id);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(customer.name),
//       ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 8,
//                       offset: Offset(0, 2))
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     customer.name,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   Text(
//                     "💳 Ghana Card ID: ${customer.ghanaCardNumber}",
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                   Text(
//                     "📞 Phone: ${customer.phone}",
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // -------------------------------
//             // SUMMARY (Borrowed, Repaid, Balance)
//             // -------------------------------
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _summaryCard(
//                   icon: Icons.arrow_downward,
//                   iconColor: Colors.blue,
//                   label: "Borrowed",
//                   amount: borrowed,
//                 ),
//                 _summaryCard(
//                   icon: Icons.arrow_upward,
//                   iconColor: Colors.green,
//                   label: "Repaid",
//                   amount: repaid,
//                 ),
//                 _summaryCard(
//                   icon: Icons.warning_amber_rounded,
//                   iconColor: Colors.red,
//                   label: "Balance",
//                   amount: balance,
//                   amountColor: Colors.red,
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 26),
//
//             // -------------------------------
//             // TRANSACTION HISTORY TITLE
//             // -------------------------------
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Transaction History",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text("${transactions.length} transactions"),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // -------------------------------
//             // TRANSACTIONS LIST
//             // -------------------------------
//             if (transactions.isEmpty)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.only(top: 30),
//                   child: Text("No transactions yet"),
//                 ),
//               ),
//
//             for (var t in transactions) _transactionCard(t),
//           ],
//         ),
//       ),
//       floatingActionButton: SpeedDial(
//         icon: Icons.add,
//         activeIcon: Icons.close,
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         overlayOpacity: 0.3,
//         spacing: 12,
//         spaceBetweenChildren: 12,
//         animationDuration: const Duration(milliseconds: 300),
//
//         children: [
//
//           // ---------------- Daily Loan ----------------
//           SpeedDialChild(
//             child: const Icon(Icons.calendar_today),
//             label: "Daily Loan",
//             backgroundColor: Colors.redAccent,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AddTransactionPage(
//                     customer: customer,
//                     preselectedType: TransactionType.loan,
//                     preselectedLoanKind: "Daily Loan",
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // ---------------- Soft Loan ----------------
//           SpeedDialChild(
//             child: const Icon(Icons.handshake),
//             label: "Soft Loan",
//             backgroundColor: Colors.orange,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AddTransactionPage(
//                     customer: customer,
//                     preselectedType: TransactionType.loan,
//                     preselectedLoanKind: "Soft Loan",
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // ---------------- Repayment ----------------
//           SpeedDialChild(
//             child: const Icon(Icons.arrow_upward),
//             label: "Repayment",
//             backgroundColor: Colors.green,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AddTransactionPage(
//                     customer: customer,
//                     preselectedType: TransactionType.repayment,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------
//   // MINI SUMMARY CARDS
//   // -------------------------------
//   Widget _summaryCard({
//     required IconData icon,
//     required Color iconColor,
//     required String label,
//     required double amount,
//     Color? amountColor,
//   }) {
//     return Container(
//       width: 110,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: iconColor),
//           const SizedBox(height: 6),
//           Text(label),
//           const SizedBox(height: 4),
//           Text(
//             "₵${amount.toStringAsFixed(2)}",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: amountColor ?? Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/customer_ledger_page.dart
//
//   Widget _transactionCard(TransactionRecord t) {
//     final isLoan = t.type == TransactionType.loan;
//     final color = isLoan ? Colors.red : Colors.green;
//     final icon = isLoan ? Icons.arrow_downward : Icons.arrow_upward;
//     double interest = t.amount * (t.interestPercent / 100);
//     final total = t.amount + interest;
//     double principal = t.amount;
//
//
//     if (isLoan && t.interestPercent > 0) {
//       // Since t.amount is the TOTAL, we need to calculate the original principal.
//       // Formula: principal = total / (1 + interest_rate)
//       principal = t.amount / (1 + (t.interestPercent / 100));
//       interest = t.amount - principal;
//     }
//
//     // *** FIX IS HERE: Create a more descriptive title ***
//     String title;
//
//     if (isLoan) {
//       // If it's a loan, the existing logic is fine.
//       title = "Loan${t.loanKind.isNotEmpty ? ' - ${t.loanKind}' : ''}";
//     } else {
//       // If it's a repayment, check the note to see what kind of loan it was for.
//       if (t.loanKind.toLowerCase().contains('soft')) {
//         title = "Repayment of Soft Loan ";
//       } else if (t.loanKind.toLowerCase().contains('daily')) {
//         title = "Repayment of Daily Loan ";
//       } else {
//         // Fallback if the note doesn't specify.
//         title = "Repayment";
//       }
//     }
//
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black12,
//               blurRadius: 8,
//               offset: const Offset(0, 2))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 backgroundColor: color.withOpacity(0.1),
//                 child: Icon(icon, color: color),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   title, // Use the new descriptive title
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Text(
//                 "GHS ${t.amount.toStringAsFixed(2)}",
//                 style: TextStyle(
//                   color: color,
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           // Only show the interest breakdown for loans
//           if (isLoan && t.interestPercent > 0) ...[
//             const SizedBox(height: 10),
//             Text(
//               "(Loan Amount + Interest = GHS ${t.amount.toStringAsFixed(2)})",
//
//               style: const TextStyle(fontSize: 13, color: Colors.black),
//             ),
//           ],
//           const SizedBox(height: 8),
//           Text(
//             t.date,
//             style: const TextStyle(fontSize: 13, color: Colors.black),
//           ),
//         ],
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:intl/intl.dart';
import 'add_transaction_page.dart';

class CustomerLedgerPage extends StatelessWidget {
  final Customer customer;

  const CustomerLedgerPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    // --- FIX IS HERE: Manually filter and calculate data ---
    // 1. Get all transactions for this specific customer from the main list.
    final transactions = state.transactions
        .where((t) => t.customerId == customer.id)
        .toList();
    // Sort them by date, newest first.
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // 2. Calculate borrowed, repaid, and balance locally.
    double borrowed = 0;
    double repaid = 0;
    double balance = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.loan) {
        borrowed += t.amount;
        balance += t.amount;
      } else {
        repaid += t.amount;
        balance -= t.amount;
      }
    }
    // Ensure balance doesn't show as negative.
    balance = balance > 0.01 ? balance : 0.0;
    // --- END OF FIX ---

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if(customer.ghanaCardNumber != null && customer.ghanaCardNumber!.isNotEmpty)
                    Text(
                      "💳 Ghana Card ID: ${customer.ghanaCardNumber}",
                      style: const TextStyle(fontSize: 15),
                    ),
                  Text(
                    "📞 Phone: ${customer.phone}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SUMMARY CARDS (Now use the locally calculated values)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard(
                  icon: Icons.arrow_downward,
                  iconColor: Colors.blue,
                  label: "Borrowed",
                  amount: borrowed,
                ),
                _summaryCard(
                  icon: Icons.arrow_upward,
                  iconColor: Colors.green,
                  label: "Repaid",
                  amount: repaid,
                ),
                _summaryCard(
                  icon: Icons.account_balance_wallet,
                  iconColor: balance > 0 ? Colors.red : Colors.green,
                  label: "Balance",
                  amount: balance,
                  amountColor: balance > 0 ? Colors.red : Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 26),

            // TRANSACTION HISTORY TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaction History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("${transactions.length} transactions"),
              ],
            ),

            const SizedBox(height: 12),

            // TRANSACTIONS LIST
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text("No transactions yet"),
                ),
              ),

            for (var t in transactions) _transactionCard(t),
          ],
        ),
      ),
      // SpeedDial FAB remains the same
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        overlayOpacity: 0.3,
        spacing: 12,
        spaceBetweenChildren: 12,
        animationDuration: const Duration(milliseconds: 300),

        children: [
          SpeedDialChild(
            child: const Icon(Icons.calendar_today),
            label: "Daily Loan",
            backgroundColor: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: customer,
                    preselectedType: TransactionType.loan,
                    preselectedLoanKind: "Daily Loan",
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.handshake),
            label: "Soft Loan",
            backgroundColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: customer,
                    preselectedType: TransactionType.loan,
                    preselectedLoanKind: "Soft Loan",
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.arrow_upward),
            label: "Repayment",
            backgroundColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: customer,
                    preselectedType: TransactionType.repayment,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    Color? amountColor,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 6),
          Text(label),
          const SizedBox(height: 4),
          Text(
            "GHS ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(TransactionRecord t) {
    final isLoan = t.type == TransactionType.loan;
    final color = isLoan ? Colors.red : Colors.green;
    final icon = isLoan ? Icons.arrow_downward : Icons.arrow_upward;

    String title;
    if (isLoan) {
      title = "Loan${t.loanKind.isNotEmpty ? ' - ${t.loanKind}' : ''}";
    } else {
      title = "Repayment";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "GHS ${t.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isLoan && t.interestPercent > 0) ...[
            const SizedBox(height: 10),
            Text(
              "(Loan Amount + ${t.interestPercent.toStringAsFixed(1)}% Interest = GHS ${t.amount.toStringAsFixed(2)})",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM, yyyy - hh:mm a').format(DateTime.parse(t.date)),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
