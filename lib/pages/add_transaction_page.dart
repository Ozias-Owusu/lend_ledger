
import 'package:flutter/material.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

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
  final _installmentsCtl = TextEditingController(text: "1");
  double _interestPercent = 5.0;

  // For soft loan specific fields
  String _repaymentFrequency = "Weekly";
  DateTime _repaymentStartDate = DateTime.now().add(const Duration(days: 1));

  // For repayment specific fields
  LoanRecord? _selectedLoan;
  List<LoanRecord> _customerLoans = [];
  double _outstandingBalance = 0.0;

  @override
  void initState() {
    super.initState();

    // Load presets coming from FAB
    _type = widget.preselectedType ?? TransactionType.loan;
    _loanKind = widget.preselectedLoanKind ?? 'Daily Loan';

    // Apply internal map
    if (_loanKind.toLowerCase().contains("daily")) {
      _loanKind = "daily";
      _interestPercent;
    } else if (_loanKind.toLowerCase().contains("soft")) {
      _loanKind = "soft";
      _interestPercent = 0.0;
    } else {
      _loanKind = "daily"; // fallback
    }

    // Load customer loans and outstanding balance if it's a repayment
    if (_type == TransactionType.repayment) {
      _loadCustomerLoans();
    }
  }

  Future<void> _loadCustomerLoans() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Get active loans for this customer
    final loans = appState.getCustomerLoans(widget.customer.id);

    // Calculate outstanding balance (sum of all loan balances)
    double totalBalance = 0.0;
    for (var loan in loans) {
      final loanBalance = loan.remainingAmount ?? loan.amount;
      totalBalance += loanBalance;
    }

    setState(() {
      _customerLoans = loans;
      _outstandingBalance = totalBalance;

      // Auto-select the first loan if available
      if (_customerLoans.isNotEmpty && _selectedLoan == null) {
        _selectedLoan = _customerLoans.first;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _repaymentStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _repaymentStartDate) {
      setState(() {
        _repaymentStartDate = picked;
      });
    }
  }

  void _showFrequencyDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Select Repayment Frequency",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("Weekly",
                    style: TextStyle(fontSize: 18)),
                leading: Radio<String>(
                  value: "Weekly",
                  groupValue: _repaymentFrequency,
                  onChanged: (value) {
                    setState(() {
                      _repaymentFrequency = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _repaymentFrequency = "Weekly";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Monthly",
                    style: TextStyle(fontSize: 18)),
                leading: Radio<String>(
                  value: "Monthly",
                  groupValue: _repaymentFrequency,
                  onChanged: (value) {
                    setState(() {
                      _repaymentFrequency = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _repaymentFrequency = "Monthly";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
              const Text(
                "Select Loan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _customerLoans.isEmpty
                    ? const Center(
                  child: Text("No active loans found"),
                )
                    : ListView.builder(
                  itemCount: _customerLoans.length,
                  itemBuilder: (context, index) {
                    final loan = _customerLoans[index];
                    final loanBalance = loan.remainingAmount ?? loan.amount;
                    final isSelected = _selectedLoan?.id == loan.id;

                    return ListTile(
                      title: Text(
                        _formatLoanDisplay(loan),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Radio<LoanRecord>(
                        value: loan,
                        groupValue: _selectedLoan,
                        onChanged: (value) {
                          setState(() {
                            _selectedLoan = value;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLoan = loan;
                        });
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
    final loanBalance = loan.amount;

    final loanDate = DateTime.tryParse(loan.date);
    final formattedDate = loanDate != null
        ? "${loanDate.day}/${loanDate.month}/${loanDate.year}"
        : "Unknown Date";

    final status = loan.isOverdue ? ' (Overdue)' : '';

    return '$currencySymbol${loanBalance.toStringAsFixed(2)} - Due: $formattedDate$status';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    final isDailyLoan = _type == TransactionType.loan && _loanKind == "daily";
    final isSoftLoan = _type == TransactionType.loan && _loanKind == "soft";
    final isRepayment = _type == TransactionType.repayment;

    final title = isRepayment
        ? "Record Repayment"
        : isSoftLoan
        ? "Add Soft Loan"
        : "Add Daily Loan";

    // Compute total
    final amount = double.tryParse(_amountCtl.text) ?? 0.0;
    final interest = isDailyLoan ? (amount * _interestPercent / 100) : 0.0;
    final total = amount + interest;

    // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/add_transaction_page.dart

    // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/add_transaction_page.dart

    Future<void> _saveTransaction() async {
      final amount = double.tryParse(_amountCtl.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount.")),
        );
        return;
      }

      // For repayments, ensure a specific loan has been selected
      if (_type == TransactionType.repayment && _selectedLoan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select which loan to repay.")),
        );
        return;
      }

      // --- *** THE FIX IS HERE *** ---
      // If it's a repayment, validate that the amount isn't more than what's owed on that specific loan.
      if (_type == TransactionType.repayment) {
        final loanBalance = _selectedLoan!.remainingAmount;
        if (amount > loanBalance) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                  "Repayment amount cannot be more than the selected loan's balance of GHS ${loanBalance.toStringAsFixed(2)}."),
            ),
          );
          return; // Stop the function from proceeding
        }
      }
      // --- *** END OF FIX *** ---

      final appState = Provider.of<AppState>(context, listen: false);

      String note = '';
      String loanKind = _loanKind; // "daily" or "soft"
      double finalAmount = amount; // Use a different variable for the final amount

      // If it's a Daily Loan, calculate the total amount to be saved.
      if (_type == TransactionType.loan && _loanKind == "daily") {
        final interest = amount * (_interestPercent / 100);
        finalAmount =
            amount + interest; // This is the total amount the customer owes for this loan
      }

      // For repayments, construct a helpful note
      if (_type == TransactionType.repayment) {
        note = 'Repayment for loan: ${_selectedLoan!.id}';
        loanKind = _selectedLoan!.loanKind;
      }

      await appState.addTransaction(
        customerId: widget.customer.id,
        type: _type,
        loanKind: loanKind,
        amount: finalAmount, // Pass the final amount
        interestPercent:
        (_type == TransactionType.loan && _loanKind == "daily") ? _interestPercent : 0.0,
        date: DateTime.now().toIso8601String(),
        note: note,
      );

      if (mounted) {
        // Go back to the previous page after saving
        Navigator.pop(context);
      }
    }


// Add this method inside the _AddTransactionPageState class
//     Future<void> _saveTransaction() async {
//       final amount = double.tryParse(_amountCtl.text);
//       if (amount == null || amount <= 0) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please enter a valid amount.")),
//         );
//         return;
//       }
//
//       // For repayments, ensure a specific loan has been selected
//       if (_type == TransactionType.repayment && _selectedLoan == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please select which loan to repay.")),
//         );
//         return;
//       }
//
//       final appState = Provider.of<AppState>(context, listen: false);
//
//       String note = '';
//       String loanKind = _loanKind; // "daily" or "soft"
//       double loanAmount = amount;
//
//       // If it's a Daily Loan, calculate the total amount to be saved.
//       if (_type == TransactionType.loan && _loanKind == "daily") {
//         final interest = amount * (_interestPercent / 100);
//         loanAmount = amount + interest; // This is the total amount the customer owes for this loan
//       }
//
//       // For repayments, construct a helpful note and determine the loan kind from the selected loan
//       if (_type == TransactionType.repayment) {
//         note = 'Repayment for loan: ${_selectedLoan!.id}';
//         loanKind = _selectedLoan!.loanKind; // Use the original loan's kind
//       }
//
//       await appState.addTransaction(
//         customerId: widget.customer.id,
//         type: _type,
//         loanKind: loanKind,
//         amount: loanAmount,
//         interestPercent: (_type == TransactionType.loan && _loanKind == "daily") ? _interestPercent : 0.0,
//         date: DateTime.now().toIso8601String(),
//         note: note,
//       );
//
//       if (mounted) {
//         // Go back to the previous page after saving
//         Navigator.pop(context);
//       }
//     }


    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------------------------------
            // REPAYMENT SPECIFIC LAYOUT
            // -------------------------------
            if (isRepayment) ...[
              // Outstanding Balance
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
                    const Text(
                      "Outstanding Balance",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$${_outstandingBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Select Loan
              const Text(
                "Select Loan:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                          _selectedLoan != null
                              ? _formatLoanDisplay(_selectedLoan!)
                              : _customerLoans.isEmpty
                              ? "No active loans"
                              : "Select a loan",
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedLoan == null ? Colors.grey.shade600 : Colors.black,
                            fontWeight: _selectedLoan == null ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_customerLoans.isNotEmpty)
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),

              if (_customerLoans.isEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  "This customer has no active loans to repay.",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 30),

              // Repayment Amount
              const Text(
                "Repayment Amount",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                enabled: _selectedLoan != null,
                decoration: InputDecoration(
                  hintText: _selectedLoan != null
                      ? "Enter repayment amount"
                      : "Select a loan first",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            // -------------------------------
            // LOAN SPECIFIC LAYOUT (Daily/Soft)
            // -------------------------------
            if (!isRepayment) ...[
              // Loan Amount section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Loan Amount",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter loan amount",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Soft Loan Specific Fields
              if (isSoftLoan) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of Installments
                    const Text(
                      "Number of Installments",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _installmentsCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter number of installments",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 25),

                    // Repayment Frequency Card with Dropdown
                    GestureDetector(
                      onTap: () => _showFrequencyDropdown(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Repayment Frequency",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _repaymentFrequency,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Divider
                    const Divider(
                      thickness: 1,
                      height: 20,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 15),

                    // Repayment Start Date
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Repayment Start Date:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_repaymentStartDate.day}/${_repaymentStartDate.month}/${_repaymentStartDate.year}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],

              // Interest slider (Only for Daily Loan)
              if (isDailyLoan)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Interest Rate",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: _interestPercent,
                        min: 0,
                        max: 20,
                        divisions: 20,
                        label: "${_interestPercent.toInt()}%",
                        onChanged: (v) {
                          setState(() => _interestPercent = v);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("0%"),
                          Text("${_interestPercent.toInt()}%"),
                          const Text("20%"),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Total Amount Card (Only for Daily Loan)
              if (!isSoftLoan && !isRepayment)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Total Amount:  ₵${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

              if (isSoftLoan) const SizedBox(height: 20),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )),
                child: Text(
                  isRepayment ? "Record Repayment" : "Save Loan",
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  await _saveTransaction();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}