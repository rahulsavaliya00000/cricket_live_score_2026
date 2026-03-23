import 'package:equatable/equatable.dart';

/// Type of in-app currency involved in this transaction.
enum RewardType { coins, balls, bats }

class WalletTransaction extends Equatable {
  final String id;
  final String description;
  final double amount; // Changed to double for fractional coins
  final RewardType type;
  final DateTime date;
  final bool isCredit;

  const WalletTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.isCredit,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'type': type.name,
    'date': date.toIso8601String(),
    'isCredit': isCredit,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: RewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RewardType.coins,
      ),
      date: DateTime.parse(json['date'] as String),
      isCredit: json['isCredit'] as bool,
    );
  }

  @override
  List<Object?> get props => [id, description, amount, type, date, isCredit];
}
