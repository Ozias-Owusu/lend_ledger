import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';


enum ExportDataType {
  allCustomers,
  allTransactions,
  singleCustomerLedger,
}

// Enum for the file format
enum ExportFormat {
  pdf,
  excel,
  csv,
}

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  ExportDataType _selectedDataType = ExportDataType.allCustomers;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  Customer? _selectedCustomer;
  bool _isExporting = false;

  // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/export_data_page.dart

  Future<void> _startExport() async {
    setState(() => _isExporting = true);

    final appState = Provider.of<AppState>(context, listen: false);
    List<List<dynamic>> dataRows;
    List<String> headers;

    // 1. Prepare data based on user selection
    switch (_selectedDataType) {
      case ExportDataType.allCustomers:
        headers = ['ID', 'Name', 'Phone', 'Ghana Card', 'Date Joined'];
        dataRows = appState.customers
            .map((c) =>
        [c.id, c.name, c.phone, c.ghanaCardNumber, c.dateJoined])
            .toList();
        break;
      case ExportDataType.allTransactions:
        headers = [
          'ID',
          'Customer ID',
          'Type',
          'Amount',
          'Interest %',
          'Date',
          'Note'
        ];
        dataRows = appState.transactions
            .map((t) => [
          t.id,
          t.customerId,
          t.type.name,
          t.amount,
          t.interestPercent,
          t.date,
          t.note
        ])
            .toList();
        break;
      case ExportDataType.singleCustomerLedger:
        if (_selectedCustomer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a customer first.')));
          setState(() => _isExporting = false);
          return;
        }

        // --- *** THE FIX IS HERE *** ---
        headers = ['Date', 'Type', 'Amount', 'Balance'];

        // 1. Manually filter transactions for the selected customer
        final customerTransactions = appState.transactions
            .where((t) => t.customerId == _selectedCustomer!.id)
            .toList();
        // Sort by date to calculate balance correctly
        customerTransactions.sort((a, b) => a.date.compareTo(b.date));

        // 2. Calculate the final balance first
        double finalBalance = 0;
        for (final t in customerTransactions) {
          finalBalance += (t.type == TransactionType.loan ? t.amount : -t.amount);
        }

        // 3. Generate rows with a running balance
        dataRows = [];
        double runningBalance = finalBalance;
        for (final t in customerTransactions.reversed) { // Newest first for display
          final row = [
            t.date,
            t.type.name,
            t.amount,
            runningBalance.toStringAsFixed(2)
          ];
          dataRows.add(row);
          runningBalance -= (t.type == TransactionType.loan ? t.amount : -t.amount);
        }
        // --- *** END OF FIX *** ---
        break;
    }

    // ... (The rest of the function for generating and opening files is fine)

    // 2. Generate file bytes based on format
    Uint8List fileBytes;
    String fileExtension = _selectedFormat.name;

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        fileBytes = await _createPdf(headers, dataRows);
        break;
      case ExportFormat.excel:
        fileBytes = await _createExcel(headers, dataRows);
        fileExtension = 'xlsx'; // excel package creates .xlsx files
        break;
      case ExportFormat.csv:
        fileBytes = await _createCsv(headers, dataRows);
        break;
    }

    // 3. Get path, save file, and open it
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final file = File(path);
      await file.writeAsBytes(fileBytes);

      // 4. Use open_filex to open the file
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to export file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }


  // Future<void> _startExport() async {
  //   setState(() => _isExporting = true);
  //
  //   final appState = Provider.of<AppState>(context, listen: false);
  //   List<List<dynamic>> dataRows;
  //   List<String> headers;
  //
  //   // 1. Prepare data based on user selection
  //   switch (_selectedDataType) {
  //     case ExportDataType.allCustomers:
  //       headers = ['ID', 'Name', 'Phone', 'Ghana Card', 'Date Joined'];
  //       dataRows = appState.customers
  //           .map((c) =>
  //       [c.id, c.name, c.phone, c.ghanaCardNumber, c.dateJoined])
  //           .toList();
  //       break;
  //     case ExportDataType.allTransactions:
  //       headers = [
  //         'ID',
  //         'Customer ID',
  //         'Type',
  //         'Amount',
  //         'Interest %',
  //         'Date',
  //         'Note'
  //       ];
  //       dataRows = appState.transactions
  //           .map((t) => [
  //         t.id,
  //         t.customerId,
  //         t.type.name,
  //         t.amount,
  //         t.interestPercent,
  //         t.date,
  //         t.note
  //       ])
  //           .toList();
  //       break;
  //     case ExportDataType.singleCustomerLedger:
  //       if (_selectedCustomer == null) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Please select a customer first.')));
  //         setState(() => _isExporting = false);
  //         return;
  //       }
  //       headers = ['Date', 'Type', 'Amount', 'Balance'];
  //       final customerTransactions =
  //       appState.transactionsForCustomer(_selectedCustomer!.id);
  //       double balance = appState.computeBalance(_selectedCustomer!.id);
  //       dataRows = customerTransactions.map((t) {
  //         final row = [
  //           t.date,
  //           t.type.name,
  //           t.amount,
  //           balance.toStringAsFixed(2)
  //         ];
  //         balance -= (t.type == TransactionType.loan
  //             ? t.amount + (t.amount * t.interestPercent / 100)
  //             : -t.amount);
  //         return row;
  //       }).toList();
  //       break;
  //   }
  //
  //   // 2. Generate file bytes based on format
  //   Uint8List fileBytes;
  //   String fileExtension = _selectedFormat.name;
  //
  //   switch (_selectedFormat) {
  //     case ExportFormat.pdf:
  //       fileBytes = await _createPdf(headers, dataRows);
  //       break;
  //     case ExportFormat.excel:
  //       fileBytes = await _createExcel(headers, dataRows);
  //       fileExtension = 'xlsx'; // excel package creates .xlsx files
  //       break;
  //     case ExportFormat.csv:
  //       fileBytes = await _createCsv(headers, dataRows);
  //       break;
  //   }
  //
  //   // 3. Get path, save file, and open it
  //   try {
  //     final directory = await getApplicationDocumentsDirectory();
  //     final path =
  //         '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
  //     final file = File(path);
  //     await file.writeAsBytes(fileBytes);
  //
  //     // 4. Use open_filex to open the file
  //     final result = await OpenFilex.open(path);
  //     if (result.type != ResultType.done) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Could not open file: ${result.message}')));
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Failed to export file: $e')));
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isExporting = false);
  //     }
  //   }
  // }

  // *** FIX IS HERE: The return type is Future<Uint8List> ***
  Future<Uint8List> _createPdf(
      List<String> headers, List<List<dynamic>> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> _createCsv(
      List<String> headers, List<List<dynamic>> data) async {
    List<List<dynamic>> csvData = [headers, ...data];
    String csv = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(csv.codeUnits);
  }

  Future<Uint8List> _createExcel(
      List<String> headers, List<List<dynamic>> data) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    // Add data rows
    for (var i = 0; i < data.length; i++) {
      for (var j = 0; j < data[i].length; j++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1)).value = TextCellValue(data[i][j].toString());
      }
    }

    // Save the file
    List<int>? fileBytes = excel.save();
    if (fileBytes == null) return Uint8List(0);
    return Uint8List.fromList(fileBytes);
  }

  String _getExportTypeName() {
    switch (_selectedDataType) {
      case ExportDataType.allCustomers:
        return 'All Customers';
      case ExportDataType.allTransactions:
        return 'All Transactions';
      case ExportDataType.singleCustomerLedger:
        return 'Ledger for ${_selectedCustomer?.name ?? '...'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = Provider.of<AppState>(context, listen: false).customers;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section 1: What to Export? ---
          _buildSectionHeader('1. Select Data to Export'),
          _buildRadioTile<ExportDataType>(
            title: 'All Customers List',
            subtitle: 'A summary list of all your customers.',
            value: ExportDataType.allCustomers,
            groupValue: _selectedDataType,
            onChanged: (value) => setState(() => _selectedDataType = value!),
          ),
          _buildRadioTile<ExportDataType>(
            title: 'All Transactions',
            subtitle: 'A complete list of every loan and repayment.',
            value: ExportDataType.allTransactions,
            groupValue: _selectedDataType,
            onChanged: (value) => setState(() => _selectedDataType = value!),
          ),
          _buildRadioTile<ExportDataType>(
            title: 'Single Customer Ledger',
            subtitle: 'A detailed transaction history for one customer.',
            value: ExportDataType.singleCustomerLedger,
            groupValue: _selectedDataType,
            onChanged: (value) => setState(() => _selectedDataType = value!),
          ),

          // --- Conditional Customer Dropdown ---
          if (_selectedDataType == ExportDataType.singleCustomerLedger)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                hint: const Text('Select a customer'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: customers
                    .map((customer) => DropdownMenuItem(
                  value: customer,
                  child: Text(customer.name),
                ))
                    .toList(),
                onChanged: (customer) =>
                    setState(() => _selectedCustomer = customer),
              ),
            ),

          const SizedBox(height: 24),

          // --- Section 2: Choose Format ---
          _buildSectionHeader('2. Select Export Format'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFormatChip(ExportFormat.pdf, Icons.picture_as_pdf),
              const SizedBox(width: 12),
              _buildFormatChip(ExportFormat.excel, Icons.grid_on),
              const SizedBox(width: 12),
              _buildFormatChip(ExportFormat.csv, Icons.description),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isExporting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Generate & Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: (_selectedDataType ==
              ExportDataType.singleCustomerLedger &&
              _selectedCustomer == null)
              ? null // Disable button if a customer isn't selected
              : _startExport,
        ),
      ),
    );
  }

  // --- Helper Widgets for Cleaner Code ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<T>(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.indigo,
      ),
    );
  }

  Widget _buildFormatChip(ExportFormat format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      label: Text(format.name.toUpperCase()),
      avatar: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.indigo.shade600,
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFormat = format);
        }
      },
      selectedColor: Colors.indigo.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
