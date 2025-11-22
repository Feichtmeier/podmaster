import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';

import '../common/media_type.dart';

class SearchManager {
  SearchManager() {
    textChangedCommand = Command.createSync((s) => s, initialValue: '');
  }

  late Command<String, String> textChangedCommand;
  final searchTypeNotifier = ValueNotifier<MediaType>(MediaType.podcast);
}
