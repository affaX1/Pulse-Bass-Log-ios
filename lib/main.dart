import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pulse_bass_log/data/logic.dart';
import 'package:pulse_bass_log/screens/portal_screen.dart';

import 'app_state.dart';
import 'data/database_service.dart';
import 'screens/main_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance.getAPNSToken();
  }
  runApp(const FishBassApp());
}

class FishBassApp extends StatefulWidget {
  const FishBassApp({super.key});

  @override
  State<FishBassApp> createState() => _FishBassAppState();
}

class _FishBassAppState extends State<FishBassApp> {
  late final Future<AppState> _loader;
  final DatabaseService _db = DatabaseService();
  late final AppLogic _logic;
  late final Future<Uri?> _feewFuture;

  @override
  void initState() {
    super.initState();
    _loader = AppState.load(_db);
    _logic = AppLogic(enableTracking: false);
    _feewFuture = _prepareFeew();
  }

  Future<Uri?> _prepareFeew() async {
    final Uri bootstrap = Uri.parse(
      'https://pulse-bass-log-default-rtdb.firebaseio.com/.json',
    );

    if (await _logic.restoreDestinationFromCache()) {
      return _logic.feewPath;
    }

    return _logic.resolveFeewPath(bootstrapEndpoint: bootstrap);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _loader,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const SplashLoader(),
          );
        }
        final state = snapshot.requireData;
        return AppStateProvider(
          state: state,
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Pulse Blass Log',
                themeMode: state.settings.themeMode,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                home: Loader(destinationFuture: _feewFuture),
              );
            },
          ),
        );
      },
    );
  }
}

class Loader extends StatelessWidget {
  const Loader({super.key, required this.destinationFuture});

  final Future<Uri?> destinationFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uri?>(
      future: destinationFuture,
      builder: (BuildContext context, AsyncSnapshot<Uri?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashLoader();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: const MainShell(),
        );
      },
    );
  }
}

class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.33, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0a1f7a), Color(0xFF1657e6), Color(0xFF1f8bff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final percent = (_controller.value * 100).ceil().clamp(1, 100);
              final rotation = _controller.value * 6.28;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: const [
                        Text(
                          'Initializing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preparing your data and notifications',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),

                  Container(
                    width: 240,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: percent / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: const [
                                Color(0xFF7ee8fa),
                                Color(0xFF80ff72),
                                Color(0xFF7ee8fa),
                              ],
                              transform: GradientRotation(rotation),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
