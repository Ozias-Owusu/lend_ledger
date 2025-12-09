
class Installment {
  final DateTime dueDate;
  final double amount;
  final String status; // e.g., "Paid", "Due", "Upcoming"

  Installment({
    required this.dueDate,
    required this.amount,
    required this.status,
  });
}
