import 'package:flutter/material.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.oopsSomethingWentWrong)),
      body: ErrorBody(error: error),
    );
  }
}

class ErrorBody extends StatelessWidget {
  const ErrorBody({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kBigPadding),
        child: Text('An error occurred: $error'),
      ),
    );
  }
}
