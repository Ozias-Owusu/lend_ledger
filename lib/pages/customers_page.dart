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

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    final list = state.customers.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name or vehicle',
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          Expanded(
            child: list.isEmpty
                ? const Center(
                child: Text("No customers found", style: TextStyle(fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final cust = list[i];
                final balance = state.computeBalance(cust.id);

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
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          cust.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📞 ${cust.phone}"),
                              Text("💳 ${cust.ghanaCardNumber ?? "Ghana card Number not set"}"),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              balance.toStringAsFixed(2),
                              style: TextStyle(
                                color: balance < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text("Balance"),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerLedgerPage(customer: cust),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        },
      ),
    );
  }

  // CONFIRM DELETE
  void _confirmDelete(customer, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Customer"),
        content: Text("Are you sure you want to delete ${customer.name}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              state.deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // CONFIRM EDIT
  void _confirmEdit(customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Customer"),
        content: Text("Do you want to edit the details of ${customer.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCustomerPage(customerToEdit: customer),
                ),
              );
            },
            child: const Text("Edit"),
          ),
        ],
      ),
    );
  }
}
