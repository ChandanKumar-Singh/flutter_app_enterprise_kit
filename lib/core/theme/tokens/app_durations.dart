class AppDurations {
  AppDurations._();
  static const instant    = Duration(milliseconds: 0);
  static const fast       = Duration(milliseconds: 150);
  static const normal     = Duration(milliseconds: 300);
  static const slow       = Duration(milliseconds: 500);
  static const xslow      = Duration(milliseconds: 800);
  static const pageEnter  = Duration(milliseconds: 350);
  static const pageExit   = Duration(milliseconds: 250);
  static const snackbar   = Duration(seconds: 4);
  static const toast      = Duration(seconds: 2);
  static const splash     = Duration(seconds: 2);
}
