import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/installment.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:provider/provider.dart';
import '../core/service_locator.dart';
import '../services/daily_loans_api_service.dart';
import '../services/repayments_api_service.dart';
import '../services/soft_loans_api_service.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';

// Enum for clarity in duration units
enum DurationUnit { days, weeks, months }

class AddTransactionPage extends StatefulWidget {
  final Customer customer;
  final TransactionType? preselectedType;
  final String? preselectedLoanKind;
  final bool enableCustomDateTime;
  final DateTime? initialDateTime;

  const AddTransactionPage({
    super.key,
    required this.customer,
    this.preselectedType,
    this.preselectedLoanKind,
    this.enableCustomDateTime = false,
    this.initialDateTime,
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
  DailyLoansApiService get _dailyLoansApiService => ServiceLocator.dailyLoansApi;
  SoftLoansApiService get _softLoansApiService => ServiceLocator.softLoansApi;
  RepaymentsApiService get _repaymentsApiService => ServiceLocator.repaymentsApi;
  bool _isSavingTransaction = false;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime ?? DateTime.now();
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
            date: (loan['loanStartDate'] ?? DateTime.now().toIso8601String())
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unable to load loans: $e")));
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
    if (_isSavingTransaction) return;
    final amount = double.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    if (_type == TransactionType.repayment) {
      if (_selectedLoan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select which loan to repay.")),
        );
        return;
      }
      if (_selectedLoan!.loanKind == 'soft' && _selectedInstallment != null) {
        if (amount > _selectedInstallment!.amount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Amount cannot exceed the installment of ${AmountFormatter.compactCurrency(_selectedInstallment!.amount)}",
              ),
            ),
          );
          return;
        }
      } else if (amount > _selectedLoan!.remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Repayment can't exceed balance of ${AmountFormatter.compactCurrency(_selectedLoan!.remainingAmount)}.",
            ),
          ),
        );
        return;
      }
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final transactionDate = widget.enableCustomDateTime
        ? _selectedDateTime
        : DateTime.now();

    if (_type == TransactionType.repayment) {
      final selected = _selectedLoan!;
      final installmentNumber = _selectedInstallment == null
          ? 0
          : (selected.installments.indexWhere(
                  (i) => i.dueDate == _selectedInstallment!.dueDate,
                ) +
                1);
      try {
        setState(() => _isSavingTransaction = true);
        await _repaymentsApiService.createRepayment(
          customerId: widget.customer.id,
          loanType: _apiLoanType(selected.loanKind),
          loanId: selected.id,
          amountPaid: amount,
          paymentDateIso: transactionDate.toIso8601String(),
          installmentNumber: installmentNumber < 0 ? 0 : installmentNumber,
          notes: _selectedInstallment == null
              ? 'Repayment for loan ${selected.id}'
              : 'Installment repayment for loan ${selected.id}',
        );

        await appState.loadCustomersFromApi();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await appState.refreshNotificationsInbox();
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
          setState(() => _isSavingTransaction = false);
        }
      }
      return;
    }

    if (_type == TransactionType.loan && _loanKind == 'daily') {
      final transactionId = appState.generateUUID();
      final interestRateDecimal = _interestPercent / 100;
      final interestAmount = amount * interestRateDecimal;
      final totalRepayableAmount = amount + interestAmount;

      try {
        setState(() => _isSavingTransaction = true);
        await _dailyLoansApiService.createDailyLoan(
          id: transactionId,
          customerId: widget.customer.id,
          principalAmount: amount,
          interestRateDecimal: interestRateDecimal,
          interestAmount: interestAmount,
          totalRepayableAmount: totalRepayableAmount,
          loanDateIso: transactionDate.toIso8601String(),
          dueDateIso: transactionDate.add(const Duration(days: 1)).toIso8601String(),
          status: 'Active',
          notes: '',
        );

        await appState.loadCustomersFromApi();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await appState.refreshNotificationsInbox();
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
      } finally {
        if (mounted) setState(() => _isSavingTransaction = false);
      }
      return;
    }

    if (_type == TransactionType.loan && _loanKind == 'soft') {
      final durationValue = int.tryParse(_durationCtl.text) ?? 1;
      final safeDuration = durationValue <= 0 ? 1 : durationValue;
      final interestRateDecimal = _interestPercent / 100;

      try {
        setState(() => _isSavingTransaction = true);
        await _softLoansApiService.createSoftLoan(
          customerId: widget.customer.id,
          principalAmount: amount,
          interestRateDecimal: interestRateDecimal,
          durationValue: safeDuration,
          durationUnit: _durationUnitLabel(_durationUnit),
          loanStartDateIso: transactionDate.toIso8601String(),
          notes: '',
        );

        await appState.loadCustomersFromApi();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await appState.refreshNotificationsInbox();
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
      } finally {
        if (mounted) setState(() => _isSavingTransaction = false);
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
    } else {
      // Repayment logic
      note = 'Repayment for loan: ${_selectedLoan!.id}';
    }

    await appState.addTransaction(
      id: transactionId,
      customerId: widget.customer.id,
      type: _type,
      loanKind: _type == TransactionType.repayment
          ? _selectedLoan!.loanKind
          : _loanKind,
      amount: finalAmount,
      interestPercent: interestToSave,
      date: transactionDate.toIso8601String(),
      note: note,
    );
    if (mounted) Navigator.pop(context);
  }

  String _calculateEndDate(int value, DurationUnit unit, DateTime baseDate) {
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
    return DateFormat('dd MMM, yyyy').format(baseDate.add(duration));
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
    final title = isRepayment
        ? "Record Repayment"
        : isSoftLoan
        ? "Add Soft Loan"
        : "Add Daily Loan";

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
      final baseDate = widget.enableCustomDateTime
          ? _selectedDateTime
          : DateTime.now();
      loanEndDate = _calculateEndDate(durationValue, _durationUnit, baseDate);
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
      appBar: AppBar(
        title: Text(title),
        backgroundColor: (isSoftLoan || (!isRepayment && !isSoftLoan))
            ? const Color(0xFFD7A9A4)
            : Theme.of(context).appBarTheme.backgroundColor,
      ),
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
                    const Text(
                      "Total Outstanding Balance",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AmountFormatter.compactCurrency(_outstandingBalance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                "Select Loan to Repay:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _customerLoans.isEmpty
                    ? null
                    : () => _showLoanSelection(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: _customerLoans.isEmpty
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
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
                              : "Select a loan",
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedLoan == null
                                ? Colors.grey.shade600
                                : Colors.black,
                            fontWeight: _selectedLoan == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_customerLoans.isNotEmpty)
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedLoan != null && _selectedLoan!.loanKind == 'soft')
                _buildInstallmentSection(),
              const SizedBox(height: 30),
              const Text(
                "Repayment Amount",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                readOnly:
                    _selectedLoan?.loanKind == 'soft' &&
                    _selectedInstallment != null,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  border: const OutlineInputBorder(),
                  filled:
                      _selectedLoan?.loanKind == 'soft' &&
                      _selectedInstallment != null,
                  fillColor: Colors.grey.shade200,
                ),
              ),
            ],

            // --- SECTION 2: LOAN UI (DAILY & SOFT) ---
            if (!isRepayment && isSoftLoan) ...[
              ..._buildSoftLoanUi(
                context: context,
                totalRepayable: totalRepayable,
                installmentLabel: installmentLabel,
                installmentAmount: installmentAmount,
                loanEndDate: loanEndDate,
              ),
            ],
            if (!isRepayment && !isSoftLoan) ...[
              ..._buildDailyLoanUi(
                context: context,
                totalRepayable: totalRepayable,
                totalInterest: totalInterest,
              ),
            ],
            if (widget.enableCustomDateTime) ...[
              const SizedBox(height: 18),
              _buildCustomDateTimePicker(isRepayment: isRepayment),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            (_customerLoans.isEmpty && isRepayment) || _isSavingTransaction
            ? null
            : _saveTransaction,
        icon: _isSavingTransaction
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSavingTransaction ? "Saving..." : "Save Transaction"),
      ),
    );
  }

  List<Widget> _buildSoftLoanUi({
    required BuildContext context,
    required double totalRepayable,
    required String installmentLabel,
    required double installmentAmount,
    required String loanEndDate,
  }) {
    final surface = const Color(0xFFF9F3F3);
    final stroke = const Color(0xFFE7DADA);
    final accent = const Color(0xFFD7A9A4);
    final valueColor = const Color(0xFF5A2A6A);
    return [
      const Text(
        "Loan Amount",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: surface,
              child: Icon(Icons.account_balance_wallet_outlined, color: accent),
            ),
            const SizedBox(width: 10),
            const Text("GHS", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter loan amount",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        "Interest Rate",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${_interestPercent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                inactiveTrackColor: const Color(0xFFF1DFDF),
                thumbColor: accent,
              ),
              child: Slider(
                value: _interestPercent,
                min: 5,
                max: 20,
                divisions: 150,
                onChanged: (value) => setState(() => _interestPercent = value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("5%"),
                  Text("per month"),
                  Text("20%"),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        "Loan Duration",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stroke),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: surface,
                    child: Icon(Icons.calendar_month_outlined, size: 16, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stroke),
              ),
              child: DropdownButtonFormField<DurationUnit>(
                initialValue: _durationUnit,
                decoration: const InputDecoration(border: InputBorder.none),
                items: const [
                  DropdownMenuItem(value: DurationUnit.days, child: Text('Days')),
                  DropdownMenuItem(value: DurationUnit.weeks, child: Text('Weeks')),
                  DropdownMenuItem(value: DurationUnit.months, child: Text('Months')),
                ],
                onChanged: (value) => setState(() => _durationUnit = value!),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            _softSummaryRow(
              icon: Icons.receipt_long_outlined,
              label: "Total Repayable",
              value: AmountFormatter.compactCurrency(totalRepayable),
              valueColor: valueColor,
            ),
            const Divider(height: 18),
            _softSummaryRow(
              icon: Icons.account_balance_wallet_outlined,
              label: installmentLabel.replaceAll(':', ''),
              value: AmountFormatter.compactCurrency(installmentAmount),
              valueColor: valueColor,
            ),
            const Divider(height: 18),
            _softSummaryRow(
              icon: Icons.event_note_outlined,
              label: "Loan End Date",
              value: loanEndDate,
              valueColor: valueColor,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stroke),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFC59796)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "The amounts above are estimates.\nActual values may vary.",
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildDailyLoanUi({
    required BuildContext context,
    required double totalRepayable,
    required double totalInterest,
  }) {
    final surface = const Color(0xFFF9F3F3);
    final stroke = const Color(0xFFE7DADA);
    final accent = const Color(0xFFD7A9A4);
    final valueColor = const Color(0xFF5A2A6A);
    return [
      const Text(
        "Loan Amount",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: surface,
              child: Icon(Icons.account_balance_wallet_outlined, color: accent),
            ),
            const SizedBox(width: 10),
            const Text("GHS", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter loan amount",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        "Enter the amount to be loaned to the customer",
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 20),
      const Text(
        "Interest Rate",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${_interestPercent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                inactiveTrackColor: const Color(0xFFF1DFDF),
                thumbColor: accent,
              ),
              child: Slider(
                value: _interestPercent,
                min: 1,
                max: 20,
                divisions: 190,
                onChanged: (value) => setState(() => _interestPercent = value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("1%"),
                  Text("per month"),
                  Text("20%"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFC59796), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Interest will be charged on the reducing balance daily.",
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        "Loan Summary",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            _softSummaryRow(
              icon: Icons.receipt_long_outlined,
              label: "Total Repayable",
              value: AmountFormatter.compactCurrency(totalRepayable),
              valueColor: valueColor,
            ),
            const Divider(height: 18),
            _softSummaryRow(
              icon: Icons.percent,
              label: "Daily Interest (${_interestPercent.toStringAsFixed(1)}%)",
              value: AmountFormatter.compactCurrency(totalInterest),
              valueColor: valueColor,
            ),
            const Divider(height: 18),
            _softSummaryRow(
              icon: Icons.calendar_month_outlined,
              label: "Repayment Period",
              value: "Daily",
              valueColor: valueColor,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stroke),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFC59796)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "The total repayable includes principal and daily interest.",
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _softSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFF7ECEC),
          child: Icon(icon, size: 16, color: const Color(0xFFD7A9A4)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateTimePicker({required bool isRepayment}) {
    final label = isRepayment
        ? 'Payment Date & Time'
        : 'Transaction Date & Time';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickTransactionDateTime,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, size: 20),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd MMM, yyyy - hh:mm a').format(_selectedDateTime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTransactionDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Widget _buildInstallmentSection() {
    if (_selectedLoan == null || _selectedLoan!.installments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Installment to Pay:",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._selectedLoan!.installments.map((installment) {
          if (installment.status == "Paid") return const SizedBox.shrink();
          bool isSelected =
              _selectedInstallment?.dueDate == installment.dueDate;
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
              title: Text(AmountFormatter.compactCurrency(installment.amount)),
              subtitle: Text(
                "Due on: ${DateFormat('dd MMM, yyyy').format(installment.dueDate)}",
              ),
              trailing: Text(
                installment.status,
                style: TextStyle(
                  color: installment.status == "Overdue"
                      ? Colors.red
                      : Colors.green,
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
        }),
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
              const Text(
                "Select Loan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                            color: selected
                                ? Colors.indigo.shade50
                                : Colors.white,
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
                                  isSoft
                                      ? Icons.handshake
                                      : Icons.calendar_today,
                                  color: isSoft
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                '${loan.loanKind.toUpperCase()} LOAN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Balance: ${AmountFormatter.compactCurrency(loan.remainingAmount)}\nDate: $formattedDate',
                              ),
                              trailing: Text(
                                AmountFormatter.compactCurrency(
                                  loan.remainingAmount,
                                ),
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
    final loanBalance = loan.remainingAmount;
    final loanDate = DateTime.tryParse(loan.date);
    final formattedDate = loanDate != null
        ? DateFormat('dd/MM/yyyy').format(loanDate)
        : "Unknown Date";
    final status = loan.isOverdue ? ' (Overdue)' : '';
    return '${loan.loanKind.toUpperCase()}: ${AmountFormatter.compactCurrency(loanBalance)} - Due: $formattedDate$status';
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

}
