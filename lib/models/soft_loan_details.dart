// C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/models/soft_loan_details.dart

class SoftLoanDetails {
  final String transactionId; // This links to the main transaction record
  final double principalAmount;
  final double interestRate;
  final double totalRepayable;
  final double installmentAmount;
  final String loanDuration; // e.g., "6 Weeks"
  final String loanEndDate;

  SoftLoanDetails({
    required this.transactionId,
    required this.principalAmount,
    required this.interestRate,
    required this.totalRepayable,
    required this.installmentAmount,
    required this.loanDuration,
    required this.loanEndDate,
  });

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'principalAmount': principalAmount,
    'interestRate': interestRate,
    'totalRepayable': totalRepayable,
    'installmentAmount': installmentAmount,
    'loanDuration': loanDuration,
    'loanEndDate': loanEndDate,
  };

  static SoftLoanDetails fromJson(Map<String, dynamic> json) => SoftLoanDetails(
    transactionId: json['transactionId'],
    principalAmount: json['principalAmount'],
    interestRate: json['interestRate'],
    totalRepayable: json['totalRepayable'],
    installmentAmount: json['installmentAmount'],
    loanDuration: json['loanDuration'],
    loanEndDate: json['loanEndDate'],
  );
}
