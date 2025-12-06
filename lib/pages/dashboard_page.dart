import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../state/app_state.dart';
import 'customers_page.dart';
import 'settings_page.dart';
import 'export_data_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Scaffold(
        // Use a CustomScrollView for ultimate layout flexibility
        body: CustomScrollView(
          slivers: [
            // Sliver 1: The Welcome Card (always full width)
            SliverToBoxAdapter(
              child: _buildItem(context, 0, state, textTheme),
            ),

            // Sliver 2: The responsive grid for summary cards
            _buildResponsiveGrid(context, state, textTheme),

            // Sliver 3: The Quick Actions section (always full width)
            SliverToBoxAdapter(
              child: _buildItem(context, 5, state, textTheme),
            ),
          ],
        ),
        floatingActionButton: _buildSpeedDial(context),
      ),
    );
  }

  // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/dashboard_page.dart

  // New helper method to build the responsive grid for summary cards
  Widget _buildResponsiveGrid(BuildContext context, AppState state, TextTheme textTheme) {
    // *** THE FIX IS HERE ***
    // The LayoutBuilder must be the direct child of the sliver, not the other way around.
    // It builds a SliverPadding, which in turn contains the SliverGrid.
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Decide on the number of columns based on screen width.
        final crossAxisCount = constraints.crossAxisExtent < 360 ? 1 : 2;

        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                // Map the grid index (0-3) to the summary card indices (1-4)
                return _buildItem(context, index + 1, state, textTheme);
              },
              childCount: 4, // We are only showing the 4 summary cards
            ),
          ),
        );
      },
    );
  }


  Widget _buildItem(
      BuildContext context,
      int index,
      AppState state,
      TextTheme textTheme,
      ) {
    switch (index) {
      case 0: // Welcome Card
        return _buildWelcomeCard(state.loggedInUserName, textTheme);
      case 1: // Total Customers
        return _buildSummaryCard(
          title: 'Total Customers',
          value: state.totalCustomers().toString(),
          icon: Icons.groups,
          color: Colors.lightBlue,
          textTheme: textTheme,
        );
      case 2: // Outstanding Loans
        return _buildSummaryCard(
          title: 'Total Outstanding',
          value: 'GHS ${state.totalOutstanding().toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          textTheme: textTheme,
        );
      case 3: // Loans Today
        return _buildSummaryCard(
          title: 'Loans Today',
          value: 'GHS ${state.getLoansToday().toStringAsFixed(2)}',
          icon: Icons.today,
          color: Colors.green,
          textTheme: textTheme,
        );
      case 4: // Active Loans
        return _buildSummaryCard(
          title: 'Active Loans',
          value: state.getActiveLoanCount().toString(),
          icon: Icons.trending_up,
          color: Colors.pink,
          textTheme: textTheme,
        );
      case 5: // Quick Actions
        return _buildQuickActionsCard(context, textTheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // The rest of your helper methods (_buildWelcomeCard, _buildSummaryCard, etc.)
  // can remain exactly the same as you have them. I am including them here
  // for completeness.

  Widget _buildWelcomeCard(String email, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/card_bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.transparent,
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 140),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 24),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            email,
                            style: textTheme.displaySmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required TextTheme textTheme,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blueGrey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              'Quick Actions',
              style: textTheme.titleMedium
                  ?.copyWith(color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 19),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickActionButton(
                context,
                icon: Icons.people_alt_outlined,
                color: Colors.red,
                color2: Colors.red,
                label: 'Customers',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const CustomersPage())),
              ),
              _quickActionButton(
                context,
                icon: Icons.bar_chart_outlined,
                color: Colors.purple,
                color2: Colors.purple,
                label: 'Reports',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reports: Coming later'))),
              ),
              _quickActionButton(
                context,
                icon: Icons.download_outlined,
                color: Colors.green,
                color2: Colors.green,
                label: 'Export',
                onPressed: () {
                  // This is the change!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const ExportDataPage()),
                  );
                },
                // onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(content: Text('Export: Coming later'))),
              ),
              _quickActionButton(
                context,
                icon: Icons.settings_outlined,
                color: Colors.black,
                label: 'Settings',
                color2: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(BuildContext context,
      {
        required IconData icon,
        required String label,
        required Color color,
        required Color color2,
        VoidCallback? onPressed
      }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color2,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  SpeedDial _buildSpeedDial(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    return SpeedDial(
      icon: Icons.question_mark,
      activeIcon: Icons.close,
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.person_add),
          label: 'New Customer',
          backgroundColor: Colors.lightBlue,
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (c) => const CustomersPage(openAddCustomer: true),
            //   ),
            // );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.post_add),
          label: 'New Loan',
          backgroundColor: Colors.green,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const CustomersPage(openForLoan: true)));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.payment),
          label: 'Add Repayment',
          backgroundColor: Colors.orange,
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (c) => const CustomersPage(openForRepayment: true),
            //   ),
            // );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.logout),
          label: 'Logout',
          backgroundColor: Colors.red.shade400,
          onTap: () async {
            await state.logout();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }
}
