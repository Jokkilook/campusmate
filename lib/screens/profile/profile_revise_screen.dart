import 'package:campusmate/models/user_data.dart';
import 'package:campusmate/modules/database.dart';
import 'package:campusmate/screens/main_screen.dart';
import 'package:campusmate/widgets/bottom_button.dart';
import 'package:campusmate/widgets/schedule_table.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//ignore: must_be_immutable
class ProfileReviseScreen extends StatelessWidget {
  ProfileReviseScreen({super.key});

  final db = DataBase();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  late final UserData modifiedData;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController introController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  late bool EI;
  late bool NS;
  late bool TF;
  late bool PJ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black,
        title: const Text('프로필 수정'),
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(const GetOptions(source: Source.cache)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                throw Error();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                return wholeProfile(UserData.fromJson(data), context);
              }
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomButton(
              text: "수정완료",
              isCompleted: true,
              onPressed: () {
                modifiedData.name = nameController.value.text;
                modifiedData.introduce = introController.value.text;
                var mbti = [];
                EI ? mbti.add("E") : mbti.add("I");
                NS ? mbti.add("N") : mbti.add("S");
                TF ? mbti.add("T") : mbti.add("F");
                PJ ? mbti.add("P") : mbti.add("J");
                modifiedData.mbti = "${mbti[0]}${mbti[1]}${mbti[2]}${mbti[3]}";
                db.addUser(modifiedData);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(index: 3),
                    ),
                    (route) => false);
              },
            ),
          )
        ],
      ),
    );
  }

  SingleChildScrollView wholeProfile(UserData userData, BuildContext context) {
    modifiedData = userData;
    introController.value = TextEditingValue(text: modifiedData.introduce!);
    nameController.value = TextEditingValue(text: modifiedData.name!);
    EI = userData.mbti![0] == "E";
    NS = userData.mbti![0] == "N";
    TF = userData.mbti![0] == "T";
    PJ = userData.mbti![0] == "P";

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 프로필 카드
            Container(
              clipBehavior: Clip.hardEdge,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 0),
                      blurRadius: 2)
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    color: Colors.amber,
                    height: 200,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //이름입력
                  IntrinsicWidth(
                    child: TextField(
                      maxLength: 20,
                      controller: nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // 자기소개
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '자기소개',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: introController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.6),
                                          width: 1.5,
                                        )),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.6),
                                          width: 1.5,
                                        )),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    hintText: "프로필에 표시될 소개를 적어보세요!",
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10)),
                              ),
                            ],
                          ),
                        ),
                        // 정보, 매너학점
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '내 정보',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                  '나이  ${DateTime.now().year - int.parse(modifiedData.birthDate!.split(".")[0])}'),
                              Text('성별  ${modifiedData.gender! ? "남" : "여"}'),
                              Text('학과  ${modifiedData.dept}'),
                            ],
                          ),
                        ),

                        //성향, 태그
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '성향',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              MBTISelector(
                                  parent: this, EI: EI, NS: NS, TF: TF, PJ: PJ),
                            ],
                          ),
                        ),
                        TagShower(parent: this),

                        //시간표
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Text(
                                  '시간표',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: ScheduleTable(
                                    scheduleData: modifiedData.schedule,
                                    readOnly: false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TagShower extends StatefulWidget {
  const TagShower({super.key, required this.parent});
  final ProfileReviseScreen parent;

  @override
  State<TagShower> createState() => _TagShowerState();
}

class _TagShowerState extends State<TagShower> {
  late List<String> userTag = widget.parent.modifiedData.tags!.cast<String>();
  var tagList = [
    "공부",
    "동네",
    "취미",
    "식사",
    "카풀",
    "술",
    "등하교",
    "시간 떼우기",
    "연애",
    "편입",
    "취업",
    "토익",
    "친분",
    "연상",
    "동갑",
    "연하",
    "선배",
    "동기",
    "후배"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '태그',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '  ${userTag.length}/8',
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            children: [
              for (var tag in tagList)
                OutlinedButton(
                  onPressed: () {
                    if (userTag.contains(tag)) {
                      //유저 태그 리스트에 태그가 있으면 삭제
                      userTag.remove(tag);
                    } else if (userTag.length < 8) {
                      //유저 태그 리스트에 태그가 없고 리스트가 8개를 넘지 않으면 추가
                      userTag.add(tag);
                    }

                    setState(() {});
                  },
                  child: Text(
                    tag,
                    style: TextStyle(
                        color: userTag.contains(tag)
                            ? const Color(0xff0B351E)
                            : Colors.black54),
                  ),
                  style: OutlinedButton.styleFrom(
                      side: userTag.contains(tag)
                          ? BorderSide(width: 2, color: Colors.green[400]!)
                          : BorderSide(
                              width: 0, color: Colors.white.withOpacity(0)),
                      backgroundColor: userTag.contains(tag)
                          ? Colors.green[400]
                          : Colors.grey[200],
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

//ignore: must_be_immutable
class MBTISelector extends StatefulWidget {
  MBTISelector(
      {super.key,
      required this.parent,
      this.EI = true,
      this.NS = true,
      this.TF = true,
      this.PJ = true});

  bool EI; //true = E, false = I
  bool NS; //true = N, false = S
  bool TF; //true = T, false = F
  bool PJ; //true = P, false = J
  final ProfileReviseScreen parent;

  @override
  State<MBTISelector> createState() => _MBTISelectorState();
}

class _MBTISelectorState extends State<MBTISelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          children: [],
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.EI = true;
              widget.parent.EI = widget.EI;
              setState(() {});
            },
            child: Text(
              "E",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: widget.EI ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor:
                  widget.EI ? const Color(0xFF2BB56B) : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10))),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.EI = false;
              widget.parent.EI = widget.EI;
              setState(() {});
            },
            child: Text(
              "I",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: !widget.EI ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor: !widget.EI
                  ? const Color(0xFF2BB56B)
                  : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.NS = true;
              widget.parent.NS = widget.NS;
              setState(() {});
            },
            child: Text(
              "N",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: widget.NS ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor:
                  widget.NS ? const Color(0xFF2BB56B) : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10))),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.NS = false;
              widget.parent.NS = widget.NS;
              setState(() {});
            },
            child: Text(
              "S",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: !widget.NS ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor: !widget.NS
                  ? const Color(0xFF2BB56B)
                  : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.TF = true;
              widget.parent.TF = widget.TF;
              setState(() {});
            },
            child: Text(
              "T",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: widget.TF ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor:
                  widget.TF ? const Color(0xFF2BB56B) : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10))),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.TF = false;
              widget.parent.TF = widget.TF;
              setState(() {});
            },
            child: Text(
              "F",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: !widget.TF ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor: !widget.TF
                  ? const Color(0xFF2BB56B)
                  : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.PJ = true;
              widget.parent.PJ = widget.PJ;
              setState(() {});
            },
            child: Text(
              "P",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: widget.PJ ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor:
                  widget.PJ ? const Color(0xFF2BB56B) : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10))),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              widget.PJ = false;
              widget.parent.PJ = widget.PJ;
              setState(() {});
            },
            child: Text(
              "J",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: !widget.PJ ? const Color(0xFF0A351E) : Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              backgroundColor: !widget.PJ
                  ? const Color(0xFF2BB56B)
                  : const Color(0xFFE3DFE3),
              minimumSize: const Size(50, 60),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
            ),
          ),
        ),
      ],
    );
  }
}
