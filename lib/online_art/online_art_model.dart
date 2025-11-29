import 'dart:async';

import 'package:flutter/material.dart';

import 'online_art_service.dart';

class OnlineArtModel extends ChangeNotifier {
  OnlineArtModel({required OnlineArtService onlineArtService})
    : _onlineArtService = onlineArtService {
    _propertiesChangedSub ??= _onlineArtService.propertiesChanged.listen(
      (_) => notifyListeners(),
    );
  }

  final OnlineArtService _onlineArtService;
  StreamSubscription<bool>? _propertiesChangedSub;
  String? getCover(String icyTitle) => _onlineArtService.get(icyTitle);

  @override
  Future<void> dispose() async {
    await _propertiesChangedSub?.cancel();
    super.dispose();
  }
}
