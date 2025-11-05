import 'package:flutter/foundation.dart';

void printMessageInDebugMode(
  Object? object, [
  StackTrace? stack,
  String tag = '',
]) {
  if (kDebugMode) {
    final message = object.toString();
    debugPrint(tag.isNotEmpty ? '[$tag] $message' : message);
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
  }
}
