import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secret_love/context.dart';



class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final ContextService contextService;
  const LifecycleWatcher({super.key, required this.child , required this.navigatorKey, required this.contextService});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.microtask(() {
        _restartApp();
      });
    }
    _lastState = state;
  }

  void _restartApp() async {
    debugPrint("Restart App Dimulai!!!");

    try {
     await widget.contextService.loadFromAPI();
    } catch (error){
      debugPrint("EROOR RESTART APP : ${error.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
