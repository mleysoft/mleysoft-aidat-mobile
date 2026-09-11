import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/loading.dart';
import '../core/ui.dart';

String _err(Object e)=>'$e'.replaceFirst('Exception: ','');
bool _on(dynamic v)=>v==true||v==1||v=='1';
void _snack(BuildContext c,String m,{bool error=false}){ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(m),backgroundColor:error?danger:null));}

Widget _section(String title,String subtitle,Widget child,{IconData icon=Icons.settings_rounded}){
 return Padding(padding:const EdgeInsets.only(bottom:14),child:SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(crossAxisAlignment:CrossAxisAlignment.start,children:[IconBubble(icon,blue),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),if(subtitle.isNotEmpty)Padding(padding:const EdgeInsets.only(top:3),child:Text(subtitle,style:const TextStyle(fontSize:12,color:muted))) ]))]),
  const SizedBox(height:16),child
 ])));
}
Widget _field(TextEditingController c,String label,{bool secret=false,int lines=1,TextInputType? keyboard,String? hint})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,obscureText:secret,maxLines:secret?1:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:label,hintText:hint)));

class AdminIntegrationsPage extends StatelessWidget{
 const AdminIntegrationsPage({super.key});
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
  const PageTitle('Entegrasyonlar',subtitle:'Web yönetimindeki SMTP, WhatsApp Cloud API ve banka kataloğunu yönetin'),
  SoftCard(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminSmtpPage())),child:const ListTile(contentPadding:EdgeInsets.zero,leading:IconBubble(Icons.email_rounded,blue),title:Text('SMTP / Mail',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Giden e-posta sunucusu, gönderen hesabı ve aktivasyon'),trailing:Icon(Icons.chevron_right_rounded))),
  const SizedBox(height:10),
  SoftCard(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminWhatsAppPage())),child:const ListTile(contentPadding:EdgeInsets.zero,leading:IconBubble(Icons.chat_rounded,success),title:Text('WhatsApp Cloud API',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Meta bağlantısı, template ayarları, testler, kuyruk ve webhook hareketleri'),trailing:Icon(Icons.chevron_right_rounded))),
  const SizedBox(height:10),
  SoftCard(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminBanksPage())),child:const ListTile(contentPadding:EdgeInsets.zero,leading:IconBubble(Icons.account_balance_rounded,violet),title:Text('Banka Entegrasyonları',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Yöneticilere açık banka kataloğunu yönetin'),trailing:Icon(Icons.chevron_right_rounded))),
 ]);
}

class AdminSmtpPage extends StatefulWidget{const AdminSmtpPage({super.key});@override State<AdminSmtpPage> createState()=>_AdminSmtpPageState();}
class _AdminSmtpPageState extends State<AdminSmtpPage>{
 final host=TextEditingController(),port=TextEditingController(),username=TextEditingController(),password=TextEditingController(),fromEmail=TextEditingController(),fromName=TextEditingController();
 String encryption='tls';bool active=false,busy=true,saving=false,passwordSaved=false;
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{final d=await Api.request('admin?action=smtp');final s=Map<String,dynamic>.from(d['settings']??{});host.text='${s['host']??''}';port.text='${s['port']??587}';username.text='${s['username']??''}';fromEmail.text='${s['from_email']??''}';fromName.text='${s['from_name']??''}';encryption='${s['encryption']??'tls'}';active=_on(s['is_active']);passwordSaved=_on(s['password_saved']);}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{busy=false;if(mounted)setState((){});}}
 Future<void>save()async{setState(()=>saving=true);try{final d=await Api.request('admin',method:'POST',body:{'action':'save_smtp','host':host.text,'port':port.text,'username':username.text,'password':password.text,'encryption':encryption,'from_email':fromEmail.text,'from_name':fromName.text,'is_active':active});if(mounted)_snack(context,'${d['message']}');password.clear();await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{if(mounted)setState(()=>saving=false);}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('SMTP / Mail')),backgroundColor:bg,body:busy?const Center(child:BrandLoader()):ListView(padding:const EdgeInsets.all(20),children:[
  const PageTitle('Giden E-posta Ayarları',subtitle:'Hoş geldiniz ve şifre sıfırlama mailleri bu hesap üzerinden gönderilir'),
  _section('SMTP Sunucusu','Web yönetimi ile aynı SMTP yapılandırması',Column(children:[
   _field(host,'SMTP Sunucu',hint:'smtp.domain.com'),_field(port,'Port',keyboard:TextInputType.number),_field(username,'Kullanıcı Adı'),
   _field(password,'Şifre',secret:true,hint:passwordSaved?'Şifre kayıtlı — değiştirmek için yenisini girin':'SMTP şifresi'),
   DropdownButtonFormField<String>(initialValue:encryption,decoration:const InputDecoration(labelText:'Şifreleme'),items:const [DropdownMenuItem(value:'tls',child:Text('TLS')),DropdownMenuItem(value:'ssl',child:Text('SSL')),DropdownMenuItem(value:'none',child:Text('Yok'))],onChanged:(v)=>setState(()=>encryption=v??'tls')),
   const SizedBox(height:10),_field(fromEmail,'Gönderen E-posta',keyboard:TextInputType.emailAddress),_field(fromName,'Gönderen Adı'),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Mail gönderimini aktif et',style:TextStyle(fontWeight:FontWeight.w800)),value:active,onChanged:(v)=>setState(()=>active=v)),
   SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:save,icon:const Icon(Icons.save_rounded),label:Text(saving?'Kaydediliyor...':'Ayarları Kaydet')))
  ]),icon:Icons.email_rounded)
 ]));
}

