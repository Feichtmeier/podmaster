import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/media_type.dart';
import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../collection_manager.dart';

class CollectionSearchField extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const CollectionSearchField({super.key});

  @override
  State<CollectionSearchField> createState() => _CollectionSearchFieldState();
}

class _CollectionSearchFieldState extends State<CollectionSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = di<CollectionManager>().textChangedCommand.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchType = watchValue((CollectionManager s) => s.mediaTypeNotifier);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kBigPadding,
      ).copyWith(top: kBigPadding, bottom: kSmallPadding),
      child: TextField(
        controller: _controller,
        onChanged: di<CollectionManager>().textChangedCommand.run,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.primary),
            borderRadius: BorderRadius.circular(6),
          ),
          label: Text(searchType.localize(context)),
          hint: Text(searchType.localize(context)),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: MediaType.values
                .mapIndexed(
                  (index, e) => IconButton(
                    style: getTextFieldPrefixStyle(context, index),
                    isSelected: e == searchType,
                    icon: Icon(e.iconData()),
                    tooltip: e.localize(context),
                    onPressed: () {
                      di<CollectionManager>().mediaTypeNotifier.value = e;
                    },
                  ),
                )
                .toList(),
          ),
          suffixIcon: IconButton(
            style: getTextFieldSuffixStyle(context),
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              di<CollectionManager>().textChangedCommand.run('');
            },
          ),
        ),
      ),
    );
  }
}
