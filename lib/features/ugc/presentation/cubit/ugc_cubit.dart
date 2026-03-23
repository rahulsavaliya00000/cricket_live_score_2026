import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cricketbuzz/features/ugc/domain/entities/ugc_post_entity.dart';
import 'package:cricketbuzz/features/ugc/data/repositories/ugc_repository.dart';

part 'ugc_state.dart';

class UGCCubit extends Cubit<UGCState> {
  final UGCRepository repository;

  UGCCubit(this.repository) : super(UGCInitial());

  int _totalCount = 0;
  List<UGCPost> _currentPosts = [];

  /// Initial load: Get total count and first page
  Future<void> loadPosts() async {
    try {
      if (isClosed) return;
      emit(UGCLoading());
      _totalCount = await repository.getTotalCount();
      
      if (isClosed) return;
      if (_totalCount == 0) {
        emit(UGCEmpty());
        return;
      }

      final result = await repository.getPaginatedPosts(page: 1);
      if (isClosed) return;
      _currentPosts = result.posts;

      if (_currentPosts.isNotEmpty) {
        emit(UGCLoaded(
          posts: _currentPosts,
          currentPage: 1,
          totalCount: _totalCount,
          hasMore: _totalCount > 1,
        ));
      } else {
        emit(UGCEmpty());
      }
    } catch (e) {
      if (!isClosed) {
        emit(UGCError(message: e.toString()));
      }
    }
  }

  /// Go to a specific page number
  Future<void> goToPage(int page) async {
    if (state is! UGCLoaded && state is! UGCLoadingMore) return;
    
    try {
      // Keep existing posts while loading to prevent jumpy UI
      final previousPosts = (state is UGCLoaded) 
          ? (state as UGCLoaded).posts 
          : (state is UGCLoadingMore) ? (state as UGCLoadingMore).posts : <UGCPost>[];
          
      if (isClosed) return;
      emit(UGCLoadingMore(posts: previousPosts));

      final result = await repository.getPaginatedPosts(page: page);
      if (isClosed) return;
      _currentPosts = result.posts;

      if (_currentPosts.isNotEmpty) {
        // Increment views for the post we are looking at
        await repository.incrementViews(_currentPosts[0].id);
        
        if (isClosed) return;
        emit(UGCLoaded(
          posts: _currentPosts,
          currentPage: page,
          totalCount: _totalCount,
          hasMore: page < _totalCount,
        ));
      } else {
        if (isClosed) return;
        emit(UGCEmpty());
      }
    } catch (e) {
      if (!isClosed) {
        emit(UGCError(message: e.toString()));
      }
    }
  }

  /// Refresh everything
  Future<void> refreshPosts() async {
    await loadPosts();
  }
}
