import 'package:lend_ledger/models/transactionRecord.dart';
import 'installment.dart';
class LoanRecord {
  String id;
  String customerId;
  TransactionType type;
  String loanKind;
  double amount;
  double interestPercent;
  String date;
  String note;
  double remainingAmount;
  List<Installment> installments;

  bool get isOverdue {
    final loanDate = DateTime.tryParse(date);
    if (loanDate == null) return false;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    return loanDate.isBefore(todayDateOnly);
  }

  LoanRecord({
    required this.id,
    required this.customerId,
    required this.type,
    required this.loanKind,
    required this.amount,
    required this.interestPercent,
    required this.date,
    required this.note,
    required this.remainingAmount,
    this.installments = const [],
  });

  // Factory constructor to create a LoanRecord from a TransactionRecord
  factory LoanRecord.fromTransaction(TransactionRecord t, double remaining) {
    return LoanRecord(
      id: t.id,
      customerId: t.customerId,
      loanKind: t.loanKind,
      amount: t.amount,
      interestPercent: t.interestPercent,
      date: t.date,
      note: t.note,
      remainingAmount: remaining,
      type: t.type == TransactionType.loan ? TransactionType.loan : TransactionType.repayment,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "customerId": customerId,
    "type": type.name,
    "loanKind": loanKind,
    "amount": amount,
    "interestPercent": interestPercent,
    "date": date,
    "note": note,

  };

  static LoanRecord fromJson(Map<String, dynamic> json) => LoanRecord(
    id: json["id"],
    customerId: json["customerId"],
    type: json["type"] == "loan" ? TransactionType.loan : TransactionType.repayment,
    loanKind: json["loanKind"],
    amount: (json["amount"] as num).toDouble(),
    interestPercent: (json["interestPercent"] as num).toDouble(),
    date: json["date"],
    note: json["note"],
    remainingAmount: json["remainingAmount"] as double,
  );
}

