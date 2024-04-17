import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../modules/format_time_stamp.dart';
import '../../provider/user_data_provider.dart';
import '../../models/post_data.dart';
import '../../widgets/community/comment_item.dart';
import '../../widgets/community/comment_reply_item.dart';
import '../../widgets/community/post_controller.dart';

class PostScreen extends StatefulWidget {
  PostData postData;
  final FirebaseFirestore firestore;

  PostScreen({
    Key? key,
    required this.postData,
    required this.firestore,
  }) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  bool _isLoading = false;
  bool _userAlreadyViewed = false;

  @override
  void initState() {
    super.initState();
    checkUserViewedPost();
    _refreshScreen();
  }

  Future<void> checkUserViewedPost() async {
    String currentUserUid = context.read<UserDataProvider>().userData.uid ?? '';
    debugPrint('currentUserUid: $currentUserUid');
    setState(() {
      _userAlreadyViewed =
          widget.postData.viewers?.contains(currentUserUid) ?? false;
    });
    if (!_userAlreadyViewed) {
      await updateViewCount(currentUserUid);
    }
  }

  // 조회수
  Future<void> updateViewCount(String currentUserUid) async {
    try {
      if (widget.postData.viewers == null ||
          !widget.postData.viewers!.contains(currentUserUid)) {
        await FirebaseFirestore.instance
            .collection(widget.postData.boardType == 'General'
                ? 'generalPosts'
                : 'anonymousPosts')
            .doc(widget.postData.postId)
            .update({
          'viewers': FieldValue.arrayUnion([currentUserUid]),
          'viewCount': FieldValue.increment(1),
        });
        debugPrint('조회수 업데이트 성공');

        setState(() {
          widget.postData.viewers ??= [];
          widget.postData.viewers!.add(currentUserUid);
          widget.postData.viewCount = (widget.postData.viewCount ?? 0) + 1;
        });
      } else {
        debugPrint('이미 조회한 사용자입니다.');
      }
    } catch (error) {
      debugPrint('조회수 업데이트 에러: $error');
    }
  }

  // 좋아요, 싫어요
  Future<void> toggleLikeDislike(bool isLike) async {
    String currentUserUid = context.read<UserDataProvider>().userData.uid ?? '';
    bool userLiked = widget.postData.likers!.contains(currentUserUid);
    bool userDisliked = widget.postData.dislikers!.contains(currentUserUid);

    if (isLike) {
      if (userLiked) {
        await FirebaseFirestore.instance
            .collection(widget.postData.boardType == 'General'
                ? 'generalPosts'
                : 'anonymousPosts')
            .doc(widget.postData.postId)
            .update({
          'likers': FieldValue.arrayRemove([currentUserUid]),
          'likeCount': FieldValue.increment(-1),
        });
        setState(() {
          widget.postData.likers!.remove(currentUserUid);
          widget.postData.likeCount = (widget.postData.likeCount ?? 0) - 1;
        });
      } else {
        if (userDisliked) {
          await FirebaseFirestore.instance
              .collection(widget.postData.boardType == 'General'
                  ? 'generalPosts'
                  : 'anonymousPosts')
              .doc(widget.postData.postId)
              .update({
            'dislikers': FieldValue.arrayRemove([currentUserUid]),
            'dislikeCount': FieldValue.increment(-1),
          });
          setState(() {
            widget.postData.dislikers!.remove(currentUserUid);
            widget.postData.dislikeCount =
                (widget.postData.dislikeCount ?? 0) - 1;
          });
        }
        await FirebaseFirestore.instance
            .collection(widget.postData.boardType == 'General'
                ? 'generalPosts'
                : 'anonymousPosts')
            .doc(widget.postData.postId)
            .update({
          'likers': FieldValue.arrayUnion([currentUserUid]),
          'likeCount': FieldValue.increment(1),
        });
        setState(() {
          widget.postData.likers!.add(currentUserUid);
          widget.postData.likeCount = (widget.postData.likeCount ?? 0) + 1;
        });
      }
    } else {
      if (userDisliked) {
        await FirebaseFirestore.instance
            .collection(widget.postData.boardType == 'General'
                ? 'generalPosts'
                : 'anonymousPosts')
            .doc(widget.postData.postId)
            .update({
          'dislikers': FieldValue.arrayRemove([currentUserUid]),
          'dislikeCount': FieldValue.increment(-1),
        });
        setState(() {
          widget.postData.dislikers!.remove(currentUserUid);
          widget.postData.dislikeCount =
              (widget.postData.dislikeCount ?? 0) - 1;
        });
      } else {
        if (userLiked) {
          await FirebaseFirestore.instance
              .collection(widget.postData.boardType == 'General'
                  ? 'generalPosts'
                  : 'anonymousPosts')
              .doc(widget.postData.postId)
              .update({
            'likers': FieldValue.arrayRemove([currentUserUid]),
            'likeCount': FieldValue.increment(-1),
          });
          setState(() {
            widget.postData.likers!.remove(currentUserUid);
            widget.postData.likeCount = (widget.postData.likeCount ?? 0) - 1;
          });
        }
        await FirebaseFirestore.instance
            .collection(widget.postData.boardType == 'General'
                ? 'generalPosts'
                : 'anonymousPosts')
            .doc(widget.postData.postId)
            .update({
          'dislikers': FieldValue.arrayUnion([currentUserUid]),
          'dislikeCount': FieldValue.increment(1),
        });
        setState(() {
          widget.postData.dislikers!.add(currentUserUid);
          widget.postData.dislikeCount =
              (widget.postData.dislikeCount ?? 0) + 1;
        });
      }
    }
  }

