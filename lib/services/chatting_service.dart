import 'dart:io';
import 'package:campusmate/Theme/app_colors.dart';
import 'package:campusmate/models/chat_room_data.dart';
import 'package:campusmate/models/group_chat_room_data.dart';
import 'package:campusmate/models/message_data.dart';
import 'package:campusmate/models/user_data.dart';
import 'package:campusmate/modules/enums.dart';
import 'package:campusmate/provider/user_data_provider.dart';
import 'package:campusmate/router/app_router.dart';
import 'package:campusmate/widgets/yest_no_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';

class ChattingService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage firestorage = FirebaseStorage.instance;

  ///1:1채팅방 ID 생성
  String makeOTORoomId(String ownerUID, String targetUID) {
    //문자열 순서에 따라 정렬한 후 '_'로 연결 (누가 먼저 시작해도 정렬 후 생성하기 때문에 중복되지 않음)
    List<String> list = [ownerUID, targetUID];
    list.sort();
    String roomId = list.join("_");
    return roomId;
  }

  ///그룹 채팅방 ID 생성
  String makeGroupRoomId(String ownerUID) {
    String roomId =
        [ownerUID, Timestamp.now().millisecondsSinceEpoch].join("_");
    return roomId;
  }

  ///1:1 채팅시작
  void startChatting(
      BuildContext context, String ownerUID, String targetUID) async {
    UserData userData = context.read<UserDataProvider>().userData;
    //1:1 채팅방ID 구하기
    String roomId = makeOTORoomId(ownerUID, targetUID);
    //원래 채팅방이 있는지 조회
    await firestore
        .collection("schools/${userData.school}/chats")
        .doc(roomId)
        .get()
        .then((value) {
      //채팅방이 있으면 그 채팅방으로 화면 이동
      if (value.exists) {
        var json = value.data() as Map<String, dynamic>;
        ChatRoomData data = ChatRoomData.fromJson(json);

        //이미 있는 채팅방 참여자에 UID가 없으면 추가
        if (!data.participantsUid!.contains(ownerUID)) {
          data.participantsUid!.add(ownerUID);
          firestore
              .collection("schools/${userData.school}/chats")
              .doc(roomId)
              .update({"participantsUid": data.participantsUid});

          //방 입장 정보 기록 (메세지에 기록해서 채팅방에 뜨도록)
          sendMessage(
            isGroup: false,
            userData: userData,
            roomId: roomId,
            data: MessageData(
                type: MessageType.notice,
                senderUID: userData.uid,
                content: "enter",
                readers: [],
                time: Timestamp.now()),
          );
        }

        //채팅방 입장
        enterRoom(context, data);
        return;
      } else {
        //기존 채팅방이 없으면 생성
        createOTORoom(context, targetUID);
        return;
      }
    });
  }

  ///1:1 채팅방 생성
  void createOTORoom(BuildContext context, String targetUID) async {
    UserData userData = context.read<UserDataProvider>().userData;
    //1:1 채팅방ID 구하기
    String roomId = makeOTORoomId(userData.uid!, targetUID);

    //채팅방 데이터 설정
    var data = await getUserProfile(context, targetUID);
    var doc = data.data() as Map<String, dynamic>;
    String targetName = doc["name"];
    String targetImageUrl = doc["imageUrl"];
    List<String> inputData = [targetName, targetImageUrl];

    ChatRoomData roomData = ChatRoomData(
        roomId: roomId,
        roomName: "새로운 채팅방",
        leavingTime: {
          targetUID: Timestamp.fromDate(DateTime.now()),
          userData.uid!: Timestamp.fromDate(DateTime.now())
        },
        participantsInfo: {
          userData.uid!: [userData.name!, userData.imageUrl!],
          targetUID: inputData
        },
        participantsUid: [userData.uid!, targetUID],
        lastMessage: "");

    //파이어스토어에 채팅방 데이터 추가
    await firestore
        .collection("schools/${userData.school}/chats")
        .doc(roomId)
        .set(roomData.toJson());

    //설정된 데이터로 채팅방 입장
    enterRoom(context, roomData);
  }

  ///1:1 채팅방 입장
  void enterRoom(BuildContext context, ChatRoomData data) {
    //채팅방 화면으로 이동
    context.pushNamed(Screen.chatRoom,
        pathParameters: {"isGroup": "one"}, extra: data);
  }

  ///그룹 채팅방 생성
  Future createGroupRoom(
      {BuildContext? context,
      String? roomName,
      String? desc,
      int? limit}) async {
    UserData userData = context!.read<UserDataProvider>().userData;
    //단체 채팅방ID 구하기
    String roomId = makeGroupRoomId(userData.uid!);

    //채팅방 데이터 설정
    GroupChatRoomData roomData = GroupChatRoomData(
        roomId: roomId,
        roomName: roomName,
        creatorUid: userData.uid,
        description: desc,
        limit: limit,
        createdTime: Timestamp.fromDate(DateTime.now()),
        leavingTime: {userData.uid!: Timestamp.fromDate(DateTime.now())},
        participantsInfo: {
          userData.uid!: [userData.name!, userData.imageUrl!],
        },
        participantsUid: [userData.uid!],
        lastMessage: "새로운 채팅방이 생성되었습니다!",
        lastMessageTime: Timestamp.now());

    //파이어스토어에 채팅방 데이터 추가
    await firestore
        .collection("schools/${userData.school}/groupChats")
        .doc(roomId)
        .set(roomData.toJson());

    enterGroupRoom(context, roomData);
  }

  ///그룹 채팅방 입장
  void enterGroupRoom(BuildContext context, GroupChatRoomData data) async {
    UserData userData = context.read<UserDataProvider>().userData;

    //채팅방 참여자 UID 리스트에 없는지 확인 없으면 입장 조건 확인
    if (!data.participantsUid!.contains(userData.uid!)) {
      List<String> updatedUIDList = data.participantsUid!;
      updatedUIDList.add(userData.uid!);
      Map<String, List<String>> updatedInfo = data.participantsInfo!;
      updatedInfo[userData.uid!] = [userData.name!, userData.imageUrl!];

      //입장 시도 시점에서의 그룹 채팅방 데이터 로딩
      //그룹 채팅은 유저가 항상 입/퇴장 하기 때문에 입장 전 데이터 로딩
      var checkData = await firestore
          .collection("schools/${userData.school}/groupChats")
          .doc(data.roomId)
          .get();

      //참여인원이 꽉찼으면 return
      if (checkData["limit"] == (checkData["participantsUid"] as List).length) {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: IntrinsicHeight(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "입장 인원이 꽉 찼어요!",
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTitle
                                    : AppColors.lightTitle,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                          onPressed: () async {
                            context.pop();
                          },
                          child: const Text("확인"))
                    ],
                  ),
                ),
              ),
            );
          },
        );

        return;
      }

      //참여자 UID 리스트와 프로필 정보 업데이트
      await firestore
          .collection("schools/${userData.school}/groupChats")
          .doc(data.roomId)
          .update({
        "participantsUid": updatedUIDList,
        "participantsInfo": updatedInfo,
      });

      //방 입장 정보 기록 (메세지에 기록해서 채팅방에 뜨도록)
      sendMessage(
        isGroup: true,
        userData: userData,
        roomId: data.roomId!,
        data: MessageData(
            type: MessageType.notice,
            senderUID: userData.uid,
            content: "enter",
            readers: [],
            time: Timestamp.now()),
      );
    }

    //채팅방 화면으로 이동
    context.pushNamed(Screen.chatRoom,
        pathParameters: {"isGroup": "group"}, extra: data);
  }

  ///채팅방 화면 나갔을 때 시간 기록
  Future recordLeavingTime(UserData userData, String roomId,
      {bool isGroup = false}) async {
    await firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
        .doc(roomId)
        .set({
      "leavingTime": {userData.uid: Timestamp.fromDate(DateTime.now())}
    }, SetOptions(merge: true));
  }

  ///채팅방 삭제
  Future deleteChatRoom(
      {required UserData userData,
      required String roomId,
      bool isGroup = false}) async {
    //파이어스토어에서 채팅방 데이터 불러오기
    //roomId 방 도큐먼트 참조
    var roomRef = firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
        .doc(roomId);
    //메세지 데이터 콜렉션 참조
    var messageRef = firestore.collection(
        "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/messages");

    //roomId 방 도큐먼트 삭제
    await roomRef.delete();

    //콜렉션 통째로 삭제가 안돼서 메세지 데이터 하나하나 삭제함
    messageRef.get().then((value) async {
      for (var doc in value.docs) {
        await doc.reference.delete();
      }
    });

    //파이어 스토어의 데이터 삭제 (이것도 한번에 삭제가 안돼서 하나하나 조회하고 삭제함)
    var imageRef = firestorage.ref().child(
        "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/images");
    var videoRef = firestorage.ref().child(
        "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/videos");
    var thumbRef = firestorage.ref().child(
        "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/thumbnails");

    ListResult imageResult = await imageRef.listAll();
    ListResult videoResult = await videoRef.listAll();
    ListResult thumbResult = await thumbRef.listAll();

    for (Reference ref in imageResult.items) {
      ref.delete();
    }

    for (Reference ref in videoResult.items) {
      ref.delete();
    }

    for (Reference ref in thumbResult.items) {
      ref.delete();
    }
  }

  ///그룹 채팅방 나가기
  void leaveGroupChatRoom(
      {BuildContext? context,
      required UserData userData,
      required String roomId,
      bool onList = false}) async {
    //파이어스토어에서 채팅방 데이터 불러오기
    var roomRef = firestore
        .collection("schools/${userData.school}/groupChats")
        .doc(roomId);
    //그룹채팅방 데이터 반환
    DocumentSnapshot<Map<String, dynamic>> data = await roomRef.get();
    GroupChatRoomData roomData =
        GroupChatRoomData.fromJson(data.data() as Map<String, dynamic>);

    //방장이 나가는 경우 context가 있을 시 다이얼로그 보여주고 방 삭제
    if (roomData.creatorUid == userData.uid) {
      if (context != null) {
        showDialog(
          context: context,
          builder: (_) {
            return YesNoDialog(
                content: "방장으로 있는 채팅방을 나가면 모든 참여자를 내보내고 채팅방을 삭제합니다.",
                onYes: () {
                  onList ? null : context.pop();
                  context.pop();
                  deleteChatRoom(
                      userData: userData, roomId: roomId, isGroup: true);
                });
          },
        );
      } else {
        deleteChatRoom(userData: userData, roomId: roomId, isGroup: true);
      }
    } else {
      //방 나간 정보 기록 (메세지에 기록해서 채팅방에 뜨도록)
      sendMessage(
        isGroup: true,
        userData: userData,
        roomId: roomId,
        data: MessageData(
            type: MessageType.notice,
            senderUID: userData.uid,
            content: "left",
            readers: [],
            time: Timestamp.now()),
      );

      //채팅방 참여자 목록에서 UID 제거하고 조건에 따라 파이어베이스에 업데이트

      //참여자 리스트 반환
      List participantsList = roomData.participantsUid ?? [];

      //참여자 리스트에서 UID 삭제
      participantsList.remove(userData.uid);

      //파이어베이스 참여자 리스트 업데이트
      firestore
          .collection("schools/${userData.school}/groupChats")
          .doc(roomId)
          .update({"participantsUid": participantsList});

      //참여자 유저 정보 map에서 삭제
      roomData.participantsInfo?.remove(userData.uid);
      firestore
          .collection("schools/${userData.school}/groupChats")
          .doc(roomId)
          .update({"participantsInfo": roomData.participantsInfo});

      //context가 입력되면 화면 나가기
      if (context != null) {
        context.pop();
      }
    }
  }

  ///채팅방 나가기
  void leaveOTOChatRoom({
    BuildContext? context,
    required UserData userData,
    required String roomId,
  }) async {
    //파이어스토어에서 채팅방 데이터 불러오기
    var roomRef =
        firestore.collection("schools/${userData.school}/chats").doc(roomId);

    DocumentSnapshot<Map<String, dynamic>> data = await roomRef.get();
    ChatRoomData roomData =
        ChatRoomData.fromJson(data.data() as Map<String, dynamic>);

    //방 나간 정보 기록 (메세지에 기록해서 채팅방에 뜨도록)
    sendMessage(
      isGroup: false,
      userData: userData,
      roomId: roomId,
      data: MessageData(
          type: MessageType.notice,
          senderUID: userData.uid,
          content: "left",
          readers: [],
          time: Timestamp.now()),
    );

    //채팅방 참여자 목록에서 UID 제거하기
    List participantsList = roomData.participantsUid ?? [];
    participantsList.remove(userData.uid);

    //나간 후 남은 참여자가 1명이면 방 데이터 모두 삭제 후 화면 나가기
    if (participantsList.length == 1) {
      //context가 입력되면 화면 나가기
      if (context != null) {
        context.pop();
      }
      //방 데이터 삭제
      deleteChatRoom(userData: userData, roomId: roomId, isGroup: false);
    } else {
      //나간 후 남은 참여자가 1명 이상이면 참여자 명단에서 내 UID만 쏙 지운 리스트를 파이어스토어에 업데이트 하고 화면 나가기
      roomRef.update({"participantsUid": participantsList}).whenComplete(() {
        if (context != null) {
          context.pop();
        }
      });
    }
  }

  ///사용자가 참여한 채팅방 데이터 스트림 리스트 반환
  Stream<QuerySnapshot<Object>> getChattingRoomListStream(BuildContext context,
      {bool isGroup = false}) {
    UserData userData = context.read<UserDataProvider>().userData;
    return firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
        .where("participantsUid", arrayContains: userData.uid)
        .snapshots();
  }

  ///사용자가 참여한 채팅방 데이터 쿼리스냅샷 리스트 반환
  Future<QuerySnapshot<Map<String, dynamic>>> getChattingRoomListQuerySnapshot(
      UserData userData,
      {bool isGroup = false}) async {
    return await firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
        .where("participantsUid", arrayContains: userData.uid)
        .get();
  }

  ///채팅방 데이터 스트림 반환
  Stream<DocumentSnapshot<Object>> getChatRoomDataStream(
      UserData userData, String roomId,
      {bool isGroup = false}) {
    return firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
        .doc(roomId)
        .snapshots();
  }

  ///채팅방의 메세지 데이터 스트림 반환
  Stream<QuerySnapshot<Object>> getChattingMessagesStream(BuildContext context,
      {String roomId = "", bool isGroup = false}) {
    UserData userData = context.read<UserDataProvider>().userData;
    return firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/messages")
        .orderBy("time", descending: true)
        .snapshots();
  }

  ///메세지 데이터 읽은 사람 갱신
  void updateReader(BuildContext context, String roomId, String messageId,
      List<String> readerList,
      {bool isGroup = false}) async {
    UserData userData = context.read<UserDataProvider>().userData;
    firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/messages")
        .doc(messageId)
        .update({"readers": readerList});
  }

  ///사용자 정보 반환
  Future<DocumentSnapshot<Object>> getUserProfile(
      BuildContext context, String uid) async {
    UserData userData = context.read<UserDataProvider>().userData;
    return firestore
        .collection("schools/${userData.school}/users")
        .doc(uid)
        .get();
  }

  ///메세지 보내기
  Future<void> sendMessage(
      {required UserData userData,
      required String roomId,
      required MessageData data,
      bool isGroup = false}) async {
    await firestore
        .collection(
            "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/$roomId/messages")
        .doc("${DateTime.now().millisecondsSinceEpoch}_${userData.uid}")
        .set(data.toJson())
        .whenComplete(() async {
      //알림(인원 출입)메세지가 아니면 마지막 메세지 기록
      if (data.type != MessageType.notice) {
        var lastMessage = "";

        switch (data.type) {
          case MessageType.text:
            lastMessage = data.content!;
            break;
          case MessageType.picture:
            lastMessage = "사진";
            break;
          case MessageType.video:
            lastMessage = "동영상";
            break;
          default:
            lastMessage = data.content!;
            break;
        }

        await firestore
            .collection(
                "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}")
            .doc(roomId)
            .update({"lastMessage": lastMessage, "lastMessageTime": data.time});
      }
    });
  }

  ///미디어파일 보내기
  Future<void> sendMedia(
      {required UserData userData,
      required ChatRoomData roomData,
      required MessageData messageData,
      required XFile media,
      bool isGroup = false,
      File? thumbnail}) async {
    String thumbUrl = "";
    String url = "";
    XFile? compMedia;

    //이미지면 이미지 압축, 비디오면 비디오 압축
    if (messageData.type == MessageType.picture) {
      //이미지 압축
      compMedia = await FlutterImageCompress.compressAndGetFile(
          media.path, "${media.path}.jpg");
      //파이어스토어에 올리고 url 가져오기
      var ref = firestorage.ref().child(
          "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/${roomData.roomId}/images/${messageData.time!.millisecondsSinceEpoch}-${roomData.roomId}.jpg");
      await ref.putFile(File(compMedia!.path)).whenComplete(() async {
        url = await ref.getDownloadURL();
      });
    }
    if (messageData.type == MessageType.video) {
      //동영상 썸네일 확보 후 파이어스토어에 업로드 후 url 가져오기
      XFile? compThumbnail = await FlutterImageCompress.compressAndGetFile(
          thumbnail!.path, "${thumbnail.path}.jpg");

      var thumbRef = firestorage.ref().child(
          "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/${roomData.roomId}/thumbnails/${messageData.time!.millisecondsSinceEpoch}-${roomData.roomId}-thumbnail-.jpg");
      await thumbRef.putFile(File(compThumbnail!.path)).whenComplete(() async {
        thumbUrl = await thumbRef.getDownloadURL();
      });
      //동영상 압축
      var mediaInfo = await VideoCompress.compressVideo(
        media.path,
        quality: VideoQuality.DefaultQuality,
      );

      //파이어스토어에 올리고 url 가져오기
      var ref = firestorage.ref().child(
          "schools/${userData.school}/${isGroup ? "groupChats" : "chats"}/${roomData.roomId}/videos/${messageData.time!.millisecondsSinceEpoch}-${roomData.roomId}.mp4");
      await ref.putFile(mediaInfo!.file!).whenComplete(() async {
        url = await ref.getDownloadURL();
      });
    }

    thumbUrl.isEmpty
        ? messageData.content = url
        : messageData.content = [thumbUrl, url].join(":-:");

    messageData.time = Timestamp.now();

    sendMessage(
        isGroup: isGroup,
        userData: userData,
        roomId: roomData.roomId!,
        data: messageData);
  }
}
