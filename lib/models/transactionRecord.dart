// C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/models/transaction_record.dart

import 'package:flutter/foundation.dart';

enum TransactionType { loan, repayment }

class TransactionRecord {
  String id;
  String customerId;
  TransactionType type;
  String loanKind;
  double amount;
  double interestPercent;
  String date;
  String note;

  TransactionRecord({
    required this.id,
    required this.customerId,
    required this.type,
    required this.loanKind,
    required this.amount,
    required this.interestPercent,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'type': describeEnum(type),
    'loanKind': loanKind,
    'amount': amount,
    'interestPercent': interestPercent,
    'date': date,
    'note': note,
  };

  static TransactionRecord fromJson(Map<String, dynamic> j) {
    return TransactionRecord(
      id: j['id'],
      customerId: j['customerId'],
      type: j['type'] == 'loan'
          ? TransactionType.loan
          : TransactionType.repayment,
      loanKind: j['loanKind'],
      amount: (j['amount'] as num).toDouble(),
      interestPercent: (j['interestPercent'] as num).toDouble(),
      date: j['date'],
      note: j['note'] ?? '',
    );
  }
}