  // 새로고침
  Future<void> _refreshScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 데이터 다시 가져오기
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection(widget.postData.boardType == 'General'
              ? 'generalPosts'
              : 'anonymousPosts')
          .doc(widget.postData.postId)
          .get();

      // 새로운 postData로 상태 업데이트
      setState(() {
        widget.postData =
            PostData.fromJson(postSnapshot.data() as Map<String, dynamic>);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('데이터 가져오기 에러: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedTime = formatTimeStamp(widget.postData.timestamp!, now);

    bool userLiked = widget.postData.likers!
        .contains(context.read<UserDataProvider>().userData.uid);
    bool userDisliked = widget.postData.dislikers!
        .contains(context.read<UserDataProvider>().userData.uid);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black,
        title: Text(
          widget.postData.boardType == 'General' ? '일반 게시판' : '익명 게시판',
        ),
        actions: [
          IconButton(
            onPressed: () {
              _refreshScreen();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  String currentUserUid =
                      context.read<UserDataProvider>().userData.uid ?? '';
                  return PostController(
                    currentUserUid: currentUserUid,
                    postData: widget.postData,
                  );
                },
              ).then((_) {
                _refreshScreen();
              });
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshScreen,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.postData.title ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 작성자 닉네임 가져오기
                      FutureBuilder<DocumentSnapshot>(
                        future: widget.firestore
                            .collection('users')
                            .doc(widget.postData.authorUid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
                            return const Text('No Data');
                          }

                          // 문서에서 사용자 이름 가져오기
                          String authorName = snapshot.data!['name'];

                          return Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.postData.boardType == 'General'
                                    ? authorName
                                    : '익명',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.postData.viewCount.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.postData.content ?? '',
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  userLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_alt_outlined,
                                  size: 20,
                                  color: userLiked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () {
                                  toggleLikeDislike(true);
                                },
                              ),
                              Text(
                                widget.postData.likeCount?.toString() ?? '0',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: Icon(
                                  userDisliked
                                      ? Icons.thumb_down
                                      : Icons.thumb_down_outlined,
                                  size: 20,
                                  color:
                                      userDisliked ? Colors.blue : Colors.grey,
                                ),
                                onPressed: () {
                                  toggleLikeDislike(false);
                                },
                              ),
                              Text(
                                widget.postData.dislikeCount?.toString() ?? '0',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '댓글 ${widget.postData.commentCount ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const CommentItem(),
                      const CommentReplyItem(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
