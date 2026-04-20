import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/installment.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:lend_ledger/services/daily_loans_api_service.dart';
import 'package:lend_ledger/services/repayments_api_service.dart';
import 'package:lend_ledger/services/soft_loans_api_service.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

// Enum for clarity in duration units
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

  // State for flexible duration
  DurationUnit _durationUnit = DurationUnit.months;

  // State for repayment fields
  LoanRecord? _selectedLoan;
  List<LoanRecord> _customerLoans = [];
  double _outstandingBalance = 0.0;
  Installment? _selectedInstallment;
  final DailyLoansApiService _dailyLoansApiService = DailyLoansApiService();
  final SoftLoansApiService _softLoansApiService = SoftLoansApiService();
  final RepaymentsApiService _repaymentsApiService = RepaymentsApiService();
  bool _isPostingRepayment = false;

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
    try {
      final customerDetails = await appState.fetchCustomerDetailsFromApi(
        widget.customer.id,
      );
      final repayments = await _repaymentsApiService.fetchRepaymentsByCustomer(
        widget.customer.id,
      );
      final Map<String, double> paidByLoanId = {};

      for (final repayment in repayments) {
        final loanId = (repayment['loanId'] ?? '').toString();
        if (loanId.isEmpty) continue;
        final amountPaid = _num(repayment['amountPaid']);
        paidByLoanId[loanId] = (paidByLoanId[loanId] ?? 0.0) + amountPaid;
      }

      final List<LoanRecord> loans = [];
      for (final loan in customerDetails.dailyLoans) {
        final loanId = (loan['id'] ?? '').toString();
        if (loanId.isEmpty) continue;
        final total = _num(loan['totalRepayableAmount']);
        final remaining = total - (paidByLoanId[loanId] ?? 0.0);
        if (remaining <= 0.01) continue;

        loans.add(
          LoanRecord(
            id: loanId,
            customerId: widget.customer.id,
            type: TransactionType.loan,
            loanKind: 'daily',
            amount: total,
            interestPercent: _num(loan['interestRate']) * 100,
            date: (loan['loanDate'] ?? DateTime.now().toIso8601String())
                .toString(),
            note: (loan['notes'] ?? '').toString(),
            remainingAmount: remaining,
          ),
        );
      }

      for (final loan in customerDetails.softLoans) {
        final loanId = (loan['id'] ?? '').toString();
        if (loanId.isEmpty) continue;
        final total = _num(loan['totalRepayableAmount']);
        final remaining = total - (paidByLoanId[loanId] ?? 0.0);
        if (remaining <= 0.01) continue;

        loans.add(
          LoanRecord(
            id: loanId,
            customerId: widget.customer.id,
            type: TransactionType.loan,
            loanKind: 'soft',
            amount: total,
            interestPercent: _num(loan['interestRate']) * 100,
            date:
                (loan['loanStartDate'] ?? DateTime.now().toIso8601String())
                    .toString(),
            note: (loan['notes'] ?? '').toString(),
            remainingAmount: remaining,
          ),
        );
      }

      loans.sort((a, b) => b.date.compareTo(a.date));
      final totalBalance = loans.fold<double>(
        0.0,
        (sum, loan) => sum + loan.remainingAmount,
      );

      if (!mounted) return;
      setState(() {
        _customerLoans = loans;
        _outstandingBalance = totalBalance;
        if (_customerLoans.isNotEmpty && _selectedLoan == null) {
          _selectLoan(_customerLoans.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load loans: $e")),
      );
    }
  }

  void _selectLoan(LoanRecord loan) {
    setState(() {
      _selectedLoan = loan;
      _selectedInstallment = null; // Clear selected installment
      _amountCtl.clear(); // Clear amount field
    });
  }

  // --- SAVE TRANSACTION ---
  Future<void> _saveTransaction() async {
    if (_isPostingRepayment) return;
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

    if (_type == TransactionType.repayment) {
      final now = DateTime.now();
      final selected = _selectedLoan!;
      final installmentNumber = _selectedInstallment == null
          ? 0
          : (selected.installments.indexWhere(
                    (i) => i.dueDate == _selectedInstallment!.dueDate,
                  ) +
                  1);
      try {
        setState(() => _isPostingRepayment = true);
        await _repaymentsApiService.createRepayment(
          customerId: widget.customer.id,
          loanType: _apiLoanType(selected.loanKind),
          loanId: selected.id,
          amountPaid: amount,
          paymentDateIso: now.toIso8601String(),
          installmentNumber: installmentNumber < 0 ? 0 : installmentNumber,
          notes: _selectedInstallment == null
              ? 'Repayment for loan ${selected.id}'
              : 'Installment repayment for loan ${selected.id}',
        );

        await appState.loadCustomersFromApi();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Repayment saved successfully.")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save repayment: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isPostingRepayment = false);
        }
      }
      return;
    }

    if (_type == TransactionType.loan && _loanKind == 'daily') {
      final transactionId = appState.generateUUID();
      final now = DateTime.now();
      final interestRateDecimal = _interestPercent / 100;
      final interestAmount = amount * interestRateDecimal;
      final totalRepayableAmount = amount + interestAmount;

      try {
        await _dailyLoansApiService.createDailyLoan(
          id: transactionId,
          customerId: widget.customer.id,
          principalAmount: amount,
          interestRateDecimal: interestRateDecimal,
          interestAmount: interestAmount,
          totalRepayableAmount: totalRepayableAmount,
          loanDateIso: now.toIso8601String(),
          dueDateIso: now.add(const Duration(days: 1)).toIso8601String(),
          status: 'Active',
          notes: '',
        );

        await appState.loadCustomersFromApi();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily loan created successfully.")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create daily loan: $e")),
          );
        }
      }
      return;
    }

    if (_type == TransactionType.loan && _loanKind == 'soft') {
      final now = DateTime.now();
      final durationValue = int.tryParse(_durationCtl.text) ?? 1;
      final safeDuration = durationValue <= 0 ? 1 : durationValue;
      final interestRateDecimal = _interestPercent / 100;

      try {
        await _softLoansApiService.createSoftLoan(
          customerId: widget.customer.id,
          principalAmount: amount,
          interestRateDecimal: interestRateDecimal,
          durationValue: safeDuration,
          durationUnit: _durationUnitLabel(_durationUnit),
          loanStartDateIso: now.toIso8601String(),
          notes: '',
        );

        await appState.loadCustomersFromApi();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Soft loan created successfully.")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create soft loan: $e")),
          );
        }
      }
      return;
    }

    final String transactionId = appState.generateUUID();
    String note = '';
    double finalAmount = amount;
    double interestToSave = 0.0;

    if (_type == TransactionType.loan) {
      final principal = amount;
      final totalInterest = principal * (_interestPercent / 100);

      final totalRepayable = principal + totalInterest;
      finalAmount = totalRepayable;
      interestToSave = _interestPercent;
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
        duration = Duration(days: value * 30); // Approximation
        break;
    }
    return DateFormat('dd MMM, yyyy').format(DateTime.now().add(duration));
  }

  String _durationUnitLabel(DurationUnit unit) {
    switch (unit) {
      case DurationUnit.days:
        return 'Days';
      case DurationUnit.weeks:
        return 'Weeks';
      case DurationUnit.months:
        return 'Months';
    }
  }

  String _apiLoanType(String loanKind) {
    final normalized = loanKind.toLowerCase();
    if (normalized.contains('soft')) return 'Soft';
    return 'Daily';
  }

  @override
  Widget build(BuildContext context) {
    final isSoftLoan = _type == TransactionType.loan && _loanKind == "soft";
    final isRepayment = _type == TransactionType.repayment;
    final title = isRepayment ? "Record Repayment" : isSoftLoan ? "Add Soft Loan" : "Add Daily Loan";

    // --- Calculations for UI display ---
    final amount = double.tryParse(_amountCtl.text) ?? 0.0;
    final durationValue = int.tryParse(_durationCtl.text) ?? 1;
    double totalInterest;

    if (isSoftLoan) {
      totalInterest = amount * (_interestPercent / 100) * durationValue;
    } else {
      totalInterest = amount * (_interestPercent / 100);
    }

    final totalRepayable = amount + totalInterest;
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
            // --- SECTION 1: REPAYMENT UI (NOW COMPLETE) ---
            if (isRepayment) ...[
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

            // --- SECTION 2: LOAN UI (DAILY & SOFT) ---
            if (!isRepayment) ...[
              const Text("Loan Amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Enter loan amount", border: OutlineInputBorder(), prefixText: 'GHS '),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 30),
              Text("Interest Rate: ${_interestPercent.toStringAsFixed(1)}% per ${_durationUnit.name.substring(0, _durationUnit.name.length - 1)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        onPressed: (_customerLoans.isEmpty && isRepayment) || _isPostingRepayment
            ? null
            : _saveTransaction,
        icon: _isPostingRepayment
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isPostingRepayment ? "Posting..." : "Save Transaction"),
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
                    final selected = _selectedLoan?.id == loan.id;
                    final isSoft = loan.loanKind.toLowerCase() == 'soft';
                    final loanDate = DateTime.tryParse(loan.date);
                    final formattedDate = loanDate != null
                        ? DateFormat('dd MMM yyyy').format(loanDate)
                        : "Unknown date";

                    return Card(
                      elevation: selected ? 4 : 1,
                      color: selected ? Colors.indigo.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected
                              ? Colors.indigo
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSoft
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isSoft ? Icons.handshake : Icons.calendar_today,
                            color: isSoft
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '${loan.loanKind.toUpperCase()} LOAN',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Balance: GHS ${loan.remainingAmount.toStringAsFixed(2)}\nDate: $formattedDate',
                        ),
                        trailing: Text(
                          'GHS ${loan.remainingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          _selectLoan(loan);
                          Navigator.pop(context);
                        },
                      ),
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

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
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
