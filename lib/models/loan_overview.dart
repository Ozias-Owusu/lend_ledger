class LoanOverview {
  const LoanOverview({
    required this.stats,
    required this.repaymentTrend,
    required this.loanTypeBreakdown,
    required this.statusBreakdown,
    required this.topCustomers,
    required this.insight,
  });

  final LoanOverviewStats stats;
  final List<LoanOverviewTrendPoint> repaymentTrend;
  final LoanTypeBreakdown loanTypeBreakdown;
  final LoanStatusBreakdown statusBreakdown;
  final List<OverviewTopCustomer> topCustomers;
  final OverviewInsight? insight;

  factory LoanOverview.fromJson(Map<String, dynamic> json) {
    final statsJson = _asMap(json['stats']);
    final trendRaw = json['repaymentTrend'];
    final trendList = trendRaw is List ? trendRaw : const [];
    final topCustomersRaw = json['topCustomers'];
    final topCustomersList = topCustomersRaw is List ? topCustomersRaw : const [];

    return LoanOverview(
      stats: LoanOverviewStats.fromJson(statsJson),
      repaymentTrend: trendList
          .map((e) => LoanOverviewTrendPoint.fromJson(_asMap(e)))
          .toList(),
      loanTypeBreakdown: LoanTypeBreakdown.fromJson(_asMap(json['loanTypeBreakdown'])),
      statusBreakdown: LoanStatusBreakdown.fromJson(_asMap(json['statusBreakdown'])),
      topCustomers: topCustomersList
          .map((e) => OverviewTopCustomer.fromJson(_asMap(e)))
          .toList(),
      insight: json['insight'] == null
          ? null
          : OverviewInsight.fromJson(_asMap(json['insight'])),
    );
  }
}

class LoanOverviewStats {
  const LoanOverviewStats({
    required this.totalOutstanding,
    required this.totalRepaidThisMonth,
    required this.totalBorrowedThisMonth,
    required this.totalCustomers,
    required this.activeBorrowers,
  });

  final double totalOutstanding;
  final double totalRepaidThisMonth;
  final double totalBorrowedThisMonth;
  final int totalCustomers;
  final int activeBorrowers;

  factory LoanOverviewStats.fromJson(Map<String, dynamic> json) {
    return LoanOverviewStats(
      totalOutstanding: _asDouble(json['totalOutstanding']),
      totalRepaidThisMonth: _asDouble(json['totalRepaidThisMonth']),
      totalBorrowedThisMonth: _asDouble(json['totalBorrowedThisMonth']),
      totalCustomers: _asInt(json['totalCustomers']),
      activeBorrowers: _asInt(json['activeBorrowers']),
    );
  }
}

class LoanOverviewTrendPoint {
  const LoanOverviewTrendPoint({
    required this.month,
    required this.borrowed,
    required this.repaid,
    required this.outstanding,
    this.dailyBorrowed,
    this.softBorrowed,
    this.dailyRepaid,
    this.softRepaid,
    this.dailyOutstanding,
    this.softOutstanding,
  });

  final String month;
  final double borrowed;
  final double repaid;
  final double outstanding;
  final double? dailyBorrowed;
  final double? softBorrowed;
  final double? dailyRepaid;
  final double? softRepaid;
  final double? dailyOutstanding;
  final double? softOutstanding;

  factory LoanOverviewTrendPoint.fromJson(Map<String, dynamic> json) {
    return LoanOverviewTrendPoint(
      month: (json['month'] ?? '').toString(),
      borrowed: _asDouble(json['borrowed']),
      repaid: _asDouble(json['repaid']),
      outstanding: _asDouble(json['outstanding']),
      dailyBorrowed: _asNullableDouble(
        json['dailyBorrowed'] ?? json['dailyLoanBorrowed'],
      ),
      softBorrowed: _asNullableDouble(
        json['softBorrowed'] ?? json['softLoanBorrowed'],
      ),
      dailyRepaid: _asNullableDouble(
        json['dailyRepaid'] ?? json['dailyLoanRepaid'],
      ),
      softRepaid: _asNullableDouble(
        json['softRepaid'] ?? json['softLoanRepaid'],
      ),
      dailyOutstanding: _asNullableDouble(
        json['dailyOutstanding'] ?? json['dailyLoanOutstanding'],
      ),
      softOutstanding: _asNullableDouble(
        json['softOutstanding'] ?? json['softLoanOutstanding'],
      ),
    );
  }
}

class LoanTypeBreakdown {
  const LoanTypeBreakdown({
    required this.dailyOutstanding,
    required this.softOutstanding,
    required this.dailyPercent,
    required this.softPercent,
    this.dailyBorrowed,
    this.softBorrowed,
    this.dailyRepaid,
    this.softRepaid,
    this.dailyLoanCount,
    this.softLoanCount,
    this.dailyAvgLoanAmount,
    this.softAvgLoanAmount,
  });

