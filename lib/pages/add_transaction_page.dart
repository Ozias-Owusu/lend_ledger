//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:lend_ledger/db/soft_loan_dao.dart';
// import 'package:lend_ledger/models/customer.dart';
// import 'package:lend_ledger/models/loan_record.dart';
// import 'package:lend_ledger/models/soft_loan_details.dart';
// import 'package:lend_ledger/models/transactionRecord.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';
//
// // Enum for clarity in duration units
// enum DurationUnit { days, weeks, months }
//
// class AddTransactionPage extends StatefulWidget {
//   final Customer customer;
//   final TransactionType? preselectedType;
//   final String? preselectedLoanKind;
//
//   const AddTransactionPage({
//     super.key,
//     required this.customer,
//     this.preselectedType,
//     this.preselectedLoanKind,
//   });
//
//   @override
//   State<AddTransactionPage> createState() => _AddTransactionPageState();
// }
//
// class _AddTransactionPageState extends State<AddTransactionPage> {
//   late TransactionType _type;
//   late String _loanKind;
//
//   final _amountCtl = TextEditingController();
//   final _durationCtl = TextEditingController(text: '3');
//   double _interestPercent = 5.0;
//
//   // State for flexible duration
//   DurationUnit _durationUnit = DurationUnit.months;
//
//   // State for repayment fields
//   LoanRecord? _selectedLoan;
//   List<LoanRecord> _customerLoans = [];
//   double _outstandingBalance = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _type = widget.preselectedType ?? TransactionType.loan;
//     _loanKind = widget.preselectedLoanKind ?? 'Daily Loan';
//
//     if (_loanKind.toLowerCase().contains("daily")) {
//       _loanKind = "daily";
//       _interestPercent = 5.0;
//     } else if (_loanKind.toLowerCase().contains("soft")) {
//       _loanKind = "soft";
//       _interestPercent = 10.0;
//     } else {
//       _loanKind = "daily";
//     }
//
//     if (_type == TransactionType.repayment) {
//       _loadCustomerLoans();
//     }
//   }
//
//   @override
//   void dispose() {
//     _amountCtl.dispose();
//     _durationCtl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadCustomerLoans() async {
//     final appState = Provider.of<AppState>(context, listen: false);
//     final loans = appState.getCustomerLoans(widget.customer.id);
//     double totalBalance = loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
//
//     setState(() {
//       _customerLoans = loans;
//       _outstandingBalance = totalBalance;
//       if (_customerLoans.isNotEmpty && _selectedLoan == null) {
//         _selectedLoan = _customerLoans.first;
//       }
//     });
//   }
//
//   // --- SAVE TRANSACTION ---
//   Future<void> _saveTransaction() async {
//     final amount = double.tryParse(_amountCtl.text);
//     if (amount == null || amount <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount.")));
//       return;
//     }
//
//     if (_type == TransactionType.repayment) {
//       if (_selectedLoan == null) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select which loan to repay.")));
//         return;
//       }
//       if (amount > _selectedLoan!.remainingAmount) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Repayment can't exceed balance of GHS ${_selectedLoan!.remainingAmount.toStringAsFixed(2)}.")));
//         return;
//       }
//     }
//
//     final appState = Provider.of<AppState>(context, listen: false);
//     final String transactionId = appState.generateUUID(); // Generate a single ID for linking
//     String note = '';
//     double finalAmount = 0;
//     double interestToSave = 0.0;
//
//     // --- Calculation Logic ---
//     if (_type == TransactionType.loan) {
//       final principal = amount;
//       final interest = principal * (_interestPercent / 100);
//       final totalRepayable = principal + interest;
//
//       finalAmount = totalRepayable; // The main transaction amount is the total owed
//       interestToSave = _interestPercent;
//
//       if (_loanKind == 'soft') {
//         final durationValue = int.tryParse(_durationCtl.text) ?? 1;
//
//         // Create the SoftLoanDetails object
//         final softLoanDetails = SoftLoanDetails(
//           transactionId: transactionId,
//           principalAmount: principal,
//           interestRate: _interestPercent,
//           totalRepayable: totalRepayable,
//           installmentAmount: totalRepayable / durationValue,
//           loanDuration: '$durationValue ${_durationUnit.name}',
//           loanEndDate: _calculateEndDate(durationValue, _durationUnit),
//         );
//
//         // Save the details to the new table
//         await SoftLoanDao().insertSoftLoanDetails(softLoanDetails);
//         note = 'Soft Loan - details in soft_loans table';
//       }
//     } else { // Repayment logic
//       finalAmount = amount;
//       note = 'Repayment for loan: ${_selectedLoan!.id}';
//     }
//
//     // Save the main transaction record for both loan types and repayments
//     await appState.addTransaction(
//       id: transactionId,
//       customerId: widget.customer.id,
//       type: _type,
//       loanKind: _type == TransactionType.repayment ? _selectedLoan!.loanKind : _loanKind,
//       amount: finalAmount,
//       interestPercent: interestToSave,
//       date: DateTime.now().toIso8601String(),
//       note: note,
//     );
//
//     if (mounted) Navigator.pop(context);
//   }
//
//   String _calculateEndDate(int value, DurationUnit unit) {
//     Duration duration;
//     switch (unit) {
//       case DurationUnit.days:
//         duration = Duration(days: value);
//         break;
//       case DurationUnit.weeks:
//         duration = Duration(days: value * 7);
//         break;
//       case DurationUnit.months:
//         duration = Duration(days: value * 30); // Approximation
//         break;
//     }
//     return DateFormat('dd MMM, yyyy').format(DateTime.now().add(duration));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isSoftLoan = _type == TransactionType.loan && _loanKind == "soft";
//     final isRepayment = _type == TransactionType.repayment;
//     final title = isRepayment ? "Record Repayment" : isSoftLoan ? "Add Soft Loan" : "Add Daily Loan";
//
//     // --- Calculations for UI display ---
//     final amount = double.tryParse(_amountCtl.text) ?? 0.0;
//     final interest = (_type == TransactionType.loan) ? (amount * _interestPercent / 100) : 0.0;
//     final totalRepayable = amount + interest;
//
//     final durationValue = int.tryParse(_durationCtl.text) ?? 1;
//     String installmentLabel = 'Installment:';
//     double installmentAmount = 0;
//     String loanEndDate = '';
//
//     if (isSoftLoan && durationValue > 0) {
//       installmentAmount = totalRepayable / durationValue;
//       loanEndDate = _calculateEndDate(durationValue, _durationUnit);
//       switch (_durationUnit) {
//         case DurationUnit.days:
//           installmentLabel = 'Daily Payment:';
//           break;
//         case DurationUnit.weeks:
//           installmentLabel = 'Weekly Payment:';
//           break;
//         case DurationUnit.months:
//           installmentLabel = 'Monthly Payment:';
//           break;
//       }
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- SECTION 1: REPAYMENT UI ---
//             if (isRepayment) ...[
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 margin: const EdgeInsets.only(bottom: 25),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.blue.shade100),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text("Outstanding Balance", style: TextStyle(fontSize: 16)),
//                     const SizedBox(height: 8),
//                     Text("GHS${_outstandingBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//               const Text("Select Loan:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),
//               GestureDetector(
//                 onTap: _customerLoans.isEmpty ? null : () => _showLoanSelection(context),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
//                   decoration: BoxDecoration(
//                     color: _customerLoans.isEmpty ? Colors.grey.shade200 : Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.shade300),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _selectedLoan != null ? _formatLoanDisplay(_selectedLoan!) : _customerLoans.isEmpty ? "No active loans" : "Select a loan",
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: _selectedLoan == null ? Colors.grey.shade600 : Colors.black,
//                             fontWeight: _selectedLoan == null ? FontWeight.normal : FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       if (_customerLoans.isNotEmpty) Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               const Text("Repayment Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _amountCtl,
//                 keyboardType: TextInputType.number,
//                 enabled: _selectedLoan != null,
//                 decoration: InputDecoration(
//                   hintText: _selectedLoan != null ? "Enter repayment amount" : "Select a loan first",
//                   border: const OutlineInputBorder(),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 ),
//                 onChanged: (_) => setState(() {}),
//               ),
//             ],
//
//             // --- SECTION 2: LOAN UI (DAILY & SOFT) ---
//             if (!isRepayment) ...[
//               const Text("Loan Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _amountCtl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(hintText: "Enter loan amount", border: OutlineInputBorder(), prefixText: 'GHS '),
//                 onChanged: (_) => setState(() {}),
//               ),
//               const SizedBox(height: 30),
//               Text("Interest Rate: ${_interestPercent.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               Slider(
//                 value: _interestPercent,
//                 min: 0,
//                 max: 20.0,
//                 divisions: 200,
//                 label: "${_interestPercent.toStringAsFixed(1)}%",
//                 onChanged: (value) => setState(() => _interestPercent = value),
//               ),
//               const SizedBox(height: 20),
//               if (isSoftLoan) ...[
//                 const Text("Loan Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: TextFormField(
//                         controller: _durationCtl,
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                         decoration: const InputDecoration(border: OutlineInputBorder()),
//                         onChanged: (_) => setState(() {}),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       flex: 3,
//                       child: DropdownButtonFormField<DurationUnit>(
//                         value: _durationUnit,
//                         items: const [
//                           DropdownMenuItem(value: DurationUnit.days, child: Text('Days')),
//                           DropdownMenuItem(value: DurationUnit.weeks, child: Text('Weeks')),
//                           DropdownMenuItem(value: DurationUnit.months, child: Text('Months')),
//                         ],
//                         onChanged: (value) => setState(() => _durationUnit = value!),
//                         decoration: const InputDecoration(border: OutlineInputBorder()),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),
//               ],
//               Card(
//                 elevation: 2,
//                 color: Colors.indigo.shade50,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       _summaryRow("Total Repayable:", "GHS ${totalRepayable.toStringAsFixed(2)}"),
//                       if (isSoftLoan) ...[
//                         const Divider(height: 20),
//                         _summaryRow(installmentLabel, "GHS ${installmentAmount.toStringAsFixed(2)}"),
//                         const Divider(height: 20),
//                         _summaryRow("Loan End Date:", loanEndDate),
//                       ]
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: (_customerLoans.isEmpty && isRepayment) ? null : _saveTransaction,
//         icon: const Icon(Icons.save),
//         label: const Text("Save Transaction"),
//       ),
//     );
//   }
//
//   // Helper for summary rows
//   Widget _summaryRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
//         Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
//       ],
//     );
//   }
//
//   // All other helper methods like _showLoanSelection and _formatLoanDisplay remain here
//   void _showLoanSelection(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.6,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text("Select Loan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: _customerLoans.isEmpty
//                     ? const Center(child: Text("No active loans found"))
//                     : ListView.builder(
//                   itemCount: _customerLoans.length,
//                   itemBuilder: (context, index) {
//                     final loan = _customerLoans[index];
//                     final isSelected = _selectedLoan?.id == loan.id;
//                     return ListTile(
//                       title: Text(_formatLoanDisplay(loan), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
//                       leading: Radio<LoanRecord>(
//                         value: loan,
//                         groupValue: _selectedLoan,
//                         onChanged: (value) {
//                           setState(() => _selectedLoan = value);
//                           Navigator.pop(context);
//                         },
//                       ),
//                       onTap: () {
//                         setState(() => _selectedLoan = loan);
//                         Navigator.pop(context);
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   String _formatLoanDisplay(LoanRecord loan) {
//     final currencySymbol = 'GHS';
//     final loanBalance = loan.remainingAmount;
//     final loanDate = DateTime.tryParse(loan.date);
//     final formattedDate = loanDate != null ? DateFormat('dd/MM/yyyy').format(loanDate) : "Unknown Date";
//     final status = loan.isOverdue ? ' (Overdue)' : '';
//     return '$currencySymbol${loanBalance.toStringAsFixed(2)} - Due: $formattedDate$status';
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:intl/intl.dart';
// // import 'package:lend_ledger/models/customer.dart';
// // import 'package:lend_ledger/models/loan_record.dart';
// // import 'package:lend_ledger/models/transactionRecord.dart';
// // import 'package:provider/provider.dart';
// // import '../state/app_state.dart';
// //
// // // Enum for clarity in duration units
// // enum DurationUnit { days, weeks, months }
// //
// // class AddTransactionPage extends StatefulWidget {
// //   final Customer customer;
// //   final TransactionType? preselectedType;
// //   final String? preselectedLoanKind;
// //
// //   const AddTransactionPage({
// //     super.key,
// //     required this.customer,
// //     this.preselectedType,
// //     this.preselectedLoanKind,
// //   });
// //
// //   @override
// //   State<AddTransactionPage> createState() => _AddTransactionPageState();
// // }
// //
// // class _AddTransactionPageState extends State<AddTransactionPage> {
// //   late TransactionType _type;
// //   late String _loanKind;
// //
// //   final _amountCtl = TextEditingController();
// //   final _durationCtl = TextEditingController(text: '3'); // Controller for duration value
// //   double _interestPercent = 5.0;
// //
// //   // --- NEW: State for flexible duration ---
// //   DurationUnit _durationUnit = DurationUnit.months; // Default to months
// //
// //   // For repayment specific fields
// //   LoanRecord? _selectedLoan;
// //   List<LoanRecord> _customerLoans = [];
// //   double _outstandingBalance = 0.0;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _type = widget.preselectedType ?? TransactionType.loan;
// //     _loanKind = widget.preselectedLoanKind ?? 'Daily Loan';
// //
// //     if (_loanKind.toLowerCase().contains("daily")) {
// //       _loanKind = "daily";
// //       _interestPercent = 5.0;
// //     } else if (_loanKind.toLowerCase().contains("soft")) {
// //       _loanKind = "soft";
// //       _interestPercent = 10.0;
// //     } else {
// //       _loanKind = "daily";
// //     }
// //
// //     if (_type == TransactionType.repayment) {
// //       _loadCustomerLoans();
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _amountCtl.dispose();
// //     _durationCtl.dispose();
// //     super.dispose();
// //   }
// //
// //   // --- All helper methods like _loadCustomerLoans, _showLoanSelection, etc., are fine ---
// //   // Omitted for brevity, but they should remain in your code.
// //   Future<void> _loadCustomerLoans() async {
// //     final appState = Provider.of<AppState>(context, listen: false);
// //     final loans = appState.getCustomerLoans(widget.customer.id);
// //     double totalBalance = loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
// //
// //     setState(() {
// //       _customerLoans = loans;
// //       _outstandingBalance = totalBalance;
// //       if (_customerLoans.isNotEmpty && _selectedLoan == null) {
// //         _selectedLoan = _customerLoans.first;
// //       }
// //     });
// //   }
// //
// //   void _showLoanSelection(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return Container(
// //           height: MediaQuery.of(context).size.height * 0.6,
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             children: [
// //               const Text("Select Loan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //               const SizedBox(height: 20),
// //               Expanded(
// //                 child: _customerLoans.isEmpty
// //                     ? const Center(child: Text("No active loans found"))
// //                     : ListView.builder(
// //                   itemCount: _customerLoans.length,
// //                   itemBuilder: (context, index) {
// //                     final loan = _customerLoans[index];
// //                     final isSelected = _selectedLoan?.id == loan.id;
// //                     return ListTile(
// //                       title: Text(_formatLoanDisplay(loan), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
// //                       leading: Radio<LoanRecord>(
// //                         value: loan,
// //                         groupValue: _selectedLoan,
// //                         onChanged: (value) {
// //                           setState(() => _selectedLoan = value);
// //                           Navigator.pop(context);
// //                         },
// //                       ),
// //                       onTap: () {
// //                         setState(() => _selectedLoan = loan);
// //                         Navigator.pop(context);
// //                       },
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   String _formatLoanDisplay(LoanRecord loan) {
// //     final currencySymbol = 'GHS';
// //     final loanBalance = loan.remainingAmount;
// //     final loanDate = DateTime.tryParse(loan.date);
// //     final formattedDate = loanDate != null ? DateFormat('dd/MM/yyyy').format(loanDate) : "Unknown Date";
// //     final status = loan.isOverdue ? ' (Overdue)' : '';
// //     return '$currencySymbol${loanBalance.toStringAsFixed(2)} - Due: $formattedDate$status';
// //   }
// //
// //
// //   Future<void> _saveTransaction() async {
// //     final amount = double.tryParse(_amountCtl.text);
// //     if (amount == null || amount <= 0) {
// //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount.")));
// //       return;
// //     }
// //
// //     if (_type == TransactionType.repayment) {
// //       if (_selectedLoan == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select which loan to repay.")));
// //         return;
// //       }
// //       if (amount > _selectedLoan!.remainingAmount) {
// //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Repayment can't exceed balance of GHS ${_selectedLoan!.remainingAmount.toStringAsFixed(2)}.")));
// //         return;
// //       }
// //     }
// //
// //     final appState = Provider.of<AppState>(context, listen: false);
// //     String note = '';
// //     String loanKind = _loanKind;
// //     double finalAmount = amount;
// //     double interestToSave = 0.0;
// //
// //     if (_type == TransactionType.loan) {
// //       final interest = amount * (_interestPercent / 100);
// //       finalAmount = amount + interest;
// //       interestToSave = _interestPercent;
// //
// //       if (loanKind == 'soft') {
// //         // --- NEW: Save the precise duration to the note ---
// //         final durationValue = int.tryParse(_durationCtl.text) ?? 1;
// //         note = 'Duration: $durationValue ${_durationUnit.name}';
// //       }
// //     }
// //
// //     if (_type == TransactionType.repayment) {
// //       note = 'Repayment for loan: ${_selectedLoan!.id}';
// //       loanKind = _selectedLoan!.loanKind;
// //     }
// //
// //     await appState.addTransaction(
// //       customerId: widget.customer.id,
// //       type: _type,
// //       loanKind: loanKind,
// //       amount: finalAmount,
// //       interestPercent: interestToSave,
// //       date: DateTime.now().toIso8601String(),
// //       note: note,
// //     );
// //
// //     if (mounted) Navigator.pop(context);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isSoftLoan = _type == TransactionType.loan && _loanKind == "soft";
// //     final isRepayment = _type == TransactionType.repayment;
// //     final title = isRepayment ? "Record Repayment" : isSoftLoan ? "Add Soft Loan" : "Add Daily Loan";
// //
// //     final amount = double.tryParse(_amountCtl.text) ?? 0.0;
// //     final interest = (_type == TransactionType.loan) ? (amount * _interestPercent / 100) : 0.0;
// //     final totalRepayable = amount + interest;
// //
// //     // --- NEW: Updated calculation logic for installment and end date ---
// //     final durationValue = int.tryParse(_durationCtl.text) ?? 1;
// //     String installmentLabel = 'Installment:';
// //     double installmentAmount = 0;
// //     String loanEndDate = '';
// //
// //     if (isSoftLoan && durationValue > 0) {
// //       Duration duration;
// //       switch(_durationUnit) {
// //         case DurationUnit.days:
// //           duration = Duration(days: durationValue);
// //           installmentLabel = 'Daily Payment:';
// //           installmentAmount = totalRepayable / durationValue;
// //           break;
// //         case DurationUnit.weeks:
// //           duration = Duration(days: durationValue * 7);
// //           installmentLabel = 'Weekly Payment:';
// //           installmentAmount = totalRepayable / durationValue;
// //           break;
// //         case DurationUnit.months:
// //           duration = Duration(days: durationValue * 30);
// //           installmentLabel = 'Monthly Payment:';
// //           installmentAmount = totalRepayable / durationValue;
// //           break;
// //       }
// //       loanEndDate = DateFormat('dd MMM, yyyy').format(DateTime.now().add(duration));
// //     }
// //
// //
// //     return Scaffold(
// //       appBar: AppBar(title: Text(title)),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // --- REPAYMENT UI SECTION (Unchanged) ---
// //             if (isRepayment) ...[
// //               // Your existing repayment UI
// //               Container(
// //                 width: double.infinity,
// //                 padding: const EdgeInsets.all(20),
// //                 margin: const EdgeInsets.only(bottom: 25),
// //                 decoration: BoxDecoration(
// //                   color: Colors.blue.shade50,
// //                   borderRadius: BorderRadius.circular(16),
// //                   border: Border.all(color: Colors.blue.shade100),
// //                 ),
// //                 child: Column(
// //                   children: [
// //                     const Text("Outstanding Balance", style: TextStyle(fontSize: 16)),
// //                     const SizedBox(height: 8),
// //                     Text("GHS${_outstandingBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
// //                   ],
// //                 ),
// //               ),
// //               const Text("Select Loan:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //               const SizedBox(height: 10),
// //               GestureDetector(
// //                 onTap: _customerLoans.isEmpty ? null : () => _showLoanSelection(context),
// //                 child: Container(
// //                   width: double.infinity,
// //                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
// //                   decoration: BoxDecoration(
// //                     color: _customerLoans.isEmpty ? Colors.grey.shade200 : Colors.grey.shade100,
// //                     borderRadius: BorderRadius.circular(8),
// //                     border: Border.all(color: Colors.grey.shade300),
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Expanded(
// //                         child: Text(
// //                           _selectedLoan != null
// //                               ? _formatLoanDisplay(_selectedLoan!)
// //                               : _customerLoans.isEmpty
// //                               ? "No active loans"
// //                               : "Select a loan",
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             color: _selectedLoan == null ? Colors.grey.shade600 : Colors.black,
// //                             fontWeight: _selectedLoan == null ? FontWeight.normal : FontWeight.w500,
// //                           ),
// //                         ),
// //                       ),
// //                       if (_customerLoans.isNotEmpty) Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 30),
// //               const Text("Repayment Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //               const SizedBox(height: 10),
// //               TextField(
// //                 controller: _amountCtl,
// //                 keyboardType: TextInputType.number,
// //                 enabled: _selectedLoan != null,
// //                 decoration: InputDecoration(
// //                   hintText: _selectedLoan != null ? "Enter repayment amount" : "Select a loan first",
// //                   border: const OutlineInputBorder(),
// //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// //                 ),
// //                 onChanged: (_) => setState(() {}),
// //               ),
// //             ],
// //
// //             // --- LOAN UI SECTION ---
// //             if (!isRepayment) ...[
// //               const Text("Loan Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //               const SizedBox(height: 10),
// //               TextField(
// //                 controller: _amountCtl,
// //                 keyboardType: TextInputType.number,
// //                 decoration: const InputDecoration(hintText: "Enter loan amount", border: OutlineInputBorder(), prefixText: 'GHS '),
// //                 onChanged: (_) => setState(() {}),
// //               ),
// //               const SizedBox(height: 30),
// //               Text("Interest Rate: ${_interestPercent.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //               Slider(
// //                 value: _interestPercent,
// //                 min: 0,
// //                 max: 20.0,
// //                 divisions: 200,
// //                 label: "${_interestPercent.toStringAsFixed(1)}%",
// //                 onChanged: (value) => setState(() => _interestPercent = value),
// //               ),
// //               const SizedBox(height: 20),
// //
// //               // --- NEW: Soft Loan Duration UI ---
// //               if (isSoftLoan) ...[
// //                 const Text("Loan Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 10),
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       flex: 2,
// //                       child: TextFormField(
// //                         controller: _durationCtl,
// //                         keyboardType: TextInputType.number,
// //                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// //                         decoration: const InputDecoration(
// //                           border: OutlineInputBorder(),
// //                         ),
// //                         onChanged: (_) => setState(() {}),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Expanded(
// //                       flex: 3,
// //                       child: DropdownButtonFormField<DurationUnit>(
// //                         value: _durationUnit,
// //                         items: const [
// //                           DropdownMenuItem(value: DurationUnit.days, child: Text('Days')),
// //                           DropdownMenuItem(value: DurationUnit.weeks, child: Text('Weeks')),
// //                           DropdownMenuItem(value: DurationUnit.months, child: Text('Months')),
// //                         ],
// //                         onChanged: (value) => setState(() => _durationUnit = value!),
// //                         decoration: const InputDecoration(border: OutlineInputBorder()),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 30),
// //               ],
// //
// //               // Enhanced Loan Summary Card
// //               Card(
// //                 elevation: 2,
// //                 color: Colors.indigo.shade50,
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(16.0),
// //                   child: Column(
// //                     children: [
// //                       _summaryRow("Total Repayable:", "GHS ${totalRepayable.toStringAsFixed(2)}"),
// //                       if (isSoftLoan) ...[
// //                         const Divider(height: 20),
// //                         _summaryRow(installmentLabel, "GHS ${installmentAmount.toStringAsFixed(2)}"),
// //                         const Divider(height: 20),
// //                         _summaryRow("Loan End Date:", loanEndDate),
// //                       ]
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton.extended(
// //         onPressed: (_customerLoans.isEmpty && isRepayment) ? null : _saveTransaction,
// //         icon: const Icon(Icons.save),
// //         label: const Text("Save Transaction"),
// //       ),
// //     );
// //   }
// //
// //   // Helper for summary rows
// //   Widget _summaryRow(String label, String value) {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
// //         Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
// //       ],
// //     );
// //   }
// // }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/db/soft_loan_dao.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/installment.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/soft_loan_details.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

enum DurationUnit { days, weeks, months }

class AddTransactionPage extends StatefulWidget {
  final Customer customer;
  final TransactionType? preselectedType;
  final String? preselectedLoanKind;

  const AddTransactionPage({
    super.key,
    required this.customer,
    this.preselectedType,
    this.preselectedLoanKind,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TransactionType _type;
  late String _loanKind;
  final _amountCtl = TextEditingController();
  final _durationCtl = TextEditingController(text: '3');
  double _interestPercent = 5.0;
  DurationUnit _durationUnit = DurationUnit.months;

  LoanRecord? _selectedLoan;
  List<LoanRecord> _customerLoans = [];
  double _outstandingBalance = 0.0;
  Installment? _selectedInstallment;

  @override
  void initState() {
    super.initState();
    _type = widget.preselectedType ?? TransactionType.loan;
    _loanKind = widget.preselectedLoanKind ?? 'Daily Loan';

    if (_loanKind.toLowerCase().contains("daily")) {
      _loanKind = "daily";
      _interestPercent = 5.0;
    } else if (_loanKind.toLowerCase().contains("soft")) {
      _loanKind = "soft";
      _interestPercent = 10.0;
    } else {
      _loanKind = "daily";
    }

    if (_type == TransactionType.repayment) {
      _loadCustomerLoans();
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _durationCtl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerLoans() async {
    final appState = Provider.of<AppState>(context, listen: false);
    // Use await to get the Future<List<LoanRecord>>
    final loans = await appState.getCustomerLoans(widget.customer.id);
    double totalBalance = loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);

    setState(() {
      _customerLoans = loans;
      _outstandingBalance = totalBalance;
      if (_customerLoans.isNotEmpty && _selectedLoan == null) {
        _selectLoan(_customerLoans.first);
      }
    });
  }

  void _selectLoan(LoanRecord loan) {
    setState(() {
      _selectedLoan = loan;
      _selectedInstallment = null; // Clear selected installment
      _amountCtl.clear(); // Clear amount field
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount.")));
      return;
    }

    if (_type == TransactionType.repayment) {
      if (_selectedLoan == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select which loan to repay.")));
        return;
      }
      if (_selectedLoan!.loanKind == 'soft' && _selectedInstallment != null) {
        if (amount > _selectedInstallment!.amount) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text("Amount cannot exceed the installment of GHS ${_selectedInstallment!.amount.toStringAsFixed(2)}"),
          ));
          return;
        }
      } else if (amount > _selectedLoan!.remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Repayment can't exceed balance of GHS ${_selectedLoan!.remainingAmount.toStringAsFixed(2)}.")));
        return;
      }
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final String transactionId = appState.generateUUID();
    String note = '';
    double finalAmount = amount;
    double interestToSave = 0.0;

    if (_type == TransactionType.loan) {
      final principal = amount;
      final interest = principal * (_interestPercent / 100);
      final totalRepayable = principal + interest;
      finalAmount = totalRepayable;
      interestToSave = _interestPercent;
      if (_loanKind == 'soft') {
        final durationValue = int.tryParse(_durationCtl.text) ?? 1;
        final softLoanDetails = SoftLoanDetails(
          transactionId: transactionId,
          principalAmount: principal,
          interestRate: _interestPercent,
          totalRepayable: totalRepayable,
          installmentAmount: totalRepayable / durationValue,
          loanDuration: '$durationValue ${_durationUnit.name}',
          loanEndDate: _calculateEndDate(durationValue, _durationUnit),
        );
        await SoftLoanDao().insertSoftLoanDetails(softLoanDetails);
        note = 'Soft Loan - details in soft_loans table';
      }
    } else { // Repayment logic
      note = 'Repayment for loan: ${_selectedLoan!.id}';
    }

    await appState.addTransaction(
      id: transactionId,
      customerId: widget.customer.id,
      type: _type,
      loanKind: _type == TransactionType.repayment ? _selectedLoan!.loanKind : _loanKind,
      amount: finalAmount,
      interestPercent: interestToSave,
      date: DateTime.now().toIso8601String(),
      note: note,
    );
    if (mounted) Navigator.pop(context);
  }

  String _calculateEndDate(int value, DurationUnit unit) {
    Duration duration;
    switch (unit) {
      case DurationUnit.days:
        duration = Duration(days: value);
        break;
      case DurationUnit.weeks:
        duration = Duration(days: value * 7);
        break;
      case DurationUnit.months:
        duration = Duration(days: value * 30);
        break;
    }
    return DateFormat('dd MMM, yyyy').format(DateTime.now().add(duration));
  }

  @override
  Widget build(BuildContext context) {
    final isSoftLoan = _type == TransactionType.loan && _loanKind == "soft";
    final isRepayment = _type == TransactionType.repayment;
    final title = isRepayment ? "Record Repayment" : isSoftLoan ? "Add Soft Loan" : "Add Daily Loan";
    final amount = double.tryParse(_amountCtl.text) ?? 0.0;
    final interest = (_type == TransactionType.loan) ? (amount * _interestPercent / 100) : 0.0;
    final totalRepayable = amount + interest;
    final durationValue = int.tryParse(_durationCtl.text) ?? 1;
    String installmentLabel = 'Installment:';
    double installmentAmount = 0;
    String loanEndDate = '';

    if (isSoftLoan && durationValue > 0) {
      installmentAmount = totalRepayable / durationValue;
      loanEndDate = _calculateEndDate(durationValue, _durationUnit);
      switch (_durationUnit) {
        case DurationUnit.days:
          installmentLabel = 'Daily Payment:';
          break;
        case DurationUnit.weeks:
          installmentLabel = 'Weekly Payment:';
          break;
        case DurationUnit.months:
          installmentLabel = 'Monthly Payment:';
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRepayment) ...[
              // --- REPAYMENT UI SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Text("Total Outstanding Balance", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("GHS ${_outstandingBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Text("Select Loan to Repay:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _customerLoans.isEmpty ? null : () => _showLoanSelection(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: _customerLoans.isEmpty ? Colors.grey.shade200 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedLoan != null ? _formatLoanDisplay(_selectedLoan!) : "Select a loan",
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedLoan == null ? Colors.grey.shade600 : Colors.black,
                            fontWeight: _selectedLoan == null ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_customerLoans.isNotEmpty) Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedLoan != null && _selectedLoan!.loanKind == 'soft')
                _buildInstallmentSection(),
              const SizedBox(height: 30),
              const Text("Repayment Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                readOnly: _selectedLoan?.loanKind == 'soft' && _selectedInstallment != null,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  border: const OutlineInputBorder(),
                  filled: _selectedLoan?.loanKind == 'soft' && _selectedInstallment != null,
                  fillColor: Colors.grey.shade200,
                ),
              ),
            ],
            if (!isRepayment) ...[
              // --- LOAN CREATION UI SECTION ---
              const Text("Loan Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Enter loan amount", border: OutlineInputBorder(), prefixText: 'GHS '),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 30),
              Text("Interest Rate: ${_interestPercent.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Slider(
                value: _interestPercent,
                min: 0,
                max: 20.0,
                divisions: 200,
                label: "${_interestPercent.toStringAsFixed(1)}%",
                onChanged: (value) => setState(() => _interestPercent = value),
              ),
              const SizedBox(height: 20),
              if (isSoftLoan) ...[
                const Text("Loan Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _durationCtl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<DurationUnit>(
                        value: _durationUnit,
                        items: const [
                          DropdownMenuItem(value: DurationUnit.days, child: Text('Days')),
                          DropdownMenuItem(value: DurationUnit.weeks, child: Text('Weeks')),
                          DropdownMenuItem(value: DurationUnit.months, child: Text('Months')),
                        ],
                        onChanged: (value) => setState(() => _durationUnit = value!),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
              Card(
                elevation: 2,
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _summaryRow("Total Repayable:", "GHS ${totalRepayable.toStringAsFixed(2)}"),
                      if (isSoftLoan) ...[
                        const Divider(height: 20),
                        _summaryRow(installmentLabel, "GHS ${installmentAmount.toStringAsFixed(2)}"),
                        const Divider(height: 20),
                        _summaryRow("Loan End Date:", loanEndDate),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_customerLoans.isEmpty && isRepayment) ? null : _saveTransaction,
        icon: const Icon(Icons.save),
        label: const Text("Save Transaction"),
      ),
    );
  }

  Widget _buildInstallmentSection() {
    if (_selectedLoan == null || _selectedLoan!.installments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Installment to Pay:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._selectedLoan!.installments.map((installment) {
          if (installment.status == "Paid") return const SizedBox.shrink();
          bool isSelected = _selectedInstallment?.dueDate == installment.dueDate;
          return Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.indigo : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              title: Text("GHS ${installment.amount.toStringAsFixed(2)}"),
              subtitle: Text("Due on: ${DateFormat('dd MMM, yyyy').format(installment.dueDate)}"),
              trailing: Text(
                installment.status,
                style: TextStyle(
                  color: installment.status == "Overdue" ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedInstallment = installment;
                  _amountCtl.text = installment.amount.toStringAsFixed(2);
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showLoanSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Select Loan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: _customerLoans.isEmpty
                    ? const Center(child: Text("No active loans found"))
                    : ListView.builder(
                  itemCount: _customerLoans.length,
                  itemBuilder: (context, index) {
                    final loan = _customerLoans[index];
                    return ListTile(
                      title: Text(_formatLoanDisplay(loan)),
                      onTap: () {
                        _selectLoan(loan);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLoanDisplay(LoanRecord loan) {
    final currencySymbol = 'GHS';
    final loanBalance = loan.remainingAmount;
    final loanDate = DateTime.tryParse(loan.date);
    final formattedDate = loanDate != null ? DateFormat('dd/MM/yyyy').format(loanDate) : "Unknown Date";
    final status = loan.isOverdue ? ' (Overdue)' : '';
    return '${loan.loanKind.toUpperCase()}: $currencySymbol${loanBalance.toStringAsFixed(2)} - Due: $formattedDate$status';
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }
}
