import 'package:cloud_firestore/cloud_firestore.dart';

class PostData {
  String? boardType;
  String? title;
  String? content;
  Timestamp? timestamp;
  String? author;
  String? authorUid;
  String? postId;
  int? viewCount;
  int? likeCount;
  int? dislikeCount;
  int? commentCount;
  List<dynamic>? viewers;
  List<dynamic>? likers;
  List<dynamic>? dislikers;

  Map<String, dynamic>? data;

  PostData({
    this.boardType = 'General',
    this.title,
    this.content,
    this.timestamp,
    this.authorUid,
    this.postId,
    this.viewCount = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.viewers = const [],
    this.likers = const [],
    this.dislikers = const [],
  }) {
    setData();
  }

  PostData.fromJson(Map<String, dynamic> json) {
    boardType = json['boardType'];
    title = json['title'];
    content = json['content'];
    timestamp = json['timestamp'];
    author = json['author'];
    authorUid = json['authorUid'];
    postId = json['postId'];
    viewCount = json['viewCount'];
    likeCount = json['likeCount'];
    dislikeCount = json['dislikeCount'];
    commentCount = json['commentCount'];
    viewers = json['viewers'] ?? [];
    likers = json['likers'] ?? [];
    dislikers = json['dislikers'] ?? [];

    setData();
  }

  void setData() {
    data = {
      'boardType': boardType,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'author': author,
      'authorUid': authorUid,
      'postId': postId,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'commentCount': commentCount,
      'viewers': viewers,
      'likers': likers,
      'dislikers': dislikers,
    };
  }
}
