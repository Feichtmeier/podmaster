import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/media_type.dart';
import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../search_manager.dart';

class SearchField extends StatefulWidget with WatchItStatefulWidgetMixin {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = di<SearchManager>().textChangedCommand.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchType = watchValue((SearchManager s) => s.searchTypeNotifier);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kBigPadding,
      ).copyWith(top: kBigPadding, bottom: kSmallPadding),
      child: TextField(
        controller: _controller,
        onChanged: di<SearchManager>().textChangedCommand.run,
        decoration: InputDecoration(
          label: Text(searchType.localize(context)),
          hint: Text(searchType.localize(context)),
          prefixIcon: DropdownButton<MediaType>(
            icon: const SizedBox.shrink(),
            padding: EdgeInsets.zero,
            underline: const SizedBox.shrink(),
            value: searchType,
            items: MediaType.values
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: kBigPadding,
                        right: 4.0,
                      ),
                      child: Icon(e.iconData()),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                di<SearchManager>().searchTypeNotifier.value = v;
              }
            },
          ),

          suffixIcon: IconButton(
            style: getTextFieldSuffixStyle(context),
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              di<SearchManager>().textChangedCommand.run('');
            },
          ),
        ),
      ),
    );
  }
}
