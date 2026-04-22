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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/amount_formatter.dart';
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
    if (profileBase64 == null || profileBase64.trim().isEmpty) return null;
    try {
      return base64Decode(profileBase64);
    } catch (_) {
      return null;
    }
  }
}
