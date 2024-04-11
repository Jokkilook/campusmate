import 'package:campusmate/firebase_options.dart';
import 'package:campusmate/models/user_data.dart';
import 'package:campusmate/provider/chatting_data_provider.dart';
import 'package:campusmate/provider/user_data_provider.dart';
import 'package:campusmate/screens/login_screen.dart';
import 'package:campusmate/screens/screen_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class SplashLoadingScreen extends StatefulWidget {
  const SplashLoadingScreen({super.key});

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  void getChattingInitData() async {}

  void initialize() async {
    String uid = "";
    User user;

    //광고 로드
    await MobileAds.instance.initialize();

    try {
      //파이어베이스 연결
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false);
        return;
      } else {
        user = FirebaseAuth.instance.currentUser!;
        uid = user.uid;
      }

      //채팅데이터프로바이더에 채팅리스트 스트림 로드
      context.read<ChattingDataProvider>().chatListStream = FirebaseFirestore
          .instance
          .collection("chats")
          .where("participantsUid",
              arrayContains: context.read<UserDataProvider>().userData.uid)
          .snapshots();

      var snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      var data = snapshot.data() as Map<String, dynamic>;
      var userData = UserData.fromJson(data);
      context.read<UserDataProvider>().userData = userData;
    } catch (e) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false);
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>$e");
    }
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ScreenList()),
        (route) => false);
  }
}
