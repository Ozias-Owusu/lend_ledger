class LoanMetrics {
  final int totalCustomers;
  final double loansTodayAmount;
  final double totalOutstandingAmount;
  final int totalActiveLoansCount;
  final double totalActivePrincipalAmount;
  final double totalActiveRepayableAmount;
  final int activeDailyLoansCount;
  final double activeDailyPrincipalAmount;
  final double activeDailyRepayableAmount;
  final int activeSoftLoansCount;
  final double activeSoftPrincipalAmount;
  final double activeSoftRepayableAmount;

  const LoanMetrics({
    required this.totalCustomers,
    required this.loansTodayAmount,
    required this.totalOutstandingAmount,
    required this.totalActiveLoansCount,
    required this.totalActivePrincipalAmount,
    required this.totalActiveRepayableAmount,
    required this.activeDailyLoansCount,
    required this.activeDailyPrincipalAmount,
    required this.activeDailyRepayableAmount,
    required this.activeSoftLoansCount,
    required this.activeSoftPrincipalAmount,
    required this.activeSoftRepayableAmount,
  });

  factory LoanMetrics.fromJson(Map<String, dynamic> json) {
    return LoanMetrics(
      totalCustomers: _asInt(json['totalCustomers']),
      loansTodayAmount: _asDouble(json['loansTodayAmount']),
      totalOutstandingAmount: _asDouble(json['totalOutstandingAmount']),
      totalActiveLoansCount: _asInt(json['totalActiveLoansCount']),
      totalActivePrincipalAmount: _asDouble(json['totalActivePrincipalAmount']),
      totalActiveRepayableAmount: _asDouble(json['totalActiveRepayableAmount']),
      activeDailyLoansCount: _asInt(json['activeDailyLoansCount']),
      activeDailyPrincipalAmount: _asDouble(json['activeDailyPrincipalAmount']),
      activeDailyRepayableAmount: _asDouble(json['activeDailyRepayableAmount']),
      activeSoftLoansCount: _asInt(json['activeSoftLoansCount']),
      activeSoftPrincipalAmount: _asDouble(json['activeSoftPrincipalAmount']),
      activeSoftRepayableAmount: _asDouble(json['activeSoftRepayableAmount']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}
