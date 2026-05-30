import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channels — one per activity category.
class NotificationChannels {
  NotificationChannels._();

  static const general = NotificationChannelDef(
    id: 'lend_ledger_general',
    name: 'General',
    description: 'General Lend Ledger updates',
  );

  static const dailyLoan = NotificationChannelDef(
    id: 'lend_ledger_daily_loan',
    name: 'Daily loans',
    description: 'Daily loan activity',
  );

  static const softLoan = NotificationChannelDef(
    id: 'lend_ledger_soft_loan',
    name: 'Soft loans',
    description: 'Soft loan activity',
  );

  static const repayment = NotificationChannelDef(
    id: 'lend_ledger_repayment',
    name: 'Repayments',
    description: 'Repayment activity',
  );

  static const customer = NotificationChannelDef(
    id: 'lend_ledger_customer',
    name: 'Customers',
    description: 'Customer updates',
  );

  static const auth = NotificationChannelDef(
    id: 'lend_ledger_auth',
    name: 'Account',
    description: 'Account and security alerts',
  );

  static List<NotificationChannelDef> get all => [
        general,
        dailyLoan,
        softLoan,
        repayment,
        customer,
        auth,
      ];

  static NotificationChannelDef forType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('daily_loan')) return dailyLoan;
    if (normalized.contains('soft_loan')) return softLoan;
    if (normalized.contains('repayment') || normalized.contains('payment')) {
      return repayment;
    }
    if (normalized.contains('customer')) return customer;
    if (normalized.contains('auth') ||
        normalized.contains('password') ||
        normalized.contains('login')) {
      return auth;
    }
    return general;
  }
}

class NotificationChannelDef {
  const NotificationChannelDef({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  AndroidNotificationChannel toAndroidChannel() {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
  }
}
