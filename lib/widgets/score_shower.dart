import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class Score extends StatelessWidget {
  const Score({super.key, this.score = ""});

  final String score;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: Colors.black87, borderRadius: BorderRadius.circular(100)),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(100)),
        ),
        AutoSizeText(
          score,
          style: const TextStyle(
              fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
