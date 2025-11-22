import 'package:flutter_it/flutter_it.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../common/media_type.dart';

class SearchManager {
  SearchManager() {
    textChangedCommand = Command.createSync((s) => s, initialValue: '');
  }

  late Command<String, String> textChangedCommand;
  final searchTypeNotifier = SafeValueNotifier<MediaType>(MediaType.podcast);
}
