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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/amount_formatter.dart';
import '../utils/image_data_utils.dart';
import 'add_transaction_page.dart';
import 'backlog_entry_page.dart';

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
    _customerFuture = context.read<AppState>().fetchCustomerDetailsFromApi(
      widget.customer.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
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
          final borrowed = items.fold(
            0.0,
            (sum, item) => sum + item.principalAmount,
          );
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
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      fixedSize: const Size(30, 30),
                      minimumSize: const Size(30, 30),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHeader(customer, colorScheme),
                  const SizedBox(height: 16),
                  Text(
                    "ACCOUNT OVERVIEW",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.south,
                          iconColor: colorScheme.primary,
                          label: "Total Borrowed",
                          amount: borrowed,
                          accent: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.north,
                          iconColor: Colors.green,
                          label: "Total Repaid",
                          amount: repaid,
                          accent: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: colorScheme.tertiary,
                          label: "Current Balance",
                          amount: balance,
                          amountColor: colorScheme.primary,
                          accent: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TRANSACTION HISTORY",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      InkWell(
                        onTap: items.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _AllLedgerTransactionsPage(
                                      customerName: customer.name,
                                      items: items,
                                    ),
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            itemsCountLabel,
                            style: TextStyle(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            "No transactions yet",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ...items.take(1).map(_transactionCard),
                  const SizedBox(height: 20),
                  Text(
                    "LOAN OPTIONS",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _loanOptionTile(
                    icon: Icons.calendar_today,
                    color: colorScheme.primary,
                    title: "Daily Loan",
                    subtitle: "Short term loans for daily needs",
                    onTap: () => _openTransactionPage(
                      AddTransactionPage(
                        customer: widget.customer,
                        preselectedType: TransactionType.loan,
                        preselectedLoanKind: "Daily Loan",
                      ),
                    ),
                  ),
                  _loanOptionTile(
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    title: "Repayment",
                    subtitle: "Make a repayment towards loan",
                    onTap: () => _openTransactionPage(
                      AddTransactionPage(
                        customer: widget.customer,
                        preselectedType: TransactionType.repayment,
                      ),
                    ),
                  ),
                  _loanOptionTile(
                    icon: Icons.account_balance,
                    color: colorScheme.tertiary,
                    title: "Soft Loan",
                    subtitle: "Medium term loan for investment",
                    onTap: () => _openTransactionPage(
                      AddTransactionPage(
                        customer: widget.customer,
                        preselectedType: TransactionType.loan,
                        preselectedLoanKind: "Soft Loan",
                      ),
                    ),
                  ),
                  _loanOptionTile(
                    icon: Icons.history,
                    color: Colors.deepPurple,
                    title: "Back Log",
                    subtitle: "View loan repayment schedule",
                    onTap: () => _openTransactionPage(
                      BacklogEntryPage(customer: widget.customer),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get itemsCountLabel => _lastItemsCount == 1
      ? '1 Transaction'
      : '$_lastItemsCount Transactions';

  int _lastItemsCount = 0;

  Future<void> _openTransactionPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() {
      _customerFuture = context
          .read<AppState>()
          .fetchCustomerDetailsFromApi(widget.customer.id);
    });
  }

  Widget _buildHeader(Customer customer, ColorScheme colorScheme) {
    final profileBytes = _safeBase64(customer.profilePicture);
    final hasImage = profileBytes != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomerDetailsBottomSheet(customer),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 20, 18),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: hasImage
                          ? Image.memory(
                              profileBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _headerInitialAvatar(customer),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "📞 ${customer.phone}",
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        Text(
                          "💳 ${customer.ghanaCardNumber.isEmpty ? 'Ghana card not set' : customer.ghanaCardNumber}",
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        Text(
                          "🪪 ${customer.licenseIdNumber.isEmpty ? 'License not set' : customer.licenseIdNumber}",
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap for full customer details",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerDetailsBottomSheet(Customer customer) {
    final joinedDate = DateTime.tryParse(customer.dateJoined);
    final joinedLabel = joinedDate != null
        ? DateFormat('dd MMM, yyyy').format(joinedDate)
        : customer.dateJoined;
    final colorScheme = Theme.of(context).colorScheme;
    final profileBytes = _safeBase64(customer.profilePicture);
    final hasImage = profileBytes != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.secondary.withValues(alpha: 0.16),
                        child: Icon(
                          Icons.badge_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Customer Details",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.secondary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 82,
                            height: 82,
                            child: hasImage
                                ? Image.memory(
                                    profileBytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _sheetInitialAvatar(customer, colorScheme),
                                  )
                                : _sheetInitialAvatar(customer, colorScheme),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _sheetMiniDetail(Icons.phone_outlined, customer.phone),
                              _sheetMiniDetail(
                                Icons.credit_card_outlined,
                                customer.ghanaCardNumber.isEmpty
                                    ? "Ghana card not set"
                                    : customer.ghanaCardNumber,
                              ),
                              _sheetMiniDetail(
                                Icons.badge_outlined,
                                customer.licenseIdNumber.isEmpty
                                    ? "License not set"
                                    : customer.licenseIdNumber,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionDividerTitle("Personal Information", colorScheme.primary),
                  const SizedBox(height: 8),
                  _sheetInfoRow(Icons.person_outline, "Full Name", customer.name),
                  _sheetInfoRow(Icons.phone_outlined, "Phone", customer.phone),
                  _sheetInfoRow(
                    Icons.credit_card_outlined,
                    "Ghana Card Number",
                    customer.ghanaCardNumber.isEmpty
                        ? "Not set"
                        : customer.ghanaCardNumber,
                  ),
                  _sheetInfoRow(
                    Icons.badge_outlined,
                    "License Number",
                    customer.licenseIdNumber.isEmpty
                        ? "Not set"
                        : customer.licenseIdNumber,
                  ),
                  _sheetInfoRow(Icons.event_outlined, "Date Joined", joinedLabel),
                  const SizedBox(height: 14),
                  _sectionDividerTitle("Loan Summary", colorScheme.primary),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _loanSummaryBox(
                          title: "Daily Loans",
                          value: "${customer.dailyLoans.length}",
                          icon: Icons.history,
                          bg: const Color(0xFFF4F0FF),
                          fg: const Color(0xFF5A49CA),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _loanSummaryBox(
                          title: "Soft Loans",
                          value: "${customer.softLoans.length}",
                          icon: Icons.account_balance,
                          bg: const Color(0xFFEFFAF2),
                          fg: const Color(0xFF1FA35B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetInitialAvatar(Customer customer, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Text(
        customer.firstInitial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _sheetMiniDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDividerTitle(String title, Color color) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _sheetInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFF7ECEC),
            child: Icon(icon, size: 15, color: const Color(0xFFD39A9A)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanSummaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: Icon(icon, color: fg, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
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
    return ImageDataUtils.decodeToBytes(input);
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    required Color accent,
    Color? amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.16),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            AmountFormatter.compactCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor ?? Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            height: 2,
            width: double.infinity,
            color: accent.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _loanOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _transactionCard(_LedgerItem t) {
    final isLoan = t.loanType == 'Daily Loan' || t.loanType == 'Soft Loan';
    final isInactive = t.status.toLowerCase() == 'inactive';
    final color = isInactive
        ? Colors.grey
        : (isLoan ? Colors.red : Colors.green);
    final icon = isLoan ? Icons.arrow_downward : Icons.arrow_upward;

    final title = "Loan - ${t.loanType}";

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isInactive ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
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
                AmountFormatter.compactCurrency(t.totalRepayableAmount),
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
            "Principal: ${AmountFormatter.compactCurrency(t.principalAmount)} | Interest: ${AmountFormatter.compactCurrency(t.interestAmount)}",
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
    _lastItemsCount = items.length;
    return items;
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;

  DateTime _parseDate(dynamic value) =>
      DateTime.tryParse('${value ?? ''}') ?? DateTime.now();
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

class _AllLedgerTransactionsPage extends StatelessWidget {
  const _AllLedgerTransactionsPage({
    required this.customerName,
    required this.items,
  });

  final String customerName;
  final List<_LedgerItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$customerName Transactions')),
      body: items.isEmpty
          ? const Center(child: Text('No transactions yet'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final t = items[index];
                final isLoan =
                    t.loanType == 'Daily Loan' || t.loanType == 'Soft Loan';
                final isInactive = t.status.toLowerCase() == 'inactive';
                final color = isInactive
                    ? Colors.grey
                    : (isLoan ? Colors.red : Colors.green);
                final icon = isLoan ? Icons.arrow_downward : Icons.arrow_upward;

                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isInactive ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Loan - ${t.loanType}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            AmountFormatter.compactCurrency(t.totalRepayableAmount),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Principal: ${AmountFormatter.compactCurrency(t.principalAmount)} | Interest: ${AmountFormatter.compactCurrency(t.interestAmount)}",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        DateFormat('dd MMM, yyyy - hh:mm a').format(t.loanDate),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