class AdminWhatsAppPage extends StatefulWidget{const AdminWhatsAppPage({super.key});@override State<AdminWhatsAppPage> createState()=>_AdminWhatsAppPageState();}
class _AdminWhatsAppPageState extends State<AdminWhatsAppPage>{
 Map<String,dynamic>? data;String? loadError;bool busy=true,saving=false;
 final phone=TextEditingController(),phoneId=TextEditingController(),waba=TextEditingController(),graph=TextEditingController(),token=TextEditingController(),verify=TextEditingController(),secret=TextEditingController();
 final payName=TextEditingController(),payLang=TextEditingController(),credName=TextEditingController(),credLang=TextEditingController(),dueName=TextEditingController(),dueLang=TextEditingController();
 bool active=false,payEnabled=false,credEnabled=false,dueEnabled=false,tokenSaved=false,secretSaved=false;
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{data=await Api.request('admin?action=whatsapp');loadError=null;final s=Map<String,dynamic>.from(data?['settings']??{});phone.text='${s['phone_number']??''}';phoneId.text='${s['phone_number_id']??''}';waba.text='${s['waba_id']??''}';graph.text='${s['graph_version']??'26.0'}';verify.text='${s['verify_token']??''}';payName.text='${s['payment_template_name']??'aidat_odeme_alindi'}';payLang.text='${s['payment_template_language']??'tr'}';credName.text='${s['credential_template_name']??'daire_giris_anahtari'}';credLang.text='${s['credential_template_language']??'tr'}';dueName.text='${s['due_template_name']??'aidat_hesaplandi'}';dueLang.text='${s['due_template_language']??'tr'}';active=_on(s['is_active']);payEnabled=_on(s['payment_template_enabled']);credEnabled=_on(s['credential_template_enabled']);dueEnabled=_on(s['due_template_enabled']);tokenSaved=_on(s['token_saved']);secretSaved=_on(s['secret_saved']);}catch(e){loadError=_err(e);data=null;}finally{busy=false;if(mounted)setState((){});}}
 Future<void>save()async{setState(()=>saving=true);try{final d=await Api.request('admin',method:'POST',body:{'action':'save_whatsapp','phone_number':phone.text,'phone_number_id':phoneId.text,'waba_id':waba.text,'graph_version':graph.text,'api_token':token.text,'verify_token':verify.text,'app_secret':secret.text,'payment_template_name':payName.text,'payment_template_language':payLang.text,'payment_template_enabled':payEnabled,'credential_template_name':credName.text,'credential_template_language':credLang.text,'credential_template_enabled':credEnabled,'due_template_name':dueName.text,'due_template_language':dueLang.text,'due_template_enabled':dueEnabled,'is_active':active});if(mounted)_snack(context,'${d['message']}');token.clear();secret.clear();await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{if(mounted)setState(()=>saving=false);}}
 Future<void>action(String a,{Map<String,dynamic>? body})async{try{final d=await Api.request('admin',method:'POST',body:{'action':a,...?body});if(mounted)_snack(context,'${d['message']}');await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}}
 Future<void>textTest()async{final r=TextEditingController(),m=TextEditingController(text:'MleySoft Aidat Takip WhatsApp Cloud API test mesajıdır.');final ok=await _sheet(context,'Serbest Metin Testi',[_field(r,'Alıcı Telefon',keyboard:TextInputType.phone),_field(m,'Mesaj',lines:3)]);if(ok)await action('whatsapp_send_test',body:{'recipient':r.text,'message':m.text});}
 Future<void>templateTest()async{final r=TextEditingController();final ok=await _sheet(context,'Template Testi',[_field(r,'Test Alıcı Telefon',keyboard:TextInputType.phone),const Text('Örnek ödeme değişkenleri ile aidat template mesajı gönderilir.',style:TextStyle(color:muted,fontSize:12))]);if(ok)await action('whatsapp_send_template_test',body:{'recipient':r.text});}
 @override Widget build(BuildContext c){if(busy)return const Scaffold(body:Center(child:BrandLoader()));if(loadError!=null)return Scaffold(appBar:AppBar(title:const Text('WhatsApp Cloud API')),backgroundColor:bg,body:Center(child:Padding(padding:const EdgeInsets.all(24),child:SoftCard(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline_rounded,size:42,color:danger),const SizedBox(height:12),const Text('WhatsApp ayarları yüklenemedi',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(loadError!,textAlign:TextAlign.center,style:const TextStyle(color:muted)),const SizedBox(height:14),FilledButton.icon(onPressed:(){setState(()=>busy=true);load();},icon:const Icon(Icons.refresh_rounded),label:const Text('Tekrar Dene'))])))));final stats=Map<String,dynamic>.from(data?['stats']??{}),incoming=(data?['incoming'] as List?)??[],queue=(data?['queue'] as List?)??[],events=(data?['events'] as List?)??[];return Scaffold(appBar:AppBar(title:const Text('WhatsApp Cloud API')),backgroundColor:bg,body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
  const PageTitle('WhatsApp Cloud API',subtitle:'Meta bağlantısı, template ayarları, testler, mesaj kuyruğu ve webhook hareketleri'),
  IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Expanded(child:MetricCard(label:'Cloud API',value:active?'Aktif':'Pasif',icon:Icons.cloud_done_rounded,color:active?success:orange)),const SizedBox(width:10),Expanded(child:MetricCard(label:'Gelen Mesaj',value:'${stats['incoming']??0}',icon:Icons.mark_chat_unread_rounded,color:blue))])),
  const SizedBox(height:14),
  _section('Bağlantı','Callback URL: ${data?['callback']??''}',Column(children:[
    _field(phone,'MleySoft WhatsApp Numarası'),_field(phoneId,'Phone Number ID'),_field(waba,'WABA ID'),_field(graph,'Graph API Version'),
    _field(token,'Access Token',secret:true,hint:tokenSaved?'Token kayıtlı — değiştirmek için yenisini girin':'Kalıcı System User token'),
    _field(verify,'Webhook Verify Token',secret:true),
    _field(secret,'Meta App Secret',secret:true,hint:secretSaved?'Secret kayıtlı — değiştirmek için yenisini girin':'Meta App Secret'),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Meta Cloud API gönderimini aktif et',style:TextStyle(fontWeight:FontWeight.w800)),value:active,onChanged:(v)=>setState(()=>active=v)),
  ]),icon:Icons.chat_rounded),
  _section('Aidat Ödeme Template','Ödeme kaydı sonrasında gönderilen onaylı Utility template',Column(children:[_field(payName,'Template Adı'),_field(payLang,'Template Dili'),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Otomatik gönder',style:TextStyle(fontWeight:FontWeight.w800)),value:payEnabled,onChanged:(v)=>setState(()=>payEnabled=v))]),icon:Icons.receipt_long_rounded),
  _section('Daire Giriş Template','WhatsApp OTP / giriş anahtarı template ayarları',Column(children:[_field(credName,'Template Adı'),_field(credLang,'Template Dili'),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Giriş mesajlarını otomatik gönder',style:TextStyle(fontWeight:FontWeight.w800)),value:credEnabled,onChanged:(v)=>setState(()=>credEnabled=v))]),icon:Icons.key_rounded),
  _section('Aidat Hesaplandı Template','Aidat hesaplama tamamlandığında gönderilen template',Column(children:[_field(dueName,'Template Adı'),_field(dueLang,'Template Dili'),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Aidat mesajını otomatik gönder',style:TextStyle(fontWeight:FontWeight.w800)),value:dueEnabled,onChanged:(v)=>setState(()=>dueEnabled=v))]),icon:Icons.calculate_rounded),
  SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:save,icon:const Icon(Icons.save_rounded),label:Text(saving?'Kaydediliyor...':'WhatsApp Ayarlarını Kaydet'))),
  const SizedBox(height:14),
  _section('Bağlantı ve Mesaj Testleri','Web yönetimindeki test işlemleri',Wrap(spacing:8,runSpacing:8,children:[
    OutlinedButton.icon(onPressed:()=>action('whatsapp_test_connection'),icon:const Icon(Icons.cable_rounded),label:const Text('Bağlantıyı Test Et')),
    OutlinedButton.icon(onPressed:()=>action('whatsapp_template_status'),icon:const Icon(Icons.cloud_done_rounded),label:const Text('Template Durumu')),
    OutlinedButton.icon(onPressed:templateTest,icon:const Icon(Icons.send_rounded),label:const Text('Template Test')),
    OutlinedButton.icon(onPressed:textTest,icon:const Icon(Icons.chat_bubble_outline_rounded),label:const Text('Metin Test')),
    OutlinedButton.icon(onPressed:()=>action('whatsapp_send_pending'),icon:const Icon(Icons.outbox_rounded),label:const Text('Bekleyenleri Gönder')),
  ]),icon:Icons.science_rounded),
  _logSection('Gelen WhatsApp Mesajları',incoming,(r)=>'${r['profile_name']??r['from_phone']} • ${r['message_type']}',(r)=>'${r['message_text']??''}\n${r['received_at']??''}',Icons.mark_chat_unread_rounded),
  _logSection('Gönderim Kuyruğu',queue,(r)=>'${r['site_name']} • ${r['block_name']??''} / Daire ${r['door_no']??'-'}',(r)=>'${r['recipient_phone']} • ${r['status']} • ${r['created_at']}',Icons.outbox_rounded),
  _logSection('Webhook Son Hareketler',events,(r)=>'${r['event_type']} • ${r['source_phone_number_id']??''}',(r)=>_on(r['processed'])?'İşlendi • ${r['created_at']}':'Hata: ${r['error_message']??''}',Icons.webhook_rounded),
 ])));}}
Widget _logSection(String title,List rows,String Function(Map r) titleOf,String Function(Map r) subOf,IconData icon)=>_section(title,'Son ${rows.length} kayıt',rows.isEmpty?const Padding(padding:EdgeInsets.all(10),child:Text('Henüz kayıt yok.',style:TextStyle(color:muted))):Column(children:rows.map((x){final r=Map<String,dynamic>.from(x);return ListTile(contentPadding:EdgeInsets.zero,leading:Icon(icon,size:20),title:Text(titleOf(r),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subOf(r),maxLines:3,overflow:TextOverflow.ellipsis));}).toList()),icon:icon);

class AdminBanksPage extends StatefulWidget{const AdminBanksPage({super.key});@override State<AdminBanksPage> createState()=>_AdminBanksPageState();}
class _AdminBanksPageState extends State<AdminBanksPage>{bool busy=true;List items=[];@override void initState(){super.initState();load();}Future<void>load()async{try{items=(await Api.request('admin?action=banks'))['items']??[];}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{busy=false;if(mounted)setState((){});}}Future<void>toggle(Map r)async{try{await Api.request('admin',method:'POST',body:{'action':'toggle_bank','bank_code':r['bank_code']});await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Banka Entegrasyonları')),backgroundColor:bg,body:busy?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[const PageTitle('Banka Entegrasyonları',subtitle:'Yöneticilerin görebileceği bankaları yönetin. API anahtarları site yöneticisinde tutulur.'),...items.map((x){final r=Map<String,dynamic>.from(x);final enabled=_on(r['is_active']);return Padding(padding:const EdgeInsets.only(bottom:8),child:SoftCard(child:SwitchListTile(contentPadding:EdgeInsets.zero,secondary:const IconBubble(Icons.account_balance_rounded,violet),title:Text('${r['bank_name']}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r['bank_code']}',style:const TextStyle(color:muted,fontSize:11)),value:enabled,onChanged:(_)=>toggle(r))));})])));}

class AdminSystemSettingsPage extends StatefulWidget{const AdminSystemSettingsPage({super.key});@override State<AdminSystemSettingsPage> createState()=>_AdminSystemSettingsPageState();}
class _AdminSystemSettingsPageState extends State<AdminSystemSettingsPage>{
 Map<String,dynamic>? firebase;final json=TextEditingController();bool busy=true,saving=false;
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{firebase=Map<String,dynamic>.from((await Api.request('admin?action=system_settings'))['firebase']??{});}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{busy=false;if(mounted)setState((){});}}
 Future<void>saveJson()async{if(json.text.trim().isEmpty){_snack(context,'Service Account JSON içeriğini yapıştırın.',error:true);return;}setState(()=>saving=true);try{final d=await Api.request('admin',method:'POST',body:{'action':'firebase_service_json','service_account_json':json.text});if(mounted)_snack(context,'${d['message']}');json.clear();await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}finally{if(mounted)setState(()=>saving=false);}}
 Future<void>disable()async{try{final d=await Api.request('admin',method:'POST',body:{'action':'firebase_disable'});if(mounted)_snack(context,'${d['message']}');await load();}catch(e){if(mounted)_snack(context,_err(e),error:true);}}
 @override Widget build(BuildContext c)=>busy?const Center(child:BrandLoader()):ListView(padding:const EdgeInsets.all(20),children:[
  const PageTitle('Sistem Ayarları',subtitle:'MleySoft Aidat sistem ve mobil bildirim ayarlarını merkezi yönetin'),
  _section('Firebase Bildirim Ayarları','Webdeki Service Account JSON kurulumunun mobil karşılığı',Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Row(children:[Expanded(child:Text('Proje: ${firebase?['project_id']??'Henüz yapılandırılmadı'}',style:const TextStyle(fontWeight:FontWeight.w800))),StatusPill(_on(firebase?['is_active'])?'Aktif':'Pasif',_on(firebase?['is_active'])?success:muted)]),
   const SizedBox(height:8),Text('Service Account: ${firebase?['client_email']??'Henüz yapılandırılmadı'}',style:const TextStyle(color:muted,fontSize:12)),
   const SizedBox(height:16),const Text('Service Account JSON',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:5),
   const Text('Mobilde dosya içeriğini Firebase Console’dan indirdiğiniz JSON’dan yapıştırın. Project ID, Client Email ve Private Key otomatik okunur; gizli anahtar ekranda geri gösterilmez.',style:TextStyle(color:muted,fontSize:12)),
   const SizedBox(height:10),TextField(controller:json,minLines:7,maxLines:14,autocorrect:false,enableSuggestions:false,style:const TextStyle(fontFamily:'monospace',fontSize:11),decoration:const InputDecoration(hintText:'{\n  "type": "service_account",\n  ...\n}')),
   const SizedBox(height:12),FilledButton.icon(onPressed:saving?null:saveJson,icon:const Icon(Icons.cloud_upload_rounded),label:Text(saving?'Yapılandırılıyor...':'JSON ile Otomatik Yapılandır')),
   if(_on(firebase?['is_active']))Padding(padding:const EdgeInsets.only(top:8),child:OutlinedButton.icon(onPressed:disable,icon:const Icon(Icons.pause_circle_outline_rounded),label:const Text('Firebase Gönderimini Pasif Yap')))
  ]),icon:Icons.local_fire_department_rounded)
 ]);}

