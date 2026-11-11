import 'dart:async';
import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/network_guard.dart';
import 'core/loading.dart';
import 'core/push.dart';
import 'core/ui.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'screens/manager_shell.dart';
import 'screens/admin_shell.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // v195: Ekranlarda yakalanmamış API/ağ hataları sessizce kaybolmasın; kullanıcıya anlaşılır mesaj gösterilir.
  binding.platformDispatcher.onError = (Object error, StackTrace stack) {
    final text = '$error';
    final handled = error is ApiException || error is TimeoutException || text.contains('SocketException') || text.contains('ClientException') || text.contains('HandshakeException');
    if (handled) showAppMessage(apiErrorText(error));
    return handled;
  };
  runApp(const MleySoftApp());
}

/// v195: Tema sıfırdan yazıldı. Tüm ekranlar ui.dart belirteçlerini kullanır.
ThemeData buildAppTheme() {
  final radius12 = BorderRadius.circular(12);
  final radius14 = BorderRadius.circular(14);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: ink,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: ink,
    error: danger,
    outline: line,
    outlineVariant: line,
  );
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: radius14, borderSide: BorderSide(color: c, width: w));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: ink, letterSpacing: -.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink, letterSpacing: -.3),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
      bodyMedium: TextStyle(color: Color(0xFF1F2937), height: 1.4),
      bodySmall: TextStyle(color: muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.2),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: radius12), iconColor: muted, titleTextStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 15)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      shape: RoundedRectangleBorder(borderRadius: radius14),
      contentTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      actionTextColor: brand,
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), titleTextStyle: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, showDragHandle: false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    popupMenuTheme: PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: radius14, side: const BorderSide(color: line))),
    drawerTheme: const DrawerThemeData(backgroundColor: ink, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: subtle),
      prefixIconColor: subtle,
      border: border(line),
      enabledBorder: border(line),
      focusedBorder: border(primary, 1.6),
      errorBorder: border(danger),
      focusedErrorBorder: border(danger, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, disabledBackgroundColor: primary.withValues(alpha: .4), disabledForegroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: radius14), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: radius14), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: ink, backgroundColor: Colors.white, minimumSize: const Size(0, 48), side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: radius14), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary, textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: ink)),
    chipTheme: ChipThemeData(backgroundColor: Colors.white, selectedColor: primarySoft, side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: ink)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primarySoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontSize: 11.5, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: s.contains(WidgetState.selected) ? primary : muted)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? primary : muted, size: 24)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primarySoft,
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12.5),
      unselectedLabelTextStyle: TextStyle(color: muted, fontWeight: FontWeight.w500, fontSize: 12.5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary, linearTrackColor: line, circularTrackColor: line),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null), trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null)),
    checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
  );
}

class MleySoftApp extends StatelessWidget {
  const MleySoftApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MleySoft Aidat',
        scaffoldMessengerKey: appMessengerKey,
        theme: buildAppTheme(),
        home: const NetworkGuard(child: Boot()),
      );
}

class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  bool? ok;
  String? role;
  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final t = await Api.token();
    if (t == null || t.isEmpty) {
      ok = false;
      if (mounted) setState(() {});
      unawaited(PushService.disableWhileLoggedOut());
      unawaited(PushService.init(registerToken: false));
      return;
    }
    role = await Api.role();
    try {
      final me = await Api.request('me').timeout(const Duration(seconds: 12));
      role = me['user']?['role']?.toString() ?? role;
      if (role != null) await Api.saveRole(role!);
      ok = true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await Api.clear();
        ok = false;
      } else {
        ok = role != null;
      }
    } on TimeoutException {
      ok = role != null;
    } catch (_) {
      ok = role != null;
    }
    if (mounted) setState(() {});
    if (ok == true) unawaited(PushService.init());
  }

  @override
  Widget build(BuildContext c) {
    if (ok == null) return const Scaffold(backgroundColor: Colors.white, body: BrandLoader());
    if (!ok!) return const LoginScreen();
    if (role == 'super_admin') return const AdminShell();
    if (role == 'manager') return const ManagerShell();
    return const AppShell();
  }
}
