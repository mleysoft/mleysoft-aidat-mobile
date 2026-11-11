import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/api.dart';
import '../core/loading.dart';
import '../core/push.dart';
import '../core/ui.dart';
import 'shell.dart';
import 'manager_shell.dart';
import 'admin_shell.dart';

/// v195 – Giriş ekranı (sıfırdan yazıldı).
///
/// App Store 3.1.1 ve 5.1.1(v) gereği uygulama içinde hesap/kurum kaydı YOKTUR.
/// Yönetici hesapları kurum tarafından tanımlanır; daire sakinleri, site yöneticisinin
/// sisteme tanımladığı cep telefonuyla tek kullanımlık kod ile giriş yapar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final TextInputFormatter _phoneFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length > 11) digits = digits.substring(2);
    final addedZero = digits.startsWith('5');
    if (addedZero) digits = '0$digits';
    if (digits.length > 11) digits = digits.substring(0, 11);
    var offset = newValue.selection.baseOffset + (addedZero ? 1 : 0);
    if (offset < 0) offset = 0;
    if (offset > digits.length) offset = digits.length;
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: offset));
  });

  int tab = 0; // 0: yönetici, 1: daire sakini
  bool busy = false, hidePassword = true, otpSent = false;
  String? err, info;
  int resendIn = 0;
  Timer? _resendTimer;
  final email = TextEditingController(), pw = TextEditingController(), phone = TextEditingController(), otp = TextEditingController();

  @override
  void dispose() {
    _resendTimer?.cancel();
    email.dispose();
    pw.dispose();
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- İşlemler
  Future<void> _openWeb(String page) async {
    final base = AppConfig.legalUrl(page);
    final uri = Uri.parse(base).replace(queryParameters: {...Uri.parse(base).queryParameters, 'app': '1'});
    try {
      var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!opened) opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!opened) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('URL açılamadı');
    } catch (_) {
      if (mounted) setState(() => err = 'Bağlantı açılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.');
    }
  }

  Future<void> managerLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final mail = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(mail)) {
      setState(() => err = 'Geçerli bir e-posta adresi girin.');
      return;
    }
    if (pw.text.isEmpty) {
      setState(() => err = 'Şifrenizi girin.');
      return;
    }
    await _run(() async {
      final d = await Api.request('login', method: 'POST', auth: false, body: {'identifier': mail, 'password': pw.text, 'device_name': 'MleySoft Aidat'});
      await _enter(d);
    });
  }

  bool _validPhone() => RegExp(r'^05\d{9}$').hasMatch(phone.text.trim());

  Future<void> sendOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validPhone()) {
      setState(() => err = 'Cep telefonunuzu 05xx xxx xx xx biçiminde girin.');
      return;
    }
    await _run(() async {
      final d = await Api.request('resident-otp-request', method: 'POST', auth: false, body: {'phone': phone.text.trim()});
      if (d['demo_login'] == true && d['token'] != null) {
        await _enter(d);
        return;
      }
      if (!mounted) return;
      setState(() {
        otpSent = true;
        info = 'Doğrulama kodu WhatsApp ile gönderildi. Kod 5 dakika geçerlidir.';
      });
      _startResendTimer();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => resendIn = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => resendIn = resendIn > 0 ? resendIn - 1 : 0);
      if (resendIn == 0) t.cancel();
    });
  }

  Future<void> verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!RegExp(r'^\d{6}$').hasMatch(otp.text.trim())) {
      setState(() => err = '6 haneli doğrulama kodunu girin.');
      return;
    }
    await _run(() async {
      final d = await Api.request('resident-otp-verify', method: 'POST', auth: false, body: {'phone': phone.text.trim(), 'code': otp.text.trim()});
      if (d['selection_required'] == true) {
        final choices = List<Map<String, dynamic>>.from(((d['choices'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
        if (!mounted) return;
        final pick = await showApartmentPicker(context, choices, title: 'Dairenizi Seçin');
        if (pick == null) return;
        final selected = await Api.request('resident-select', method: 'POST', auth: false, body: {'selection_token': d['selection_token'], 'apartment_id': pick['apartment_id']});
        await _enter(selected);
        return;
      }
      await _enter(d);
    });
  }

  Future<void> _enter(Map<String, dynamic> d) async {
    final token = d['token']?.toString() ?? '';
    if (token.isEmpty) throw const ApiException('Oturum açılamadı. Lütfen tekrar deneyin.', 500);
    await Api.saveToken(token);
    final u = Map<String, dynamic>.from((d['user'] as Map?) ?? const {});
    final role = (u['role'] ?? 'resident').toString();
    await Api.saveRole(role);
    try {
      await PushService.syncToken().timeout(const Duration(seconds: 4));
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => role == 'manager' ? const ManagerShell() : role == 'super_admin' ? const AdminShell() : const AppShell()),
      (_) => false,
    );
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      busy = true;
      err = null;
      info = null;
    });
    try {
      await f();
    } on TimeoutException {
      if (mounted) setState(() => err = 'Sunucu yanıt vermedi. İnternet bağlantınızı kontrol edip tekrar deneyin.');
    } catch (e) {
      if (mounted) setState(() => err = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _switchTab(int i) {
    if (i == tab) return;
    setState(() {
      tab = i;
      err = null;
      info = null;
    });
  }

  void _resetPhone() {
    _resendTimer?.cancel();
    setState(() {
      otpSent = false;
      otp.clear();
      err = null;
      info = null;
      resendIn = 0;
    });
  }

  // ---------------------------------------------------------------- Arayüz
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _formPanel(wide);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: LoadingOverlay(
          loading: busy,
          child: wide
              ? Row(children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 6, child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32), child: form)))),
                ])
              : SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 28, 22, 24), child: form))),
        ),
      ),
    );
  }

  Widget _formPanel(bool wide) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!wide) ...[
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/images/aidat_icon.png', width: 48, height: 48, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MleySoft Aidat', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink, letterSpacing: -.3)),
                Text('Aidat ve site yönetimi', style: TextStyle(fontSize: 13, color: muted)),
              ])),
            ]),
            const SizedBox(height: 32),
          ],
          Text(tab == 0 ? 'Yönetici girişi' : 'Daire sakini girişi', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink, letterSpacing: -.8)),
          const SizedBox(height: 6),
          Text(
            tab == 0 ? 'Yönetim panelinize e-posta ve şifrenizle giriş yapın.' : 'Site yöneticinizin sisteme tanımladığı cep telefonunuzla, şifresiz giriş yapın.',
            style: const TextStyle(fontSize: 14.5, color: muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          _segmented(),
          const SizedBox(height: 22),
          if (err != null) _note(err!, danger, Icons.error_outline_rounded),
          if (info != null && err == null) _note(info!, success, Icons.check_circle_outline_rounded),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(tab), child: tab == 0 ? _managerForm() : _residentForm()),
          ),
          const SizedBox(height: 28),
          _legalLinks(),
        ]),
      );

  Widget _segmented() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
        child: Row(children: [
          _segment('Yönetici', Icons.business_center_outlined, 0),
          _segment('Daire Sakini', Icons.home_outlined, 1),
        ]),
      );

  Widget _segment(String label, IconData icon, int i) {
    final active = tab == i;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: busy ? null : () => _switchTab(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active ? const [BoxShadow(color: Color(0x140B1324), blurRadius: 6, offset: Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: active ? ink : muted),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? ink : muted)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _note(String text, Color color, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: .07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .22))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: TextStyle(color: color == danger ? const Color(0xFF991B1B) : const Color(0xFF166534), fontWeight: FontWeight.w600, height: 1.35))),
        ]),
      );

  Widget _managerForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-posta', hintText: 'ornek@firma.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: pw,
          enabled: !busy,
          obscureText: hidePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => managerLogin(),
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: hidePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
              onPressed: () => setState(() => hidePassword = !hidePassword),
              icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: muted),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: busy ? null : () => _openWeb('forgot-password.php'), child: const Text('Şifremi unuttum')),
        ),
        const SizedBox(height: 4),
        FilledButton(onPressed: busy ? null : managerLogin, child: const Text('Giriş Yap')),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 19, color: muted),
            SizedBox(width: 10),
            Expanded(child: Text('Yönetici hesapları kurumunuz tarafından tanımlanır. Giriş bilgileriniz yoksa site yönetiminizle iletişime geçin.', style: TextStyle(color: muted, fontSize: 13, height: 1.4))),
          ]),
        ),
      ]);

  Widget _residentForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: phone,
          readOnly: otpSent,
          enabled: !busy,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => otpSent ? null : sendOtp(),
          inputFormatters: [_phoneFormatter],
          decoration: InputDecoration(
            labelText: 'Kayıtlı cep telefonu',
            hintText: '05xx xxx xx xx',
            prefixIcon: const Icon(Icons.phone_iphone_rounded),
            suffixIcon: otpSent ? IconButton(tooltip: 'Numarayı değiştir', onPressed: busy ? null : _resetPhone, icon: const Icon(Icons.edit_outlined, color: muted)) : null,
          ),
        ),
        if (!otpSent) ...[
          const SizedBox(height: 10),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.verified_user_outlined, size: 17, color: primary),
            SizedBox(width: 8),
            Expanded(child: Text('Şifre gerekmez. Numaranıza WhatsApp üzerinden 6 haneli tek kullanımlık bir kod gönderilir.', style: TextStyle(color: muted, fontSize: 13, height: 1.4))),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: busy ? null : sendOtp, icon: const Icon(Icons.send_rounded, size: 19), label: const Text('Doğrulama Kodu Gönder')),
        ] else ...[
          const SizedBox(height: 14),
          TextField(
            controller: otp,
            enabled: !busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onChanged: (v) {
              if (v.length == 6 && !busy) verifyOtp();
            },
            onSubmitted: (_) => verifyOtp(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 10, color: ink),
            decoration: const InputDecoration(labelText: 'Doğrulama kodu', hintText: '••••••', counterText: ''),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: busy ? null : verifyOtp, icon: const Icon(Icons.verified_rounded, size: 19), label: const Text('Doğrula ve Giriş Yap')),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(onPressed: busy ? null : _resetPhone, child: const Text('Farklı numara')),
            TextButton(onPressed: (busy || resendIn > 0) ? null : sendOtp, child: Text(resendIn > 0 ? 'Tekrar gönder ($resendIn sn)' : 'Kodu tekrar gönder')),
          ]),
        ],
      ]);

  Widget _legalLinks() => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          TextButton(onPressed: () => _openWeb('gizlilik-politikasi.php'), style: TextButton.styleFrom(foregroundColor: muted), child: const Text('Gizlilik', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          const Text('·', style: TextStyle(color: subtle)),
          TextButton(onPressed: () => _openWeb('kullanim-kosullari.php'), style: TextButton.styleFrom(foregroundColor: muted), child: const Text('Kullanım Koşulları', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          const Text('·', style: TextStyle(color: subtle)),
          TextButton(onPressed: () => _openWeb('kvkk.php'), style: TextButton.styleFrom(foregroundColor: muted), child: const Text('KVKK', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      );
}

/// iPad / geniş ekranda sol marka paneli.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) => Container(
        color: ink,
        child: Stack(children: [
          Positioned(right: -140, top: -120, child: Container(width: 380, height: 380, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x38C6F135), Color(0x00C6F135)])))),
          Positioned(left: -120, bottom: -160, child: Container(width: 380, height: 380, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x770F766E), Color(0x000F766E)])))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 44, 48, 36),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/aidat_icon.png', width: 44, height: 44, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  const Text('MleySoft Aidat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
                const Spacer(),
                const Text('AİDAT & SİTE YÖNETİMİ', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 14),
                const Text('Sitenizin tüm finansı,\ntek ve sade bir ekranda.', style: TextStyle(color: Colors.white, fontSize: 34, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 30),
                const _BrandPoint(Icons.calculate_outlined, 'Kuruşu kuruşuna aidat', 'Giderler bağımsız bölümlere otomatik ve hatasız dağıtılır.'),
                const _BrandPoint(Icons.account_balance_wallet_outlined, 'Anlık tahsilat takibi', 'Borç ve ödeme geçmişi her an elinizin altında.'),
                const _BrandPoint(Icons.campaign_outlined, 'Sakinlerle iletişim', 'Duyurular, talepler ve bildirimler tek merkezde.'),
                const Spacer(),
                const Text('© MleySoft Yazılım', style: TextStyle(color: Color(0xFF7D8BA1), fontSize: 12)),
              ]),
            ),
          ),
        ]),
      );
}

class _BrandPoint extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _BrandPoint(this.icon, this.title, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: brand, size: 21)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(color: Color(0xFFA6B2C4), fontSize: 13.5, height: 1.4)),
          ])),
        ]),
      );
}
