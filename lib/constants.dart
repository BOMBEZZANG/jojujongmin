import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFF8E9AAF);
const Color favoriteColor = Color(0xFFEC4899);

Color getPrimaryColor(bool isDarkMode) {
  return isDarkMode ? Color(0xFF8E9AAF) : Color(0xFF4A90E2);
}

final Map<int, String> reverseRoundMapping = {
  1: '2016년 7월',
  2: '2016년 4월',
  3: '2016년 1월',
  4: '2015년 10월',
  5: '2015년 7월',
  6: '2015년 4월',
  7: '2015년 1월',
  8: '2014년 10월',
  9: '2014년 7월',
  10: '2014년 4월',
  11: '2014년 1월',
  12: '2013년 10월',
};


String examSessionToRoundName(dynamic examVal) {
  int? intVal = (examVal is int) ? examVal : int.tryParse(examVal.toString());
  return reverseRoundMapping[intVal] ?? '기타';
}


final List<String> categories = [
  '주류학개론',
  '주장관리개론',
  '고객서비스영어'
];