class AdminSystemInfoPage extends StatefulWidget{const AdminSystemInfoPage({super.key});@override State<AdminSystemInfoPage> createState()=>_AdminSystemInfoPageState();}
class _AdminSystemInfoPageState extends State<AdminSystemInfoPage>{Map<String,dynamic>? d;@override void initState(){super.initState();load();}Future<void>load()async{try{d=await Api.request('admin?action=system_info');}catch(e){if(mounted)_snack(context,_err(e),error:true);}if(mounted)setState((){});}@override Widget build(BuildContext c){if(d==null)return const Center(child:BrandLoader());final checks=(d!['checks'] as List?)??[],cron=Map<String,dynamic>.from(d!['cron']??{});return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
 const PageTitle('Bilgilendirme',subtitle:'Sunucu / cPanel gereksinimleri ve zamanlanmış görev bilgileri'),
 ...checks.map((x){final r=Map<String,dynamic>.from(x);final ok=_on(r['ready']);return Padding(padding:const EdgeInsets.only(bottom:8),child:SoftCard(child:Row(children:[IconBubble(ok?Icons.check_circle_rounded:Icons.error_outline_rounded,ok?success:danger),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['name']}',style:const TextStyle(fontWeight:FontWeight.w900)),Text('${r['detail']}',style:const TextStyle(color:muted,fontSize:12))])),StatusPill(ok?'Hazır':'Kontrol Edin',ok?success:danger)])));}),
 const SizedBox(height:10),_section('Zamanlanmış Görevler','cPanel Cron Jobs',Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${cron['file']??'cron/daily.php'}',style:const TextStyle(fontFamily:'monospace',fontWeight:FontWeight.w900)),const SizedBox(height:8),Text('${cron['message']??''}',style:const TextStyle(fontSize:12,height:1.45)),const SizedBox(height:10),Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFFFF7E6),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFFED7AA))),child:Text('${cron['security']??''}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)))]),icon:Icons.schedule_rounded)
 ]));}}

Future<bool> _sheet(BuildContext c,String title,List<Widget> fields)async=>await showModalBottomSheet<bool>(context:c,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(x)=>Container(constraints:BoxConstraints(maxHeight:MediaQuery.of(x).size.height*.88),padding:EdgeInsets.fromLTRB(20,20,20,20+MediaQuery.of(x).viewInsets.bottom),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(x,false),icon:const Icon(Icons.close))]),const SizedBox(height:14),...fields.expand((w)=>[w,const SizedBox(height:10)]),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Devam Et'))]))))??false;
