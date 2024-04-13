import 'package:campusmate/screens/profile/stranger_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble(
      {super.key,
      required this.messageData,
      this.index = 0,
      this.showTime = false,
      this.showDay = true,
      this.isOther = false,
      this.viewSender = true,
      this.name,
      this.senderUid,
      this.imageUrl});

  final QueryDocumentSnapshot messageData;
  final int index;
  final bool showTime;
  final bool showDay;
  final bool isOther;
  final bool viewSender;
  final String? name;
  final String? senderUid;
  final String? imageUrl;

  String timeStampToHourMinutes(Timestamp time) {
    var data = time.toDate().toString();
    var date = DateTime.parse(data);

    return "${NumberFormat("00").format(date.hour)}:${NumberFormat("00").format(date.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        showDay
            ? Stack(alignment: Alignment.center, children: [
                const Divider(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.grey[50]),
                  child: Text(
                    DateFormat("yyyy년 M월 dd일")
                        .format((messageData["time"] as Timestamp).toDate())
                        .toString(),
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              ])
            : Container(),
        Align(
          //내 채팅버블이면 오른쪽 정렬, 상대버블이면 왼쪽 정렬
          alignment: isOther ? Alignment.centerLeft : Alignment.centerRight,
          child: Row(
            mainAxisAlignment:
                //내 채팅버블이면 오른쪽 정렬, 상대버블이면 왼쪽 정렬
                isOther ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment:
                    //내 채팅버블이면 아래쪽, 상대버블이면 위쪽으로 정렬해서 프로필 사진이 위로 올라가게 한다
                    isOther ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  //프로필을 보여줘야하고 상대방일 때 사진 표시
                  viewSender && isOther
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StrangerProfilScreen(uid: senderUid ?? ""),
                              ),
                            );
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            width: 50,
                            height: 50,
                            child: Image.network(
                                imageUrl ??
                                    "https://firebasestorage.googleapis.com/v0/b/classmate-81447.appspot.com/o/images%2Ftest.png?alt=media&token=4a231bcd-04fa-4220-9914-1028783f5f35",
                                fit: BoxFit.cover),
                          ),
                        )
                      : Container(
                          width: 50,
                        ),
                  const SizedBox(width: 10),
                  //왼쪽 시간표시 (시간을 보여줘야하고 내 버블일 때)
                  showTime && !isOther
                      ? Text(timeStampToHourMinutes(messageData["time"]),
                          style: const TextStyle(fontSize: 10))
                      : Container(),
                  isOther ? Container() : const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //프로필을 보여줘야 하고 상대방일 때 이름표시
                      viewSender && isOther ? Text(name ?? "") : Container(),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.65),
                        decoration: BoxDecoration(
                            color:
                                //상대 채팅버블이면 회색, 내 채팅버블이면 초록
                                isOther ? Colors.grey[200] : Colors.green[400],
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageData["content"],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              //오른쪽 시간표시 (시간을 보여줘야하고 상대방 버블일 때)
              isOther ? const SizedBox(width: 6) : Container(),
              showTime && isOther
                  ? Text(timeStampToHourMinutes(messageData["time"]),
                      style: const TextStyle(fontSize: 10))
                  : Container(),
            ],
          ),
        ),
      ],
    );
  }
}