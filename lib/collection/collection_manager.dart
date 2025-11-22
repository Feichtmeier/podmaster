import 'package:flutter/foundation.dart';

import '../common/media_type.dart';

class CollectionManager {
  final mediaTypeNotifier = ValueNotifier<MediaType>(MediaType.podcast);
}