  final double dailyOutstanding;
  final double softOutstanding;
  final double dailyPercent;
  final double softPercent;
  final double? dailyBorrowed;
  final double? softBorrowed;
  final double? dailyRepaid;
  final double? softRepaid;
  final int? dailyLoanCount;
  final int? softLoanCount;
  final double? dailyAvgLoanAmount;
  final double? softAvgLoanAmount;

  factory LoanTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return LoanTypeBreakdown(
      dailyOutstanding: _asDouble(json['dailyOutstanding']),
      softOutstanding: _asDouble(json['softOutstanding']),
      dailyPercent: _fraction(_asDouble(json['dailyPercent'])),
      softPercent: _fraction(_asDouble(json['softPercent'])),
      dailyBorrowed: _asNullableDouble(
        json['dailyBorrowed'] ?? json['dailyLoanBorrowed'],
      ),
      softBorrowed: _asNullableDouble(
        json['softBorrowed'] ?? json['softLoanBorrowed'],
      ),
      dailyRepaid: _asNullableDouble(
        json['dailyRepaid'] ?? json['dailyLoanRepaid'],
      ),
      softRepaid: _asNullableDouble(
        json['softRepaid'] ?? json['softLoanRepaid'],
      ),
      dailyLoanCount: _asNullableInt(
        json['dailyLoanCount'] ?? json['dailyCount'],
      ),
      softLoanCount: _asNullableInt(
        json['softLoanCount'] ?? json['softCount'],
      ),
      dailyAvgLoanAmount: _asNullableDouble(
        json['dailyAvgLoanAmount'] ?? json['dailyAverageLoanAmount'],
      ),
      softAvgLoanAmount: _asNullableDouble(
        json['softAvgLoanAmount'] ?? json['softAverageLoanAmount'],
      ),
    );
  }
}

class LoanStatusBreakdown {
  const LoanStatusBreakdown({
    required this.onTrackCount,
    required this.dueSoonCount,
    required this.overdueCount,
    required this.onTrackPercent,
    required this.dueSoonPercent,
    required this.overduePercent,
  });

  final int onTrackCount;
  final int dueSoonCount;
  final int overdueCount;
  final double onTrackPercent;
  final double dueSoonPercent;
  final double overduePercent;

  factory LoanStatusBreakdown.fromJson(Map<String, dynamic> json) {
    final onTrack = _asInt(json['onTrackCount'] ?? json['onTrack']);
    final dueSoon = _asInt(json['dueSoonCount'] ?? json['dueSoon']);
    final overdue = _asInt(json['overdueCount'] ?? json['overdue']);
    final total = onTrack + dueSoon + overdue;

    final onTrackPercent = _fraction(
      _asDouble(json['onTrackPercent']),
      fallback: total == 0 ? 0 : onTrack / total,
    );
    final dueSoonPercent = _fraction(
      _asDouble(json['dueSoonPercent']),
      fallback: total == 0 ? 0 : dueSoon / total,
    );
    final overduePercent = _fraction(
      _asDouble(json['overduePercent']),
      fallback: total == 0 ? 0 : overdue / total,
    );

    return LoanStatusBreakdown(
      onTrackCount: onTrack,
      dueSoonCount: dueSoon,
      overdueCount: overdue,
      onTrackPercent: onTrackPercent,
      dueSoonPercent: dueSoonPercent,
      overduePercent: overduePercent,
    );
  }
}

class OverviewTopCustomer {
  const OverviewTopCustomer({
    required this.customerId,
    required this.customerName,
    required this.outstanding,
    required this.profileImage,
    required this.activeLoansCount,
  });

  final String customerId;
  final String customerName;
  final double outstanding;
  final String? profileImage;
  final int activeLoansCount;

  factory OverviewTopCustomer.fromJson(Map<String, dynamic> json) {
    return OverviewTopCustomer(
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ??
              json['fullName'] ??
              json['name'] ??
              'Unknown customer')
          .toString(),
      outstanding: _asDouble(
        json['outstandingAmount'] ?? json['outstanding'] ?? json['amount'],
      ),
      profileImage:
          (json['profilePicture'] ?? json['profileImage'])?.toString(),
      activeLoansCount:
          _asInt(json['activeLoansCount'] ?? json['activeLoanCount']),
    );
  }
}

class OverviewInsight {
  const OverviewInsight({
    required this.message,
    required this.changePercent,
    required this.isPositive,
  });

  final String message;
  final double changePercent;
  final bool isPositive;

  factory OverviewInsight.fromJson(Map<String, dynamic> json) {
    final change = _asDouble(json['changePercent'] ?? json['repaymentChangePercent']);
    return OverviewInsight(
      message: (json['message'] ?? '').toString(),
      changePercent: _fraction(change),
      isPositive: json['isPositive'] == true ||
          (json['direction'] ?? '').toString().toLowerCase() == 'up' ||
          change >= 0,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0.0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

double _fraction(double value, {double fallback = 0}) {
  if (value == 0) return fallback;
  if (value > 1) return value / 100;
  return value;
}
