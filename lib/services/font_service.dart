import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontService {
  static String currentFont = 'Quicksand';
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentFont = prefs.getString('app_font') ?? 'Quicksand';
  }

  static TextStyle getStyleForFont(String fontName, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
    
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: style);
      case 'Nunito':
        return GoogleFonts.nunito(textStyle: style);
      case 'Montserrat':
        return GoogleFonts.montserrat(textStyle: style);
      case 'Dancing Script':
        return GoogleFonts.dancingScript(textStyle: style);
      case 'Pacifico':
        return GoogleFonts.pacifico(textStyle: style);
      case 'Quicksand':
      default:
        return GoogleFonts.quicksand(textStyle: style);
    }
  }

  static TextStyle getStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return getStyleForFont(currentFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextTheme getTextTheme(TextTheme base) {
    switch (currentFont) {
      case 'Roboto':
        return GoogleFonts.robotoTextTheme(base);
      case 'Nunito':
        return GoogleFonts.nunitoTextTheme(base);
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme(base);
      case 'Dancing Script':
        return GoogleFonts.dancingScriptTextTheme(base);
      case 'Pacifico':
        return GoogleFonts.pacificoTextTheme(base);
      case 'Quicksand':
      default:
        return GoogleFonts.quicksandTextTheme(base);
    }
  }
}
