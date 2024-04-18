import 'package:cloud_firestore/cloud_firestore.dart';

class PostReplyData {
  String? postId;
  String? commentId;
  String? replyId;
  String? content;
  Timestamp? timestamp;
  String? authorUid;
  int? likeCount;
  int? dislikeCount;
  List<dynamic>? likers;
  List<dynamic>? dislikers;

  Map<String, dynamic>? data;

  PostReplyData({
    this.postId,
    this.commentId,
    this.replyId,
    this.content,
    this.timestamp,
    this.authorUid,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.likers = const [],
    this.dislikers = const [],
  }) {
    setData();
  }

  PostReplyData.fromJson(Map<String, dynamic> json) {
    postId = json['postId'];
    commentId = json['commentId'];
    replyId = json['replyId'];
    content = json['content'];
    timestamp = json['timestamp'];
    authorUid = json['authorUid'];
    likeCount = json['likeCount'];
    dislikeCount = json['dislikeCount'];
    likers = json['likers'] ?? [];
    dislikers = json['dislikers'] ?? [];
    setData();
  }

  void setData() {
    data = {
      'postId': postId,
      'commentId': commentId,
      'replyId': replyId,
      'content': content,
      'timestamp': timestamp,
      'authorUid': authorUid,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'likers': likers,
      'dislikers': dislikers,
    };
  }
}
