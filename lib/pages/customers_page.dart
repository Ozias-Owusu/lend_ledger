// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';
// import 'add_customer_page.dart';
// import 'customer_ledger_page.dart';
//
// class CustomersPage extends StatefulWidget {
//   final bool openForLoan;
//   const CustomersPage({super.key, this.openForLoan = false});
//
//   @override
//   State<CustomersPage> createState() => _CustomersPageState();
// }
//
// class _CustomersPageState extends State<CustomersPage> {
//   String _query = '';
//
//   @override
//   Widget build(BuildContext context) {
//     final state = Provider.of<AppState>(context);
//     final list = state.customers.where((c) {
//       final q = _query.toLowerCase();
//       return c.name.toLowerCase().contains(q) || c.vehicle.toLowerCase().contains(q);
//     }).toList();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Customers')),
//       body: Column(children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or vehicle'),
//             onChanged: (v) => setState(() => _query = v),
//           ),
//         ),
//         Expanded(
//           child: ListView.builder(
//             itemCount: list.length,
//             itemBuilder: (c, i) {
//               final cust = list[i];
//               return ListTile(
//                 title: Text(cust.name),
//                 subtitle: Text('${cust.vehicle} • ${cust.phone}'),
//                 trailing: Text('${state.computeBalance(cust.id).toStringAsFixed(2)}'),
//                 onTap: () {
//                   // If opened for loan, go to ledger to add loan
//                   Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerLedgerPage(customer: cust)));
//                 },
//               );
//             },
//           ),
//         )
//       ]),
//       floatingActionButton: FloatingActionButton(
//         child: const Icon(Icons.person_add),
//         onPressed: () {
//           Navigator.push(context, MaterialPageRoute(builder: (c) => const AddCustomerPage()));
//         },
//       ),
//     );
//   }
// }

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';
import '../utils/image_data_utils.dart';
import 'add_customer_page.dart';
import 'customer_ledger_page.dart';

class CustomersPage extends StatefulWidget {
  final bool openForLoan;
  const CustomersPage({super.key, this.openForLoan = false});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _query = '';
  late Future<void> _initialLoad;
  bool _isDownloadingTemplate = false;
  bool _isUploadingImport = false;

  @override
  void initState() {
    super.initState();
    _initialLoad = context.read<AppState>().loadCustomersFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    final list = state.apiCustomers.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name or phone',
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloadingTemplate || _isUploadingImport
                        ? null
                        : _downloadTemplate,
                    icon: _isDownloadingTemplate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Download Template'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isUploadingImport || _isDownloadingTemplate
                        ? null
                        : _pickAndUploadFile,
                    icon: _isUploadingImport
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload File'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<void>(
              future: _initialLoad,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.customersApiError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Unable to load customers from API",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.customersApiError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _initialLoad = context
                                    .read<AppState>()
                                    .loadCustomersFromApi();
                              });
                            },
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "No customers found",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<AppState>().loadCustomersFromApi(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final cust = list[i];
                      final balance = cust.getOutstandingBalanceFromApiLoans();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Slidable(
                          key: ValueKey(cust.id),

                          // LEFT ACTIONS
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                backgroundColor: Colors.blue,
                                icon: Icons.edit,
                                label: 'Edit',
                                onPressed: (_) => _confirmEdit(cust),
                              ),
                            ],
                          ),

                          // RIGHT ACTIONS
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Delete',
                                onPressed: (_) => _confirmDelete(cust, state),
                              ),
                            ],
                          ),

                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Row(
                                children: [
                                  _buildCustomerAvatar(cust),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cust.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "📞 ${cust.phone}",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          "💳 ${cust.ghanaCardNumber.isEmpty ? "Ghana card Number not set" : cust.ghanaCardNumber}",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          "🪪 ${cust.licenseIdNumber.isEmpty ? "License number not set" : cust.licenseIdNumber}",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AmountFormatter.compactCurrency(balance),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text("Balance"),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CustomerLedgerPage(customer: cust),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(
          child: const Icon(Icons.person_add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerPage()),
            );
          },
        ),
      ),
    );
  }

  // CONFIRM DELETE
  void _confirmDelete(Customer customer, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Customer"),
        content: Text(
          "Are you sure you want to delete ${customer.name}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AppState>().deleteCustomerFromApi(
                  customer.id,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Customer deleted successfully."),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // CONFIRM EDIT
  void _confirmEdit(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(customerToEdit: customer),
      ),
    );
  }

  Widget _buildCustomerAvatar(Customer customer) {
    final imageBytes = _profileBytes(customer.profilePicture);
    if (imageBytes != null) {
      return ClipOval(
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(customer),
          ),
        ),
      );
    }
    return _buildInitialAvatar(customer);
  }

  Widget _buildInitialAvatar(Customer customer) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.blueGrey,
      child: Text(
        customer.firstInitial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  Uint8List? _profileBytes(String? profileBase64) {
    return ImageDataUtils.decodeToBytes(profileBase64);
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloadingTemplate = true);
    try {
      final template = await context
          .read<AppState>()
          .downloadCustomersImportTemplate();
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${template.filename}';
      final file = File(savePath);
      await file.writeAsBytes(template.bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template downloaded: ${template.filename}')),
      );
      await OpenFilex.open(savePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download template: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloadingTemplate = false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'xls', 'xlsx', 'doc', 'docx'],
      );
      if (result == null) return;

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file selected.')),
        );
        return;
      }

      final confirmed = await _showFilePreview(path);
      if (confirmed != true) {
        return;
      }

      setState(() => _isUploadingImport = true);
      await context.read<AppState>().importCustomersFileToApi(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customers file uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImport = false);
      }
    }
  }

  Future<bool?> _showFilePreview(String path) async {
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;
    final ext = name.split('.').last.toLowerCase();

    Widget content;
    if (ext == 'xlsx' || ext == 'xls') {
      try {
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final sheetName = excel.tables.keys.isNotEmpty
            ? excel.tables.keys.first
            : null;
        final sheet = sheetName != null ? excel.tables[sheetName] : null;
        final rows = sheet?.rows ?? const [];

        final previewRows = rows.take(10).toList();
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sheetName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Sheet: $sheetName (showing first ${previewRows.length} rows)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 280),
                  child: SingleChildScrollView(
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.all(
                        color: const Color(0xFFE0E0E0),
                      ),
                      children: previewRows.map((row) {
                        final cells = row
                            .map((c) => (c?.value ?? '').toString())
                            .toList();
                        return TableRow(
                          children: cells
                              .map(
                                (text) => Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } catch (_) {
        content = Text(
          'File: $name\n\nUnable to preview this Excel file, but you can still upload it.',
          style: const TextStyle(fontSize: 13),
        );
      }
    } else {
      final sizeBytes = await file.length();
      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
      content = Text(
        'File: $name\nType: $ext\nSize: $sizeKb KB\n\nOnly Excel files can show a row preview. This file will still be uploaded if you continue.',
        style: const TextStyle(fontSize: 13),
      );
    }

    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preview before upload'),
          content: SizedBox(
            width: double.maxFinite,
            child: content,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }
}
