part of 'wallet_cubit.dart';

class WalletState extends Equatable {
  final double irCoins;
  final int balls;
  final int bats;
  final List<WalletTransaction> transactions;
  final int adsWatchedToday;
  final DateTime? lastAdWatchDate;
  final DateTime? lastFreeSpinDate;
  final bool isSpinning;

  const WalletState({
    this.irCoins = 10.0, // Changed to double
    this.balls = 2,
    this.bats = 1,
    this.transactions = const [],
    this.adsWatchedToday = 0,
    this.lastAdWatchDate,
    this.lastFreeSpinDate,
    this.isSpinning = false,
  });

  WalletState copyWith({
    double? irCoins,
    int? balls,
    int? bats,
    List<WalletTransaction>? transactions,
    int? adsWatchedToday,
    DateTime? lastAdWatchDate,
    DateTime? lastFreeSpinDate,
    bool? isSpinning,
  }) {
    return WalletState(
      irCoins: irCoins ?? this.irCoins,
      balls: balls ?? this.balls,
      bats: bats ?? this.bats,
      transactions: transactions ?? this.transactions,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      lastAdWatchDate: lastAdWatchDate ?? this.lastAdWatchDate,
      lastFreeSpinDate: lastFreeSpinDate ?? this.lastFreeSpinDate,
      isSpinning: isSpinning ?? this.isSpinning,
    );
  }

  @override
  List<Object?> get props => [
    irCoins,
    balls,
    bats,
    transactions,
    adsWatchedToday,
    lastAdWatchDate,
    lastFreeSpinDate,
    isSpinning,
  ];

  bool get canSpinFree {
    if (AppConstants.devForceSpinAvailable) return true; // dev flag
    if (lastFreeSpinDate == null) return true;
    final now = DateTime.now();
    return now.year != lastFreeSpinDate!.year ||
        now.month != lastFreeSpinDate!.month ||
        now.day != lastFreeSpinDate!.day;
  }
}
