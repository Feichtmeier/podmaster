import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../common/media_type.dart';

class CollectionManager {
  final mediaTypeNotifier = SafeValueNotifier<MediaType>(MediaType.podcast);
}
