# MleySoft Aidat Mobil v35
Native Flutter istemci + PHP REST API.

## İlk kurulum
1. Sunucuda `sql/update_v35.sql` çalıştırın.
2. `mobile_app` içinde `flutter pub get` çalıştırın.
3. Firebase projenizde Android ve iOS uygulamalarını oluşturup `flutterfire configure` çalıştırın. Bu işlem gerçek `firebase_options.dart`, Android `google-services.json` ve Apple yapılandırmasını üretir.
4. iOS'ta Push Notifications ile Background Modes > Remote notifications özelliklerini açın ve APNs anahtarını Firebase'e bağlayın.
5. Gerekirse API adresini build sırasında değiştirin: `--dart-define=API_BASE=https://alanadiniz/.../api/mobile`.

## v35 mobil kapsamı
Sakin girişi, güvenli token oturumu, anasayfa, aidat/borçlar, dönemsel ödeme referansları, ödeme geçmişi, duyurular/okunma, arıza-talep, FCM cihaz token kaydı, foreground/background bildirim altyapısı, beyaz arka plan, logo splash/yükleme animasyonu.

Firebase proje anahtarları kullanıcı hesabına özgü olduğu için ZIP'e uydurma anahtar gömülmemiştir.

## v48
Üç rol native: super_admin / manager / resident. Local notification paketi kullanılmaz; FCM kullanılır. Firebase istemci yapılandırması gerçek Firebase projesinden sağlanmalıdır.
