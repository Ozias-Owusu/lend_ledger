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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'add_transaction_page.dart';

class CustomerLedgerPage extends StatefulWidget {
  final Customer customer;

  const CustomerLedgerPage({super.key, required this.customer});

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  late Future<Customer> _customerFuture;

  @override
  void initState() {
    super.initState();
    _customerFuture = context
        .read<AppState>()
        .fetchCustomerDetailsFromApi(widget.customer.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),
      body: FutureBuilder<Customer>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Unable to load customer details.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _customerFuture = context
                              .read<AppState>()
                              .fetchCustomerDetailsFromApi(widget.customer.id);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final customer = snapshot.data!;
          final items = _buildLedgerItems(customer);
          final borrowed = items.fold(0.0, (sum, item) => sum + item.principalAmount);
          final repaid = items
              .where((item) => item.status.toLowerCase() == 'inactive')
              .fold(0.0, (sum, item) => sum + item.totalRepayableAmount);
          final balance = items
              .where((item) => item.status.toLowerCase() == 'active')
              .fold(0.0, (sum, item) => sum + item.totalRepayableAmount);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _customerFuture = context
                    .read<AppState>()
                    .fetchCustomerDetailsFromApi(widget.customer.id);
              });
              await _customerFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(customer),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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
                            Text("${items.length} transactions"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 30),
                              child: Text("No transactions yet"),
                            ),
                          ),
                        for (final item in items) _transactionCard(item),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    const SizedBox(
                      height: 20,
                    ),
                  if (items.isNotEmpty)
                    const SizedBox(
                      height: 10,
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: widget.customer,
                    preselectedType: TransactionType.loan,
                    preselectedLoanKind: "Daily Loan",
                  ),
                ),
              );
              if (!mounted) return;
              setState(() {
                _customerFuture = context
                    .read<AppState>()
                    .fetchCustomerDetailsFromApi(widget.customer.id);
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.handshake),
            label: "Soft Loan",
            backgroundColor: Colors.orange,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: widget.customer,
                    preselectedType: TransactionType.loan,
                    preselectedLoanKind: "Soft Loan",
                  ),
                ),
              );
              if (!mounted) return;
              setState(() {
                _customerFuture = context
                    .read<AppState>()
                    .fetchCustomerDetailsFromApi(widget.customer.id);
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.arrow_upward),
            label: "Repayment",
            backgroundColor: Colors.green,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    customer: widget.customer,
                    preselectedType: TransactionType.repayment,
                  ),
                ),
              );
              if (!mounted) return;
              setState(() {
                _customerFuture = context
                    .read<AppState>()
                    .fetchCustomerDetailsFromApi(widget.customer.id);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Customer customer) {
    final profileBytes = _safeBase64(customer.profilePicture);
    final hasImage = profileBytes != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 78,
              height: 78,
              child: hasImage
                  ? Image.memory(
                      profileBytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _headerInitialAvatar(customer),
                    )
                  : _headerInitialAvatar(customer),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "📞 ${customer.phone}",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                Text(
                  "💳 ${customer.ghanaCardNumber.isEmpty ? 'Ghana card not set' : customer.ghanaCardNumber}",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                Text(
                  "🪪 ${customer.licenseIdNumber.isEmpty ? 'License not set' : customer.licenseIdNumber}",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerInitialAvatar(Customer customer) {
    return Container(
      color: Colors.grey.shade500,
      alignment: Alignment.center,
      child: Text(
        customer.firstInitial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Uint8List? _safeBase64(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      return base64Decode(input);
    } catch (_) {
      return null;
    }
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
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

  Widget _transactionCard(_LedgerItem t) {
    final isLoan = t.loanType == 'Daily Loan' || t.loanType == 'Soft Loan';
    final isInactive = t.status.toLowerCase() == 'inactive';
    final color = isInactive ? Colors.grey : (isLoan ? Colors.red : Colors.green);
    final icon = isLoan ? Icons.arrow_downward : Icons.arrow_upward;

    final title = "Loan - ${t.loanType}";

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isInactive ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
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
                "GHS ${t.totalRepayableAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Principal: GHS ${t.principalAmount.toStringAsFixed(2)} | Interest: GHS ${t.interestAmount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            "Status: ${t.status}",
            style: TextStyle(
              fontSize: 13,
              color: isInactive ? Colors.grey : Colors.red,
            ),
          ),
          if (t.note.isNotEmpty)
            Text(
              t.note,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM, yyyy - hh:mm a').format(t.loanDate),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  List<_LedgerItem> _buildLedgerItems(Customer customer) {
    final List<_LedgerItem> items = [];
    for (final loan in customer.dailyLoans) {
      items.add(
        _LedgerItem(
          id: (loan['id'] ?? '').toString(),
          loanType: 'Daily Loan',
          principalAmount: _num(loan['principalAmount']),
          interestAmount: _num(loan['interestAmount']),
          totalRepayableAmount: _num(loan['totalRepayableAmount']),
          loanDate: _parseDate(loan['loanDate']),
          status: (loan['status'] ?? '').toString(),
          note: (loan['notes'] ?? '').toString(),
        ),
      );
    }
    for (final loan in customer.softLoans) {
      final principal = _num(loan['principalAmount']);
      final total = _num(loan['totalRepayableAmount']);
      items.add(
        _LedgerItem(
          id: (loan['id'] ?? '').toString(),
          loanType: 'Soft Loan',
          principalAmount: principal,
          interestAmount: (total - principal).clamp(0, 1e18).toDouble(),
          totalRepayableAmount: total,
          loanDate: _parseDate(loan['loanStartDate']),
          status: (loan['status'] ?? '').toString(),
          note: (loan['notes'] ?? '').toString(),
        ),
      );
    }
    items.sort((a, b) => b.loanDate.compareTo(a.loanDate));
    return items;
  }

  double _num(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;

  DateTime _parseDate(dynamic value) => DateTime.tryParse('${value ?? ''}') ?? DateTime.now();
}

class _LedgerItem {
  final String id;
  final String loanType;
  final double principalAmount;
  final double interestAmount;
  final double totalRepayableAmount;
  final DateTime loanDate;
  final String status;
  final String note;

  _LedgerItem({
    required this.id,
    required this.loanType,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalRepayableAmount,
    required this.loanDate,
    required this.status,
    required this.note,
  });
}
