import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class NetworkGuard extends StatefulWidget {
  final Widget child;

  const NetworkGuard({super.key, required this.child});

  @override
  State<NetworkGuard> createState() => _NetworkGuardState();
}

class _NetworkGuardState extends State<NetworkGuard>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;
  bool _offline = false;
  bool _checking = false;
  bool _everOffline = false;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = Connectivity().onConnectivityChanged.listen((_) => _check());
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    bool ok = false;

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.none)) {
        final uri = Uri.parse(
          '${AppConfig.apiBase}/ping.php?t=${DateTime.now().millisecondsSinceEpoch}',
        );
        final response = await http.get(
          uri,
          headers: const {'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 3));
        ok = response.statusCode >= 200 && response.statusCode < 500;
      }
    } catch (_) {
      ok = false;
    } finally {
      _checking = false;
    }

    if (!mounted) return;

    final wasOffline = _offline;
    if (!ok) {
      _everOffline = true;
      _showRestored = false;
    }

    setState(() => _offline = !ok);

    if (wasOffline && ok && _everOffline) {
      setState(() => _showRestored = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showRestored = false);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: SafeArea(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 52,
                          color: Color(0xFF111418),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'İnternet bağlantısı yok',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111418),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bağlantınızı kontrol edin. İnternet yeniden geldiğinde uygulama otomatik olarak bağlanacaktır.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.45,
                            color: Color(0xFF667085),
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_showRestored)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16794A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'İnternet bağlantısı yeniden kuruldu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
