import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const kTinyPadding = 2.5;

const kSmallPadding = 5.0;

const kMediumPadding = 10.0;

const kMediumPlusPadding = 15.0;

const kBigPadding = 20.0;

const kSideBarWith = 280.0;

const kShowSideBarThreshHold = 700.0;

const kBottomPlayerHeight = 80.0;

const kPlayerInfoWidth = 160.0;

const kPlayerTrackHeight = 4.0;

const windowOptions = WindowOptions(
  size: Size(1024, 800),
  minimumSize: Size(400, 600),
  center: true,
);

var playerButtonStyle = IconButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.transparent,
);

const kDefaultTileLeadingDimension = 40.0;

final kGridViewPadding = const EdgeInsets.symmetric(
  horizontal: kBigPadding,
).copyWith(bottom: kBigPadding);
const kGridViewDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  crossAxisSpacing: kBigPadding,
  mainAxisSpacing: kBigPadding,
  maxCrossAxisExtent: 200,
  mainAxisExtent: 260,
);
