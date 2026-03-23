import 'package:equatable/equatable.dart';

class UGCPost extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? customTag;
  final bool hideUrl;
  final String? externalUrl;
  final String? linkName;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int views;
  final bool isPinned;

  const UGCPost({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.customTag,
    this.hideUrl = false,
    this.externalUrl,
    this.linkName,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.views = 0,
    this.isPinned = false,
  });

  UGCPost copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? customTag,
    bool? hideUrl,
    String? externalUrl,
    String? linkName,
    DateTime? timestamp,
    String? userId,
    String? userName,
    String? userAvatar,
    int? views,
    bool? isPinned,
  }) {
    return UGCPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      customTag: customTag ?? this.customTag,
      hideUrl: hideUrl ?? this.hideUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      linkName: linkName ?? this.linkName,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      views: views ?? this.views,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    imageUrl,
    customTag,
    hideUrl,
    externalUrl,
    linkName,
    timestamp,
    userId,
    userName,
    userAvatar,
    views,
    isPinned,
  ];
}
