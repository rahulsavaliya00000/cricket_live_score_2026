import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cricket_live_score/features/ugc/domain/entities/ugc_post_entity.dart';

class UGCRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collection = 'ugc_posts';
  static const int _pageSize = 1;

  UGCRepository(this._firestore, this._storage);

  /// Result class for paginated posts
  static final ({List<UGCPost> posts, DocumentSnapshot? lastDoc}) _emptyResult = 
      (posts: [], lastDoc: null);

  /// Upload image to Firebase Storage and return the download URL
  Future<String> uploadImage(File imageFile, String fileName) async {
    final bucket = _storage.bucket;
    try {
      final ref = _storage.ref().child('ugc_images/$fileName');
      
      // Simpler upload logic
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw 'Storage error (object-not-found): The bucket "$bucket" was not found. Please ensure Storage is enabled in the Firebase Console and that the bucket name matches.';
      }
      throw 'Firebase Storage error (${e.code}): ${e.message}';
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  /// Get total number of posts
  Future<int> getTotalCount() async {
    try {
      final aggregateQuery = _firestore.collection(_collection).count();
      final res = await aggregateQuery.get();
      return res.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch paginated UGC posts (oldest first, pinned first)
  Future<({List<UGCPost> posts, DocumentSnapshot? lastDoc})> getPaginatedPosts({
    DocumentSnapshot? lastDocument,
    int? page,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Order: pinned first, then by timestamp ascending (oldest first)
      query = query
          .orderBy('isPinned', descending: true)
          .orderBy('timestamp', descending: false);

      // Manual Page Jump (Offset)
      if (page != null && page > 0) {
        // Fetch up to the required page number
        query = query.limit(page);
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty || snapshot.docs.length < page) return _emptyResult;
        
        // Take ONLY the document at the specific page index
        final doc = snapshot.docs[page - 1];
        final posts = [
          UGCPost(
            id: doc.id,
            title: doc['title'] ?? '',
            content: doc['content'] ?? '',
            imageUrl: doc['imageUrl'],
            customTag: doc['customTag'],
            hideUrl: doc['hideUrl'] ?? false,
            externalUrl: doc['externalUrl'],
            linkName: doc['linkName'],
            timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            userId: doc['userId'] ?? '',
            userName: doc['userName'] ?? 'Unknown',
            userAvatar: doc['userAvatar'],
            views: doc['views'] ?? 0,
            isPinned: doc['isPinned'] ?? false,
          )
        ];
        return (posts: posts, lastDoc: doc);
      } else if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(_pageSize);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return _emptyResult;

      final posts = snapshot.docs
          .map(
            (doc) => UGCPost(
              id: doc.id,
              title: doc['title'] ?? '',
              content: doc['content'] ?? '',
              imageUrl: doc['imageUrl'],
              customTag: doc['customTag'],
              hideUrl: doc['hideUrl'] ?? false,
              externalUrl: doc['externalUrl'],
              linkName: doc['linkName'],
              timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              userId: doc['userId'] ?? '',
              userName: doc['userName'] ?? 'Unknown',
              userAvatar: doc['userAvatar'],
              views: doc['views'] ?? 0,
              isPinned: doc['isPinned'] ?? false,
            ),
          )
          .toList();
      
      return (posts: posts, lastDoc: snapshot.docs.last);
    } catch (e) {
      rethrow;
    }
  }

  /// Increment view count for a post
  Future<void> incrementViews(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new UGC post
  Future<String> createPost({
    required String title,
    required String content,
    String? imageUrl,
    String? customTag,
    bool hideUrl = false,
    String? externalUrl,
    String? linkName,
    required String userId,
    required String userName,
    String? userAvatar,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'customTag': customTag,
        'hideUrl': hideUrl,
        'externalUrl': externalUrl,
        'linkName': linkName,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'views': 0,
        'isPinned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get single post by ID
  Future<UGCPost?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (!doc.exists) return null;

      return UGCPost(
        id: doc.id,
        title: doc['title'] ?? '',
        content: doc['content'] ?? '',
        imageUrl: doc['imageUrl'],
        customTag: doc['customTag'],
        hideUrl: doc['hideUrl'] ?? false,
        externalUrl: doc['externalUrl'],
        linkName: doc['linkName'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
        userId: doc['userId'] ?? '',
        userName: doc['userName'] ?? 'Unknown',
        userAvatar: doc['userAvatar'],
        views: doc['views'] ?? 0,
        isPinned: doc['isPinned'] ?? false,
      );
    } catch (e) {
      rethrow;
    }
  }
}
