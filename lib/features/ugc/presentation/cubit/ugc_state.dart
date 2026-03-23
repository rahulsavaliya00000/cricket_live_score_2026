part of 'ugc_cubit.dart';

abstract class UGCState extends Equatable {
  const UGCState();

  bool get hasMore => false;

  @override
  List<Object?> get props => [];
}

class UGCInitial extends UGCState {
  const UGCInitial();
}

class UGCLoading extends UGCState {
  const UGCLoading();
}

class UGCLoadingMore extends UGCState {
  final List<UGCPost> posts;
  
  const UGCLoadingMore({required this.posts});

  @override
  bool get hasMore => true;

  @override
  List<Object?> get props => [posts];
}

class UGCLoaded extends UGCState {
  final List<UGCPost> posts;
  final int currentPage;
  final int totalCount;
  @override
  final bool hasMore;

  const UGCLoaded({
    required this.posts,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [posts, currentPage, totalCount, hasMore];
}

class UGCEmpty extends UGCState {
  const UGCEmpty();
}

class UGCError extends UGCState {
  final String message;

  const UGCError({required this.message});

  @override
  List<Object?> get props => [message];
}
