import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';

import '../common/media_type.dart';

class CollectionManager {
  CollectionManager() {
    textChangedCommand = Command.createSync((s) => s, initialValue: '');
  }
  final mediaTypeNotifier = ValueNotifier<MediaType>(MediaType.podcast);
  final showOnlyDownloadsNotifier = ValueNotifier<bool>(false);

  late Command<String, String> textChangedCommand;
}
