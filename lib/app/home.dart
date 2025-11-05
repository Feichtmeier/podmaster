import 'package:custom_adaptive_scaffold/custom_adaptive_scaffold.dart';
import 'package:flutter/material.dart';

import '../player/view/player_view.dart';

class WaitForRegistrationPage extends StatefulWidget {
  const WaitForRegistrationPage({super.key});

  @override
  State<WaitForRegistrationPage> createState() => _WaitForRegistrationPageState();
}

class _WaitForRegistrationPageState extends State<WaitForRegistrationPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedTab = 0;
  final int _transitionDuration = 300;
  @override
  Widget build(BuildContext context) {
    // Define the children to display within the body at different breakpoints.
    final List<Widget> children = <Widget>[
      for (int i = 0; i < 10; i++)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: const Color.fromARGB(255, 255, 201, 197),
            height: 400,
          ),
        ),
    ];
    return Material(
      child: Column(
        children: [
          Expanded(
            child: AdaptiveScaffold(
              // An option to override the default transition duration.
              transitionDuration: Duration(milliseconds: _transitionDuration),
              // An option to override the default breakpoints used for small, medium,
              // mediumLarge, large, and extraLarge.
              smallBreakpoint: const Breakpoint(endWidth: 700),
              mediumBreakpoint: const Breakpoint(
                beginWidth: 700,
                endWidth: 1000,
              ),
              mediumLargeBreakpoint: const Breakpoint(
                beginWidth: 1000,
                endWidth: 1200,
              ),
              largeBreakpoint: const Breakpoint(
                beginWidth: 1200,
                endWidth: 1600,
              ),
              extraLargeBreakpoint: const Breakpoint(beginWidth: 1600),
              useDrawer: false,
              selectedIndex: _selectedTab,
              onSelectedIndexChange: (int index) =>
                  setState(() => _selectedTab = index),

              destinations: const <CustomNavigationDestination>[
                CustomNavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                CustomNavigationDestination(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  selectedIcon: Icon(Icons.collections_bookmark),
                  label: 'Library',
                ),
                CustomNavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
              smallBody: (_) => ListView.builder(
                itemCount: children.length,
                itemBuilder: (_, int idx) => children[idx],
              ),
              body: (_) =>
                  GridView.count(crossAxisCount: 2, children: children),
              mediumLargeBody: (_) =>
                  GridView.count(crossAxisCount: 3, children: children),
              largeBody: (_) =>
                  GridView.count(crossAxisCount: 4, children: children),
              extraLargeBody: (_) =>
                  GridView.count(crossAxisCount: 5, children: children),
              // Define a default secondaryBody.
              // Override the default secondaryBody during the smallBreakpoint to be
              // empty. Must use AdaptiveScaffold.emptyBuilder to ensure it is properly
              // overridden.
              smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
              secondaryBody: (_) =>
                  Container(color: const Color.fromARGB(255, 234, 158, 192)),
              mediumLargeSecondaryBody: (_) =>
                  Container(color: const Color.fromARGB(255, 234, 158, 192)),
              largeSecondaryBody: (_) =>
                  Container(color: const Color.fromARGB(255, 234, 158, 192)),
              extraLargeSecondaryBody: (_) =>
                  Container(color: const Color.fromARGB(255, 234, 158, 192)),
            ),
          ),
          const PlayerView(),
        ],
      ),
    );
  }
}
