import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/loading.dart';
import '../core/ui.dart';
import '../core/push.dart';
import 'login.dart';

String money(dynamic v)=>'${(double.tryParse('$v')??0).toStringAsFixed(2)} ₺';
Future<bool> requireManagerPackage(BuildContext context) async {
  if(Api.managerPackageActive!=false)return true;
  await showDialog<void>(context:context,builder:(c)=>AlertDialog(
    icon:const Icon(Icons.lock_outline_rounded,color:orange,size:34),
    title:const Text('Paket aktivasyonu gerekli'),
    content:const Text('Hesap planınız aktif değil. Mobil uygulama üzerinden plan satın alma veya abonelik ödemesi yapılmaz. Plan aktif olana kadar sistemi inceleyebilirsiniz ancak kayıt değiştiren işlemler kapalıdır.'),
    actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Tamam'))],
  ));
  return false;
}
class ManagerShell extends StatefulWidget{const ManagerShell({super.key});@override State<ManagerShell> createState()=>_ManagerShellState();}
class _ManagerShellState extends State<ManagerShell>{
 int i=0;bool loading=true,portfolio=false;bool? subscriptionActive;String activeSiteName='';
 final allPages=const [ManagerDashboard(),ManagerSitesPage(),BlocksPage(),ApartmentsPage(),ResidentsManagerPage(),NativeListPage(kind:'dues',title:'Aidatlar'),NativeListPage(kind:'payments',title:'Tahsilatlar'),ExpensesPage(),AnnouncementsManagerPage(),TicketsManagerPage(),FinancePage(),ReportsManagerPage(),ManagerSubscriptionPage(),NotificationsManagerPage(),AutomationManagerPage(),CardPaymentIntegrationPage()];
 final allLabels=['Genel Bakış','Siteler','Bloklar','Daireler','Kat Malikleri','Aidatlar','Tahsilatlar','Giderler','Duyurular','Talepler','Kasa & Banka','Raporlar','Plan Durumu','Bildirimler','Otomasyon Ayarları','Sanal POS Entegrasyonu'];
 final allIcons=[Icons.grid_view_rounded,Icons.location_city_rounded,Icons.apartment_rounded,Icons.meeting_room_rounded,Icons.groups_rounded,Icons.account_balance_wallet_rounded,Icons.payments_rounded,Icons.receipt_long_rounded,Icons.campaign_rounded,Icons.build_circle_rounded,Icons.account_balance_rounded,Icons.analytics_rounded,Icons.credit_card_rounded,Icons.notifications_active_rounded,Icons.auto_awesome_rounded,Icons.credit_card_rounded];
 @override void initState(){super.initState();boot();}
 Future<void>boot()async{try{final d=await Api.request('manager-sites?action=list');portfolio=d['portfolio_enabled']==true&&d['selected_site_id']==null;if(!portfolio){try{final x=await Api.request('manager?action=dashboard');subscriptionActive=x['subscription_active']==true;Api.managerPackageActive=subscriptionActive;activeSiteName='${x['profile']?['site_name']??''}'.trim();}catch(_){}}else{activeSiteName='';}}catch(_){portfolio=false;}loading=false;if(mounted)setState((){});}
 Future<void>logout()async{await PushService.deactivateForLogout();try{await Api.request('logout',method:'POST');}catch(_){}await Api.clear();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
 @override Widget build(BuildContext c){
  if(loading)return const Scaffold(backgroundColor:Colors.white,body:BrandLoader());
  final pages=portfolio?const [ManagerPortfolioDashboard(),ManagerSitesPage(),ManagerSubscriptionPage()]:allPages;
  final labels=portfolio?['Yönetim Merkezi','Siteler','Plan Durumu']:allLabels;
  final icons=portfolio?[Icons.grid_view_rounded,Icons.location_city_rounded,Icons.credit_card_rounded]:allIcons;
  if(i>=pages.length)i=0;
  return Scaffold(
    backgroundColor:bg,
    appBar:AppBar(
      toolbarHeight:70,
      backgroundColor:Colors.white,
      leading:Builder(builder:(c)=>IconButton(tooltip:'Menü',icon:const Icon(Icons.menu_rounded),onPressed:()=>Scaffold.of(c).openDrawer())),
      titleSpacing:0,
      title:Row(children:[
        ClipRRect(borderRadius:BorderRadius.circular(9),child:Image.asset('assets/images/aidat_icon.png',width:34,height:34,fit:BoxFit.cover)),
        const SizedBox(width:9),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('MleySoft',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:ink,letterSpacing:-.25)),
          const SizedBox(height:1),
          Text(labels[i],maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:muted,fontWeight:FontWeight.w700))
        ]))
      ]),
      actions:portfolio?[]:[Container(margin:const EdgeInsets.only(right:12),decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(14)),child:IconButton(tooltip:'Bildirimler',onPressed:()=>setState(()=>i=13),icon:const Icon(Icons.notifications_none_rounded,color:ink,size:20)))],
      bottom:const PreferredSize(preferredSize:Size.fromHeight(1),child:Divider(height:1,color:line)),
    ),
    drawer:Drawer(
      width:310,
      backgroundColor:Colors.white,
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.horizontal(right:Radius.circular(26))),
      child:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(18,18,18,14),child:Row(children:[
          ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.asset('assets/images/aidat_icon.png',width:44,height:44)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('MleySoft Aidat',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:ink)),
            Text(portfolio?'Yönetim Merkezi':(activeSiteName.isEmpty?'Site Yönetimi':activeSiteName),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:muted,fontWeight:FontWeight.w600))
          ]))
        ])),
        const Divider(height:1),
        Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(10,12,10,8),children:List.generate(labels.length,(x)=>Padding(
          padding:const EdgeInsets.only(bottom:3),
          child:ListTile(
            selected:i==x,
            selectedTileColor:brand.withValues(alpha:.16),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
            leading:Icon(icons[x],color:i==x?ink:muted),
            title:Text(labels[x],style:TextStyle(fontWeight:i==x?FontWeight.w900:FontWeight.w700,color:i==x?ink:const Color(0xFF344054))),
            trailing:i==x?Container(width:6,height:6,decoration:const BoxDecoration(color:brandDark,shape:BoxShape.circle)):null,
            onTap:(){setState(()=>i=x);Navigator.pop(c);}
          )
        )))),
        Padding(padding:const EdgeInsets.all(12),child:ListTile(
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
          tileColor:danger.withValues(alpha:.06),
          leading:const Icon(Icons.logout_rounded,color:danger),
          title:const Text('Güvenli Çıkış',style:TextStyle(color:danger,fontWeight:FontWeight.w800)),
          onTap:logout
        ))
      ]))
    ),
    body:Column(children:[
      if(!portfolio)Container(
        width:double.infinity,
        margin:const EdgeInsets.fromLTRB(12,8,12,4),
        padding:const EdgeInsets.fromLTRB(12,10,10,10),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:line),boxShadow:const[BoxShadow(color:Color(0x07101828),blurRadius:12,offset:Offset(0,3))]),
        child:Row(children:[
          Container(width:36,height:36,decoration:BoxDecoration(color:brand.withValues(alpha:.22),borderRadius:BorderRadius.circular(11)),child:const Icon(Icons.apartment_rounded,size:19,color:ink)),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('AKTİF YÖNETİM ALANI',style:TextStyle(fontSize:9,color:muted,fontWeight:FontWeight.w900,letterSpacing:.55)),
            const SizedBox(height:2),
            Text(activeSiteName.isEmpty?'Seçili Site':activeSiteName,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13.5,fontWeight:FontWeight.w900,color:ink,letterSpacing:-.15)),
          ])),
          Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:success.withValues(alpha:.09),borderRadius:BorderRadius.circular(999)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.verified_rounded,size:13,color:success),SizedBox(width:4),Text('Aktif',style:TextStyle(fontSize:10,color:success,fontWeight:FontWeight.w900))]))
        ])
      ),
      if(!portfolio&&subscriptionActive==false)Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),color:const Color(0xFFFFEBDD),child:const Row(children:[Icon(Icons.lock_outline_rounded,size:17,color:orange),SizedBox(width:7),Expanded(child:Text('Paketiniz aktif değil. Sistemi inceleyebilirsiniz; kayıt değiştiren işlemler kapalıdır.',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w800,color:ink)))])),
      Expanded(child:pages[i])
    ])
  );
 }
}
class ManagerPortfolioDashboard extends StatefulWidget{const ManagerPortfolioDashboard({super.key});@override State<ManagerPortfolioDashboard> createState()=>_ManagerPortfolioDashboardState();}
class _ManagerPortfolioDashboardState extends State<ManagerPortfolioDashboard>{Map<String,dynamic>? d;bool switching=false;@override void initState(){super.initState();load();}Future<void>load()async{d=await Api.request('manager-sites?action=list');if(mounted)setState((){});}Future<void>openSite(Map r)async{if(switching)return;setState(()=>switching=true);try{final x=await Api.request('manager-sites',method:'POST',body:{'action':'switch','site_id':r['id']});await Api.saveToken('${x['token']}');await PushService.syncToken();if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const ManagerShell()),(_)=>false);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>switching=false);}}@override Widget build(BuildContext c){if(d==null)return const Center(child:BrandLoader());final items=d!['items'] as List;return Stack(children:[RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('Yönetim Merkezi',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Aşağıdaki sitelerden birine dokunarak doğrudan site yönetimine girebilirsiniz.',style:TextStyle(color:muted)),const SizedBox(height:18),SoftCard(child:Row(children:[const IconBubble(Icons.business_rounded,blue),const SizedBox(width:12),Expanded(child:Text('Kayıtlı site: ${items.length}   •   Paket limiti: ${d!['max_sites']??'Sınırsız'}',style:const TextStyle(fontWeight:FontWeight.w900)))])),const SizedBox(height:14),...items.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:SoftCard(onTap:()=>openSite(Map<String,dynamic>.from(r)),child:ListTile(contentPadding:EdgeInsets.zero,leading:const IconBubble(Icons.location_city_rounded,success),title:Text('${r['name']}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r['apartment_count']} daire • Site yönetimine girmek için dokunun'),trailing:const Icon(Icons.login_rounded)))))])),if(switching)const Positioned.fill(child:ColoredBox(color:Color(0x44FFFFFF),child:Center(child:CircularProgressIndicator()))) ]);}}
class ManagerSitesPage extends StatefulWidget{const ManagerSitesPage({super.key});@override State<ManagerSitesPage> createState()=>_ManagerSitesPageState();}
class _ManagerSitesPageState extends State<ManagerSitesPage>{bool busy=true,owner=false;List items=[];Map data={};@override void initState(){super.initState();load();}Future<void>load()async{data=await Api.request('manager-sites?action=list');items=data['items']??[];owner=data['owner']==true;busy=false;if(mounted)setState((){});}Future<void>open(Map r)async{final d=await Api.request('manager-sites',method:'POST',body:{'action':'switch','site_id':r['id']});await Api.saveToken('${d['token']}');await PushService.syncToken();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const ManagerShell()),(_)=>false);}Future<void>add()async{final n=TextEditingController(),p=TextEditingController(),d=TextEditingController();final ok=await form(context,'Yeni Site Ekle',[TextField(controller:n,decoration:const InputDecoration(labelText:'Site Adı')),TextField(controller:p,decoration:const InputDecoration(labelText:'İl')),TextField(controller:d,decoration:const InputDecoration(labelText:'İlçe'))]);if(ok){await Api.request('manager-sites',method:'POST',body:{'action':'create','name':n.text,'province':p.text,'district':d.text});await load();}}
Future<void>assign(Map r)async{final e=TextEditingController(),n=TextEditingController(),pw=TextEditingController();final ok=await form(context,'Yeni Yönetici Tanımla',[const Text('Her e-posta sistemde yalnızca bir kullanıcı hesabına ait olabilir.',style:TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w700)),TextField(controller:n,decoration:const InputDecoration(labelText:'Ad Soyad')),TextField(controller:e,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),TextField(controller:pw,obscureText:true,decoration:const InputDecoration(labelText:'Geçici Şifre (en az 6 karakter)'))]);if(ok){await Api.request('manager-sites',method:'POST',body:{'action':'assign','site_id':r['id'],'email':e.text,'name':n.text,'password':pw.text});await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Yönetici oluşturuldu.')));}}
Future<void>editManager(Map site,Map m)async{final e=TextEditingController(text:'${m['email']??''}'),n=TextEditingController(text:'${m['full_name']??''}'),pw=TextEditingController();final ok=await form(context,'Yönetici Düzenle',[TextField(controller:n,decoration:const InputDecoration(labelText:'Ad Soyad')),TextField(controller:e,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),TextField(controller:pw,obscureText:true,decoration:const InputDecoration(labelText:'Yeni Şifre (değişmeyecekse boş)'))]);if(ok){await Api.request('manager-sites',method:'POST',body:{'action':'manager_update','site_id':site['id'],'manager_id':m['id'],'email':e.text,'name':n.text,'password':pw.text});await load();}}
Future<void>removeManager(Map site,Map m)async{if(!await confirm(context))return;await Api.request('manager-sites',method:'POST',body:{'action':'manager_remove','site_id':site['id'],'manager_id':m['id']});await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Yönetici bu siteden kaldırıldı.')));}
@override Widget build(BuildContext c)=>busy?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[Row(children:[const Expanded(child:Text('Siteler',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))),if(owner)FilledButton.icon(onPressed:add,icon:const Icon(Icons.add_business_rounded),label:const Text('Yeni Site Ekle'))]),const SizedBox(height:12),SoftCard(child:Text('Paket: ${data['package_name']??'-'}   •   Site: ${items.length}/${data['max_sites']??'∞'}   •   Daire/site: ${data['max_apartments']??'∞'}',style:const TextStyle(fontWeight:FontWeight.w800))),const SizedBox(height:12),...items.map((r){final managers=(r['managers'] as List?)??[];return Padding(padding:const EdgeInsets.only(bottom:12),child:SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[ListTile(contentPadding:EdgeInsets.zero,leading:const IconBubble(Icons.location_city_rounded,success),title:Text('${r['name']}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r['apartment_count']} daire • ${managers.length} yönetici')),const Text('SITE YÖNETİCİLERİ',style:TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:muted)),const SizedBox(height:6),if(managers.isEmpty)Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(12)),child:const Text('Tanımlı alt yönetici yok. Ana yönetici siteyi yönetebilir.',style:TextStyle(fontSize:12,color:muted))) else ...managers.map((m)=>Container(margin:const EdgeInsets.only(bottom:6),padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.person_outline_rounded,size:20),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${m['full_name']}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${m['email']??''}',style:const TextStyle(fontSize:11,color:muted))])),if(owner)IconButton(onPressed:()=>editManager(r,m),icon:const Icon(Icons.edit_outlined,size:20)),if(owner)IconButton(onPressed:()=>removeManager(r,m),icon:const Icon(Icons.delete_outline_rounded,size:20,color:danger))]))),const SizedBox(height:10),FilledButton(onPressed:()=>open(r),child:const Text('Siteye Giriş Yap')),if(owner)...[const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>assign(r),icon:const Icon(Icons.person_add_alt_1_rounded),label:const Text('Yeni Yönetici Tanımla'))]])));})]));}

class ManagerSubscriptionPage extends StatefulWidget{const ManagerSubscriptionPage({super.key});@override State<ManagerSubscriptionPage> createState()=>_ManagerSubscriptionPageState();}
class _ManagerSubscriptionPageState extends State<ManagerSubscriptionPage>{
 Map<String,dynamic>? d;String? error;bool busy=false;
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{d=await Api.request('manager-subscription');error=null;}catch(e){error='$e'.replaceFirst('Exception: ','');}if(mounted)setState((){});}
 Future<void>selectPackage(Map p)async{if(p['capacity_error']!=null)return;setState(()=>busy=true);try{await Api.request('manager-subscription',method:'POST',body:{'action':'select_package','package_id':p['id']});await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>busy=false);}}
 Future<void>notice()async{final latest=Map<String,dynamic>.from(d?['latest']??{});final bank=TextEditingController(),amount=TextEditingController(text:'${latest['amount']??latest['package_price']??''}'),note=TextEditingController();final ok=await form(context,'Ödeme Bildirimi',[Text('Referans: ${latest['reference_code']??''}',style:const TextStyle(fontWeight:FontWeight.w800)),TextField(controller:bank,decoration:const InputDecoration(labelText:'Gönderen Banka')),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Tutar')),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Not'))]);if(ok){await Api.request('manager-subscription',method:'POST',body:{'action':'payment_notice','sender_name':'Yönetici','sender_bank':bank.text,'amount':amount.text,'transfer_date':DateTime.now().toIso8601String().substring(0,10),'note':note.text});await load();}}
 @override Widget build(BuildContext c){if(d==null&&error==null)return const Center(child:BrandLoader());if(error!=null)return Center(child:Text(error!));if(Platform.isIOS){final active=Map<String,dynamic>.from(d!['active']??{}),usage=Map<String,dynamic>.from(d!['usage']??{});return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[head('Plan Durumu',null),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[IconBubble(Icons.verified_user_rounded,blue),SizedBox(width:10),Expanded(child:Text('Kuruluş Hesabı Planı',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)))]),const SizedBox(height:12),Text('Aktif plan: ${active['allowed']==true?active['package_name']:'Aktif plan bulunmuyor'}',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:6),Text('Kalan gün: ${d!['days_remaining']??'—'}',style:const TextStyle(color:muted)),const SizedBox(height:6),Text('Kullanım: ${usage['site_count']??0} site • ${usage['apartment_count']??0} daire',style:const TextStyle(color:muted)),const Divider(height:28),const Text('Bu mobil uygulama site yönetimi ve daire sakinlerinin mevcut hesaplarına erişmesi içindir. iOS uygulamasında MleySoft yazılım planı satın alma, plan yükseltme veya abonelik ödemesi yapılmaz.',style:TextStyle(fontSize:12.5,color:muted,height:1.45))]))]));}final active=Map<String,dynamic>.from(d!['active']??{}),latest=Map<String,dynamic>.from(d!['latest']??{}),usage=Map<String,dynamic>.from(d!['usage']??{});final packages=(d!['packages'] as List?)??[];return Stack(children:[RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[head('Paket / Ödeme',null),SoftCard(child:Wrap(spacing:16,runSpacing:8,children:[Text('Aktif paket: ${active['allowed']==true?active['package_name']:'—'}',style:const TextStyle(fontWeight:FontWeight.w900)),Text('Kalan gün: ${d!['days_remaining']??'—'}',style:const TextStyle(fontWeight:FontWeight.w900)),Text('Site: ${usage['site_count']}/${(latest['status']=='pending'?latest['max_sites']:active['max_sites'])??'∞'}',style:const TextStyle(fontWeight:FontWeight.w900)),Text('Daire/site: ${usage['apartment_count']}/${(latest['status']=='pending'?latest['max_apartments']:active['max_apartments'])??'∞'}',style:const TextStyle(fontWeight:FontWeight.w900))])),const SizedBox(height:14),const Text('Paketler',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:8),...packages.map((x){final p=Map<String,dynamic>.from(x);final disabled=p['capacity_error']!=null;return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:Text('${p['name']}',style:const TextStyle(fontWeight:FontWeight.w900))),Text(money(p['price']),style:const TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:4),Text('${p['description']??''}',style:const TextStyle(color:muted,fontSize:12)),const SizedBox(height:8),Text('${p['billing_months']} ay • Site ${p['max_sites']??'∞'} • Daire/site ${p['max_apartments']??'∞'}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),if(disabled)Padding(padding:const EdgeInsets.only(top:6),child:Text('${p['capacity_error']}',style:const TextStyle(color:danger,fontSize:11))),const SizedBox(height:10),FilledButton(onPressed:disabled?null:()=>selectPackage(p),child:const Text('Paketi Seç'))])));}),if(latest['status']=='pending')...[const SizedBox(height:16),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Ödeme Bekliyor • ${latest['package_name']}',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('Referans: ${latest['reference_code']}',style:const TextStyle(fontSize:12)),const SizedBox(height:5),Text('IBAN: ${d!['bank']?['iban']??'Tanımlı değil'}',style:const TextStyle(fontSize:12)),const SizedBox(height:12),FilledButton(onPressed:d!['pending_notice']==true?null:notice,child:Text(d!['pending_notice']==true?'Onay Bekleniyor':'Ödeme Bildirimi Gönder'))]))]])),if(busy)const Positioned.fill(child:ColoredBox(color:Color(0x55FFFFFF),child:Center(child:CircularProgressIndicator())))]);}
}

class ManagerDashboard extends StatefulWidget{const ManagerDashboard({super.key});@override State<ManagerDashboard> createState()=>_ManagerDashboardState();}
class _ManagerDashboardState extends State<ManagerDashboard>{Map<String,dynamic>? d;String? error;@override void initState(){super.initState();load();}Future<void>load()async{try{d=await Api.request('manager?action=dashboard');error=null;}catch(e){error='$e';}if(mounted)setState((){});}@override Widget build(BuildContext c){if(d==null&&error==null)return const Center(child:BrandLoader());if(error!=null)return Center(child:Text(error!));final s=d!['stats'] as Map<String,dynamic>;final cards=[['Toplam Borç',money(s['debt']),Icons.wallet_rounded,danger],['Bu Ay Tahsilat',money(s['month_income']),Icons.trending_up_rounded,success],['Bu Ay Gider Planı',money(s['month_expense']),Icons.trending_down_rounded,orange],['Açık Talep','${s['open_tickets']}',Icons.support_agent_rounded,violet]];return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:32),children:[PageTitle('Genel Bakış',subtitle:'${d!['profile']?['site_name'] ?? 'Site Yönetimi'} • ${d!['profile']?['name'] ?? 'Yönetici'}'),if(d!['subscription_active']!=true)Padding(padding:const EdgeInsets.fromLTRB(20,0,20,14),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:orange.withValues(alpha:.12),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.info_outline_rounded,color:orange),SizedBox(width:9),Expanded(child:Text('Hesap planınız aktif değil. Mobil uygulama plan satın alma veya abonelik ödemesi sunmaz. Plan aktif olana kadar kayıt ekleme ve düzenleme kapalıdır.',style:TextStyle(fontWeight:FontWeight.w700,color:ink)))]))),Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[ink,Color(0xFF344054)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(26),boxShadow:const [BoxShadow(color:Color(0x24101828),blurRadius:25,offset:Offset(0,12))]),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${d!['profile']?['site_name'] ?? 'Yönetim Merkezi'}',style:const TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text('${d!['profile']?['name'] ?? 'Yönetici'} • Bina Yöneticisi',style:const TextStyle(color:Color(0xFFCFD4DC),fontSize:12,fontWeight:FontWeight.w600))])),Container(width:54,height:54,decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.auto_graph_rounded,color:ink,size:28))]))),const SizedBox(height:16),Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.18,crossAxisSpacing:12,mainAxisSpacing:12),itemCount:cards.length,itemBuilder:(c,i)=>MetricCard(label:'${cards[i][0]}',value:'${cards[i][1]}',icon:cards[i][2] as IconData,color:cards[i][3] as Color))),Padding(padding:const EdgeInsets.fromLTRB(20,24,20,10),child:Row(children:[const Expanded(child:Text('Son Tahsilatlar',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:ink))),StatusPill('${s['apartments']} daire',blue)])),...(d!['recent'] as List).map((r)=>Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:SoftCard(child:Row(children:[const IconBubble(Icons.payments_rounded,success),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['block_name']} • Daire ${r['door_no']}',style:const TextStyle(fontWeight:FontWeight.w800,color:ink)),const SizedBox(height:4),Text('${r['payment_date']}  •  ${detailStatus(r['payment_method'])}',style:const TextStyle(fontSize:12,color:muted))])),Text(money(r['amount']),style:const TextStyle(fontWeight:FontWeight.w900,color:success))]))))]));}}
abstract class ReloadPage<T extends StatefulWidget> extends State<T>{bool busy=true;List items=[];Future<void>load();Widget body();@override Widget build(BuildContext c)=>busy?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:body());}
class BlocksPage extends StatefulWidget {
  const BlocksPage({super.key});
  @override State<BlocksPage> createState()=>_BlocksPageState();
}
class _BlocksPageState extends ReloadPage<BlocksPage> {
  @override void initState(){super.initState();load();}
  @override Future<void> load() async { final d=await Api.request('manager?action=blocks'); items=d['items']; busy=false; if(mounted)setState((){}); }
  Future<void> edit([Map? r]) async {
    if(!await requireManagerPackage(context))return;
    final n=TextEditingController(text:'${r?['name']??''}');
    final desc=TextEditingController(text:'${r?['description']??''}');
    final ok=await form(context,r==null?'Yeni Blok':'Blok Düzenle',[
      TextField(controller:n,decoration:const InputDecoration(labelText:'Blok Adı')),
      TextField(controller:desc,decoration:const InputDecoration(labelText:'Açıklama')),
    ]);
    if(ok){await Api.request('manager',method:'POST',body:{'action':'save_block','id':r?['id']??0,'name':n.text,'description':desc.text});await load();}
  }
  @override Widget body()=>ListView(
    padding:const EdgeInsets.all(16),
    children:[
      head('Bloklar',()=>edit()),
      ...items.map((r)=>Card(
        child:ListTile(
          title:Text(r['name'],style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text('${r['apartment_count']} daire · ${r['description']??''}'),
          onTap:()=>edit(r),
          trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:() async {
            if(!await requireManagerPackage(context))return;
            if(await confirm(context)){await Api.request('manager',method:'POST',body:{'action':'delete_block','id':r['id']});await load();}
          }),
        ),
      )),
    ],
  );
}
class ApartmentsPage extends StatefulWidget {
  const ApartmentsPage({super.key});
  @override
  State<ApartmentsPage> createState() => _ApartmentsPageState();
}

class _ApartmentsPageState extends ReloadPage<ApartmentsPage> {
  List blocks = [];
  double totalDebt = 0;
  String query = '';
  String blockFilter = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<void> load() async {
    final d = await Api.request('manager?action=apartments');
    items = d['items'] ?? [];
    blocks = d['blocks'] ?? [];
    totalDebt = double.tryParse('${d['total_debt'] ?? 0}') ?? 0;
    busy = false;
    if (mounted) setState(() {});
  }

  List get shown => items.where((r) {
        final q = query.trim().toLowerCase();
        final matchesBlock = blockFilter.isEmpty || '${r['block_id'] ?? ''}' == blockFilter;
        final haystack = '${r['block_name'] ?? ''} ${r['door_no'] ?? ''} ${r['floor_no'] ?? ''}'.toLowerCase();
        return matchesBlock && (q.isEmpty || haystack.contains(q));
      }).toList();

  Future<void> edit([Map? r]) async {
    if (!await requireManagerPackage(context)) return;
    if (blocks.isEmpty) return;
    int bid = int.tryParse('${r?['block_id'] ?? blocks.first['id']}')!;
    final door = TextEditingController(text: '${r?['door_no'] ?? ''}');
    final floor = TextEditingController(text: '${r?['floor_no'] ?? ''}');
    final ok = await form(context, r == null ? 'Yeni Daire' : 'Daire Düzenle', [
      DropdownButtonFormField<int>(
        initialValue: bid,
        items: blocks
            .map<DropdownMenuItem<int>>((x) => DropdownMenuItem(value: int.parse('${x['id']}'), child: Text('${x['name']}')))
            .toList(),
        onChanged: (v) => bid = v!,
        decoration: const InputDecoration(labelText: 'Blok'),
      ),
      TextField(controller: door, decoration: const InputDecoration(labelText: 'Daire No')),
      TextField(controller: floor, decoration: const InputDecoration(labelText: 'Kat')),
    ]);
    if (ok) {
      await Api.request('manager', method: 'POST', body: {
        'action': 'save_apartment',
        'id': r?['id'] ?? 0,
        'block_id': bid,
        'door_no': door.text,
        'floor_no': floor.text,
        'unit_type': r?['unit_type'] ?? 'residential',
      });
      load();
    }
  }

  @override
  Widget body() {
    final filtered = shown;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        head('Daireler', () => edit()),
        SummaryScroller(children: [
          CompactStatCard(
            label: 'Toplam Açık Borç',
            value: money(totalDebt),
            icon: Icons.account_balance_wallet_rounded,
            color: danger,
          ),
          CompactStatCard(
            label: 'Kayıtlı Daire',
            value: '${items.length}',
            icon: Icons.meeting_room_rounded,
            color: blue,
          ),
          CompactStatCard(
            label: 'Borçlu Daire',
            value: '${items.where((r) => (double.tryParse('${r['total_debt'] ?? 0}') ?? 0) > .009).length}',
            icon: Icons.notification_important_rounded,
            color: orange,
          ),
        ]),
        const SizedBox(height: 14),
        FilterSurface(
          subtitle: '${filtered.length} / ${items.length} daire gösteriliyor',
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                labelText: 'Daire ara',
                hintText: 'Blok, daire no veya kat',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            DropdownButtonFormField<String>(
              value: blockFilter,
              decoration: const InputDecoration(labelText: 'Blok filtresi'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm bloklar')),
                ...blocks.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['name']}'))),
              ],
              onChanged: (v) => setState(() => blockFilter = v ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionHeading(
          'Daire Borç Durumu',
          subtitle: 'Satıra dokunarak daire bilgilerini düzenleyebilirsiniz.',
        ),
        const SizedBox(height: 8),
        ProfessionalDataTable(
          minWidth: 760,
          columns: const [
            DataColumn(label: Text('DAİRE')),
            DataColumn(label: Text('KAT')),
            DataColumn(label: Text('TOPLAM BORÇ'), numeric: true),
            DataColumn(label: Text('DURUM')),
          ],
          rows: filtered.map<DataRow>((r) {
            final debt = double.tryParse('${r['total_debt'] ?? 0}') ?? 0;
            return DataRow(
              onSelectChanged: (_) => edit(r),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: TableText('${r['block_name']} / ${r['door_no']}', strong: true)),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Daireyi düzenle',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: () => edit(r),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
                DataCell(TableText('${r['floor_no'] ?? '-'}')),
                DataCell(TableAmount(money(debt), color: debt > .009 ? danger : success)),
                DataCell(StatusPill(debt > .009 ? 'BORÇLU' : 'BORÇ YOK', debt > .009 ? danger : success)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class NativeListPage extends StatefulWidget {
  final String kind, title;
  const NativeListPage({super.key, required this.kind, required this.title});
  @override
  State<NativeListPage> createState() => _NativeListPageState();
}

class _NativeListPageState extends ReloadPage<NativeListPage> {
  Map<String, dynamic> summary = {};
  List periods = [];
  List blocks = [];
  String period = '';
  String block = '';
  String status = 'all';
  DateTime? from, to;

  @override
  void initState() {
    super.initState();
    load();
  }

  String ds(DateTime? d) => d == null ? '' : d.toIso8601String().substring(0, 10);

  Future<void> pick(bool isFrom) async {
    final x = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (isFrom ? from : to) ?? DateTime.now(),
    );
    if (x == null) return;
    setState(() {
      if (isFrom) {
        from = x;
      } else {
        to = x;
      }
    });
    await load();
  }

  void resetFilters() {
    setState(() {
      period = '';
      block = '';
      status = 'all';
      from = null;
      to = null;
    });
    load();
  }

  @override
  Future<void> load() async {
    var q = 'manager?action=${widget.kind}';
    if (period.isNotEmpty) q += '&period=$period';
    if (block.isNotEmpty) q += '&block_id=$block';
    if (widget.kind == 'payments') {
      if (from != null) q += '&from=${ds(from)}';
      if (to != null) q += '&to=${ds(to)}';
    }
    final d = await Api.request(q);
    items = d['items'] ?? [];
    summary = Map<String, dynamic>.from(d['summary'] ?? {});
    periods = d['periods'] ?? [];
    blocks = d['blocks'] ?? [];
    busy = false;
    if (mounted) setState(() {});
  }

  List get shown {
    if (widget.kind != 'dues' || status == 'all') return items;
    return items.where((r) {
      final balance = double.tryParse('${r['balance'] ?? 0}') ?? 0;
      if (status == 'paid') return balance <= .009;
      return balance > .009;
    }).toList();
  }

  String dueStatus(Map r) {
    final total = double.tryParse('${r['total_amount'] ?? 0}') ?? 0;
    final paid = double.tryParse('${r['paid'] ?? 0}') ?? 0;
    final balance = double.tryParse('${r['balance'] ?? 0}') ?? 0;
    if (balance <= .009) return 'ÖDENDİ';
    if (paid > .009 && paid < total) return 'KISMİ';
    return 'ÖDENMEDİ';
  }

  Color dueStatusColor(Map r) {
    final s = dueStatus(r);
    if (s == 'ÖDENDİ') return success;
    if (s == 'KISMİ') return orange;
    return danger;
  }

  @override
  Widget body() {
    final filtered = shown;
    final isDues = widget.kind == 'dues';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        head(widget.title, null),
        if (isDues)
          SummaryScroller(children: [
            CompactStatCard(
              label: 'Dönem Toplamı',
              value: money(summary['total']),
              icon: Icons.receipt_long_rounded,
              color: blue,
            ),
            CompactStatCard(
              label: 'Tahsil Edilen',
              value: money(summary['paid']),
              icon: Icons.check_circle_outline_rounded,
              color: success,
            ),
            CompactStatCard(
              label: 'Açık Borç',
              value: money(summary['debt']),
              icon: Icons.warning_amber_rounded,
              color: danger,
            ),
            CompactStatCard(
              label: 'Ödeyen / Ödemeyen',
              value: '${summary['paid_units'] ?? 0} / ${summary['unpaid_units'] ?? 0}',
              icon: Icons.groups_2_outlined,
              color: violet,
            ),
          ])
        else
          SummaryScroller(children: [
            CompactStatCard(
              label: 'Filtrelenen Tahsilat',
              value: money(summary['total']),
              icon: Icons.payments_outlined,
              color: success,
            ),
            CompactStatCard(
              label: 'İşlem Sayısı',
              value: '${summary['count'] ?? 0}',
              icon: Icons.format_list_numbered_rounded,
              color: violet,
            ),
          ]),
        const SizedBox(height: 14),
        if (isDues) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tümü')),
              ButtonSegment(value: 'paid', label: Text('Ödeyen')),
              ButtonSegment(value: 'unpaid', label: Text('Ödemeyen')),
            ],
            selected: {status},
            onSelectionChanged: (v) => setState(() => status = v.first),
          ),
          const SizedBox(height: 12),
        ],
        FilterSurface(
          subtitle: '${filtered.length} kayıt gösteriliyor',
          initiallyExpanded: false,
          children: [
            DropdownButtonFormField<String>(
              value: period,
              decoration: const InputDecoration(labelText: 'Dönem'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm dönemler')),
                ...periods.map((x) => DropdownMenuItem(value: '${x['period']}', child: Text('${x['period']}'))),
              ],
              onChanged: (v) {
                period = v ?? '';
                load();
              },
            ),
            DropdownButtonFormField<String>(
              value: block,
              decoration: const InputDecoration(labelText: 'Blok'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm bloklar')),
                ...blocks.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['name']}'))),
              ],
              onChanged: (v) {
                block = v ?? '';
                load();
              },
            ),
            if (!isDues)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pick(true),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(from == null ? 'Başlangıç' : ds(from)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pick(false),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(to == null ? 'Bitiş' : ds(to)),
                    ),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Filtreleri Temizle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionHeading(
          isDues ? 'Aidat Kayıtları' : 'Tahsilat Kayıtları',
          subtitle: isDues
              ? 'Dairelerin dönem bazlı tahakkuk, ödeme ve kalan borç durumu.'
              : 'Geçmiş ve güncel tahsilatlar dönem ve tarih bilgileriyle listelenir.',
        ),
        const SizedBox(height: 8),
        if (isDues)
          ProfessionalDataTable(
            minWidth: 860,
            columns: const [
              DataColumn(label: Text('DAİRE')),
              DataColumn(label: Text('DÖNEM')),
              DataColumn(label: Text('TAHAKKUK'), numeric: true),
              DataColumn(label: Text('ÖDENEN'), numeric: true),
              DataColumn(label: Text('KALAN'), numeric: true),
              DataColumn(label: Text('DURUM')),
            ],
            rows: filtered.map<DataRow>((r) {
              final row = Map<String, dynamic>.from(r);
              final c = dueStatusColor(row);
              return DataRow(cells: [
                DataCell(TableText('${row['block_name']} / ${row['door_no']}', strong: true)),
                DataCell(TableText('${row['period'] ?? '-'}')),
                DataCell(TableAmount(money(row['total_amount']))),
                DataCell(TableAmount(money(row['paid']), color: success)),
                DataCell(TableAmount(money(row['balance']), color: (double.tryParse('${row['balance']}') ?? 0) > .009 ? danger : success)),
                DataCell(StatusPill(dueStatus(row), c)),
              ]);
            }).toList(),
          )
        else
          ProfessionalDataTable(
            minWidth: 820,
            columns: const [
              DataColumn(label: Text('DAİRE')),
              DataColumn(label: Text('TARİH')),
              DataColumn(label: Text('DÖNEM')),
              DataColumn(label: Text('YÖNTEM')),
              DataColumn(label: Text('TUTAR'), numeric: true),
            ],
            rows: filtered.map<DataRow>((r) {
              final row = Map<String, dynamic>.from(r);
              return DataRow(cells: [
                DataCell(TableText('${row['block_name']} / ${row['door_no']}', strong: true)),
                DataCell(TableText('${row['payment_date'] ?? '-'}')),
                DataCell(TableText('${row['period'] ?? 'Dönemsiz'}')),
                DataCell(TableText(detailStatus(row['payment_method']))),
                DataCell(TableAmount(money(row['amount']), color: success)),
              ]);
            }).toList(),
          ),
      ],
    );
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ReloadPage<ExpensesPage> {
  List blocks = [];
  List categories = [];
  List applies = [];
  List types = [];
  Map<String, dynamic> summary = {};
  bool subscriptionActive = true;
  String fBlock = '';
  String fCat = '';
  DateTime? from, to;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<void> load() async {
    final d = await Api.request('manager?action=expenses');
    items = d['items'] ?? [];
    blocks = d['blocks'] ?? [];
    categories = d['categories'] ?? [];
    applies = d['applies_to'] ?? [];
    types = d['recurrence_types'] ?? [];
    summary = Map<String, dynamic>.from(d['summary'] ?? {});
    subscriptionActive = d['subscription_active'] == true;
    Api.managerPackageActive = subscriptionActive;
    busy = false;
    if (mounted) setState(() {});
  }

  String ds(DateTime? d) => d == null ? '' : d.toIso8601String().substring(0, 10);

  List get shown => items.where((r) {
        final d = DateTime.tryParse('${r['expense_date']}');
        return (fBlock.isEmpty || '${r['block_id'] ?? ''}' == fBlock) &&
            (fCat.isEmpty || '${r['category']}' == fCat) &&
            (from == null || d == null || !d.isBefore(from!)) &&
            (to == null || d == null || !d.isAfter(to!));
      }).toList();

  Future<void> pick(bool isFrom) async {
    final x = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (isFrom ? from : to) ?? DateTime.now(),
    );
    if (x == null) return;
    setState(() {
      if (isFrom) {
        from = x;
      } else {
        to = x;
      }
    });
  }

  void resetFilters() {
    setState(() {
      fBlock = '';
      fCat = '';
      from = null;
      to = null;
    });
  }

  String recurrenceLabel(dynamic value) {
    switch ('$value') {
      case 'fixed':
        return 'Sabit';
      case 'installment':
        return 'Taksitli';
      default:
        return 'Tek Sefer';
    }
  }

  String expenseState(Map r) {
    final total = int.tryParse('${r['schedule_count'] ?? 0}') ?? 0;
    final done = int.tryParse('${r['calculated_count'] ?? 0}') ?? 0;
    if (total > 0 && done >= total) return 'PLANI TAMAMLANDI';
    if (done > 0) return 'İŞLENİYOR';
    return 'AİDATA İŞLENMEDİ';
  }

  Color expenseStateColor(Map r) {
    final state = expenseState(r);
    if (state == 'PLANI TAMAMLANDI') return success;
    if (state == 'İŞLENİYOR') return blue;
    return orange;
  }

  List<Map<String, String>> scheduleRows(Map r) {
    final raw = '${r['schedule_text'] ?? ''}'.trim();
    if (raw.isEmpty) return [];
    final out = <Map<String, String>>[];
    for (final part in raw.split(';')) {
      final cells = part.split('|');
      if (cells.length < 3) continue;
      out.add({'period': cells[0], 'amount': cells[1], 'status': cells[2]});
    }
    return out;
  }

  String scheduleRangeLabel(Map r) {
    final rows = scheduleRows(r);
    if (rows.isEmpty) return '-';
    final first = rows.first['period'] ?? '-';
    final last = rows.last['period'] ?? first;
    return rows.length == 1 ? first : '$first → $last';
  }

  Future<void> edit([Map? r]) async {
    if (!await requireManagerPackage(context)) return;
    final t = TextEditingController(text: '${r?['title'] ?? ''}');
    final amt = TextEditingController(text: '${r?['amount'] ?? ''}');
    final date = TextEditingController(text: '${r?['expense_date'] ?? DateTime.now().toIso8601String().substring(0, 10)}');
    final note = TextEditingController(text: '${r?['note'] ?? ''}');
    String cat = '${r?['category'] ?? (categories.isNotEmpty ? categories.first : 'Diğer')}';
    String block = '${r?['block_id'] ?? ''}';
    final ok = await form(context, r == null ? 'Yeni Gider' : 'Gider Düzenle', [
      TextField(controller: t, decoration: const InputDecoration(labelText: 'Gider Adı')),
      DropdownButtonFormField<String>(
        value: cat,
        items: categories.map((e) => DropdownMenuItem(value: '$e', child: Text('$e'))).toList(),
        onChanged: (v) => cat = v ?? cat,
        decoration: const InputDecoration(labelText: 'Kategori'),
      ),
      TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tutar')),
      TextField(controller: date, decoration: const InputDecoration(labelText: 'Gider Tarihi')),
      DropdownButtonFormField<String>(
        value: block,
        items: [
          const DropdownMenuItem(value: '', child: Text('Tüm Site')),
          ...blocks.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text('${e['name']}'))),
        ],
        onChanged: (v) => block = v ?? '',
        decoration: const InputDecoration(labelText: 'Blok'),
      ),
      TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Not')),
    ]);
    if (ok) {
      await Api.request('manager', method: 'POST', body: {
        'action': 'save_expense',
        'id': r?['id'] ?? 0,
        'title': t.text,
        'category': cat,
        'amount': amt.text,
        'expense_date': date.text,
        'block_id': block,
        'applies_to': r?['applies_to'] ?? 'all',
        'recurrence_type': r?['recurrence_type'] ?? 'one_time',
        'start_date': r?['start_date'] ?? '',
        'end_date': r?['end_date'] ?? '',
        'installment_count': r?['installment_count'] ?? 1,
        'is_fixed_asset': r?['is_fixed_asset'] ?? 0,
        'note': note.text,
      });
      load();
    }
  }

  Future<void> showExpenseDetail(Map r) async {
    final total = int.tryParse('${r['schedule_count'] ?? 0}') ?? 0;
    final done = int.tryParse('${r['calculated_count'] ?? 0}') ?? 0;
    final schedules = scheduleRows(r);
    final canEdit = done == 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .95,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(color: const Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(99)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r['title']}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
                            const SizedBox(height: 3),
                            Text('${r['category']} • ${r['expense_date']}', style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      StatusPill(expenseState(r), expenseStateColor(r)),
                      IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      SummaryScroller(children: [
                        CompactStatCard(label: 'Gider Tutarı', value: money(r['amount']), icon: Icons.receipt_long_outlined, color: danger),
                        CompactStatCard(label: 'Kalan Yük', value: money(r['remaining_amount']), icon: Icons.schedule_rounded, color: orange),
                        CompactStatCard(label: 'İşlenen Dönem', value: '$done / $total', icon: Icons.calendar_view_month_rounded, color: blue),
                      ]),
                      const SizedBox(height: 18),
                      const SectionHeading('Gider Bilgileri'),
                      const SizedBox(height: 8),
                      _expenseInfoRow('Kapsam', '${r['block_name'] ?? 'Tüm Site'}'),
                      _expenseInfoRow('Gider tipi', recurrenceLabel(r['recurrence_type'])),
                      _expenseInfoRow('Başlangıç', '${r['start_date'] ?? '-'}'),
                      _expenseInfoRow('Bitiş', '${r['end_date'] ?? '-'}'),
                      _expenseInfoRow('Taksit / dönem', '${r['installment_count'] ?? total}'),
                      if ('${r['note'] ?? ''}'.trim().isNotEmpty) _expenseInfoRow('Not', '${r['note']}'),
                      const SizedBox(height: 18),
                      SectionHeading('Dönem / Taksit Planı', subtitle: schedules.isEmpty ? 'Plan kaydı bulunmuyor.' : '${schedules.length} dönem kaydı'),
                      const SizedBox(height: 8),
                      if (schedules.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
                          child: const Text('Bu gider için dönem planı oluşturulmamış.', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFFF8FAFC),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: const Row(children: [
                                  Expanded(child: Text('DÖNEM', style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w900))),
                                  Expanded(child: Text('TUTAR', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w900))),
                                  SizedBox(width: 96, child: Text('DURUM', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w900))),
                                ]),
                              ),
                              ...schedules.asMap().entries.map((e) {
                                final row = e.value;
                                final calculated = row['status'] == 'calculated';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(border: Border(top: BorderSide(color: e.key == 0 ? Colors.transparent : line))),
                                  child: Row(children: [
                                    Expanded(child: TableText(row['period'] ?? '-')),
                                    Expanded(child: TableAmount(money(row['amount']))),
                                    SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: StatusPill(calculated ? 'İŞLENDİ' : 'BEKLİYOR', calculated ? success : orange))),
                                  ]),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheet);
                          edit(r);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Gideri Düzenle'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expenseInfoRow(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w800))),
          ],
        ),
      );

  @override
  Widget body() {
    final filtered = shown;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        head('Giderler', () => edit()),
        SummaryScroller(children: [
          CompactStatCard(
            label: 'Bu Ay Aidata İşlenmemiş',
            value: money(summary['current_pending']),
            icon: Icons.pending_actions_rounded,
            color: orange,
            caption: 'Henüz tahakkuka yansımadı',
          ),
          CompactStatCard(
            label: 'Toplam Kalan Gider',
            value: money(summary['all_pending']),
            icon: Icons.schedule_rounded,
            color: danger,
            caption: 'Gelecek dönem yükü',
          ),
          CompactStatCard(
            label: 'Aidata İşlenmiş',
            value: money(summary['calculated']),
            icon: Icons.verified_outlined,
            color: success,
            caption: 'Geçmiş finansal kayıt',
          ),
          CompactStatCard(
            label: 'Gider Kaydı',
            value: '${filtered.length}',
            icon: Icons.list_alt_rounded,
            color: blue,
          ),
        ]),
        const SizedBox(height: 14),
        FilterSurface(
          subtitle: '${filtered.length} / ${items.length} gider gösteriliyor',
          children: [
            DropdownButtonFormField<String>(
              value: fBlock,
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm bloklar')),
                ...blocks.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text('${e['name']}'))),
              ],
              onChanged: (v) => setState(() => fBlock = v ?? ''),
              decoration: const InputDecoration(labelText: 'Blok filtresi'),
            ),
            DropdownButtonFormField<String>(
              value: fCat,
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm kategoriler')),
                ...categories.map((e) => DropdownMenuItem(value: '$e', child: Text('$e'))),
              ],
              onChanged: (v) => setState(() => fCat = v ?? ''),
              decoration: const InputDecoration(labelText: 'Kategori filtresi'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pick(true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(from == null ? 'Başlangıç' : ds(from)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pick(false),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(to == null ? 'Bitiş' : ds(to)),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Filtreleri Temizle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionHeading(
          'Gider Kayıtları',
          subtitle: 'Satıra dokunarak giderin geçmiş ve kalan dönem/taksit planını görüntüleyin.',
        ),
        const SizedBox(height: 8),
        ProfessionalDataTable(
          minWidth: 1250,
          columns: const [
            DataColumn(label: Text('GİDER')),
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('DÖNEM PLANI')),
            DataColumn(label: Text('KATEGORİ')),
            DataColumn(label: Text('KAPSAM')),
            DataColumn(label: Text('TUTAR'), numeric: true),
            DataColumn(label: Text('İŞLENEN')),
            DataColumn(label: Text('KALAN'), numeric: true),
            DataColumn(label: Text('DURUM')),
          ],
          rows: filtered.map<DataRow>((r) {
            final row = Map<String, dynamic>.from(r);
            final total = int.tryParse('${row['schedule_count'] ?? 0}') ?? 0;
            final done = int.tryParse('${row['calculated_count'] ?? 0}') ?? 0;
            return DataRow(
              onSelectChanged: (_) => showExpenseDetail(row),
              cells: [
                DataCell(TableText('${row['title']}', strong: true)),
                DataCell(TableText('${row['expense_date'] ?? '-'}')),
                DataCell(TableText(scheduleRangeLabel(row), strong: true, color: blue)),
                DataCell(TableText('${row['category'] ?? '-'}')),
                DataCell(TableText('${row['block_name'] ?? 'Tüm Site'}')),
                DataCell(TableAmount(money(row['amount']))),
                DataCell(TableText('$done / $total dönem')),
                DataCell(TableAmount(money(row['remaining_amount']), color: (double.tryParse('${row['remaining_amount'] ?? 0}') ?? 0) > .009 ? danger : success)),
                DataCell(StatusPill(expenseState(row), expenseStateColor(row))),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class AnnouncementsManagerPage extends StatefulWidget{const AnnouncementsManagerPage({super.key});@override State<AnnouncementsManagerPage> createState()=>_AnnouncementsManagerPageState();}class _AnnouncementsManagerPageState extends ReloadPage<AnnouncementsManagerPage>{@override void initState(){super.initState();load();}@override Future<void>load()async{items=(await Api.request('manager?action=announcements'))['items'];busy=false;if(mounted)setState((){});}Future<void>add()async{if(!await requireManagerPackage(context))return;final t=TextEditingController(),b=TextEditingController();if(await form(context,'Yeni Duyuru',[TextField(controller:t,decoration:const InputDecoration(labelText:'Başlık')),TextField(controller:b,maxLines:5,decoration:const InputDecoration(labelText:'Duyuru'))])){await Api.request('manager',method:'POST',body:{'action':'save_announcement','title':t.text,'body':b.text,'audience':'residents'});load();}}@override Widget body()=>ListView(padding:const EdgeInsets.all(16),children:[head('Duyurular',add),...items.map((r)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r['title'],style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:6),Text(r['body']),const SizedBox(height:8),Text('${r['publish_at']}',style:TextStyle(color:Colors.grey.shade600))]))))]);}
class TicketsManagerPage extends StatefulWidget{const TicketsManagerPage({super.key});@override State<TicketsManagerPage> createState()=>_TicketsManagerPageState();}class _TicketsManagerPageState extends ReloadPage<TicketsManagerPage>{@override void initState(){super.initState();load();}@override Future<void>load()async{items=(await Api.request('manager?action=tickets'))['items'];busy=false;if(mounted)setState((){});}Future<void>edit(Map r)async{if(!await requireManagerPackage(context))return;String status='${r['status']}';final note=TextEditingController(text:'${r['manager_note']??''}');if(await form(context,'Talep Yönetimi',[Text(r['title'],style:const TextStyle(fontWeight:FontWeight.w800)),Text(r['description']),DropdownButtonFormField<String>(initialValue:status,items:['new','in_progress','resolved','closed'].map((x)=>DropdownMenuItem(value:x,child:Text(detailStatus(x)))).toList(),onChanged:(v)=>status=v!),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Yönetici Notu'))])){await Api.request('manager',method:'POST',body:{'action':'update_ticket','id':r['id'],'status':status,'manager_note':note.text});load();}}@override Widget body()=>ListView(padding:const EdgeInsets.all(16),children:[head('Arıza / Talepler',null),...items.map((r)=>Card(child:ListTile(title:Text(r['title'],style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${r['block_name']??''} ${r['door_no']??''} · ${r['opener']}\n${r['description']}'),isThreeLine:true,trailing:Chip(label:Text(detailStatus(r['status']))),onTap:()=>edit(r))))]);}
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override State<FinancePage> createState()=>_FinancePageState();
}
class _FinancePageState extends State<FinancePage> {
  Map? d;
  @override void initState(){super.initState();load();}
  Future<void> load() async {d=await Api.request('manager?action=finance');if(mounted)setState((){});}
  @override Widget build(BuildContext c){
    if(d==null)return const Center(child:BrandLoader());
    return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
      head('Kasa / Banka',null),
      ...(d!['accounts'] as List).map((r)=>Card(child:ListTile(
        leading:Icon(r['type']=='bank'?Icons.account_balance:Icons.payments),
        title:Text(r['name']),
        trailing:Text(money(r['balance']),style:const TextStyle(fontWeight:FontWeight.w900)),
      ))),
      const SizedBox(height:14),
      const Text('Son Hareketler',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      ...(d!['transactions'] as List).map((r)=>ListTile(
        title:Text(r['category']),
        subtitle:Text('${r['account_name']} · ${r['transaction_date']}'),
        trailing:Text('${r['direction']=='in'?'+':'-'}${money(r['amount'])}'),
      )),
    ]));
  }
}
Widget head(String title,VoidCallback? add)=>PageTitle(title,subtitle:'Kayıtları yönetin ve güncel bilgileri görüntüleyin',action:add==null?null:FilledButton.icon(onPressed:add,icon:const Icon(Icons.add_rounded),label:const Text('Yeni')));
Future<bool> form(BuildContext c,String title,List<Widget> fields) async {
  final result=await showModalBottomSheet<bool>(
    context:c,
    isScrollControlled:true,
    showDragHandle:true,
    builder:(x)=>Padding(
      padding:EdgeInsets.fromLTRB(20,8,20,MediaQuery.of(x).viewInsets.bottom+20),
      child:SingleChildScrollView(
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
          const SizedBox(height:16),
          ...fields.expand((w)=>[w,const SizedBox(height:12)]),
          FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Padding(padding:EdgeInsets.all(14),child:Text('Kaydet'))),
        ]),
      ),
    ),
  );
  return result??false;
}
Future<bool> confirm(BuildContext c)async=>(await showDialog<bool>(context:c,builder:(x)=>AlertDialog(title:const Text('Emin misiniz?'),content:const Text('Bu işlem geri alınamayabilir.'),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Devam Et'))])))??false;
class ResidentsManagerPage extends StatefulWidget {
  const ResidentsManagerPage({super.key});
  @override
  State<ResidentsManagerPage> createState() => _ResidentsManagerPageState();
}

class _ResidentsManagerPageState extends ReloadPage<ResidentsManagerPage> {
  List apartments = [];
  String q = '';
  String statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<void> load() async {
    final d = await Api.request('manager?action=property_owners');
    items = d['items'] ?? [];
    apartments = d['apartments'] ?? [];
    busy = false;
    if (mounted) setState(() {});
  }

  List get shown => items.where((r) {
        final active = r['is_active'] == 1 || r['is_active'] == true || '${r['is_active']}' == '1';
        final statusOk = statusFilter == 'all' || (statusFilter == 'active' ? active : !active);
        final query = q.trim().toLowerCase();
        final haystack = '${r['block_name']} ${r['door_no']} ${r['full_name']} ${r['phone']}'.toLowerCase();
        return statusOk && (query.isEmpty || haystack.contains(query));
      }).toList();

  Future<void> edit([Map? r]) async {
    if (!await requireManagerPackage(context)) return;
    if (apartments.isEmpty) return;
    int aid = int.parse('${r?['apartment_id'] ?? apartments.first['id']}');
    final name = TextEditingController(text: '${r?['full_name'] ?? ''}');
    final phone = TextEditingController(text: '${r?['phone'] ?? ''}');
    if (await form(context, r == null ? 'Kat Maliki Ekle' : 'Kat Maliki Düzenle', [
      DropdownButtonFormField<int>(
        initialValue: aid,
        items: apartments
            .map<DropdownMenuItem<int>>((x) => DropdownMenuItem(
                  value: int.parse('${x['id']}'),
                  child: Text('${x['block_name']} / Daire ${x['door_no']}'),
                ))
            .toList(),
        onChanged: (v) => aid = v!,
        decoration: const InputDecoration(labelText: 'Daire'),
      ),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad Soyad')),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
    ])) {
      await Api.request('manager', method: 'POST', body: {
        'action': 'save_property_owner',
        'user_id': r?['user_id'] ?? 0,
        'apartment_id': aid,
        'full_name': name.text,
        'phone': phone.text,
      });
      load();
    }
  }

  Future<void> toggle(Map r) async {
    await Api.request('manager', method: 'POST', body: {
      'action': 'toggle_property_owner',
      'user_id': r['user_id'],
      'apartment_id': r['apartment_id'],
    });
    load();
  }

  Future<void> downloadExcel() async {
    final d = await Api.request('manager?action=property_owners_excel_download');
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${d['filename']}');
    await f.writeAsBytes(base64Decode('${d['data_base64']}'));
    await Share.shareXFiles([XFile(f.path)], text: 'Kat Malikleri Excel Tablosu');
  }

  Future<void> uploadExcel() async {
    if (!await requireManagerPackage(context)) return;
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    if (r == null) return;
    final bytes = r.files.single.bytes ?? await File(r.files.single.path!).readAsBytes();
    final d = await Api.request('manager', method: 'POST', body: {
      'action': 'property_owners_excel_upload',
      'data_base64': base64Encode(bytes),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d['message']}')));
    load();
  }

  @override
  Widget body() {
    final filtered = shown;
    final activeCount = items.where((r) => r['is_active'] == 1 || r['is_active'] == true || '${r['is_active']}' == '1').length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        head('Kat Malikleri', () => edit()),
        SummaryScroller(children: [
          CompactStatCard(label: 'Toplam Kayıt', value: '${items.length}', icon: Icons.groups_rounded, color: blue),
          CompactStatCard(label: 'Aktif Kayıt', value: '$activeCount', icon: Icons.verified_user_outlined, color: success),
          CompactStatCard(label: 'Pasif Kayıt', value: '${items.length - activeCount}', icon: Icons.person_off_outlined, color: muted),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: downloadExcel,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Excel İndir'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: uploadExcel,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Excel Yükle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('Tümü')),
            ButtonSegment(value: 'active', label: Text('Aktif')),
            ButtonSegment(value: 'passive', label: Text('Pasif')),
          ],
          selected: {statusFilter},
          onSelectionChanged: (v) => setState(() => statusFilter = v.first),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            labelText: 'Kat maliki ara',
            hintText: 'Blok, daire, ad soyad veya telefon',
          ),
        ),
        const SizedBox(height: 14),
        SectionHeading('Kat Maliki Kayıtları', subtitle: '${filtered.length} kayıt gösteriliyor'),
        const SizedBox(height: 8),
        ProfessionalDataTable(
          minWidth: 830,
          columns: const [
            DataColumn(label: Text('DAİRE')),
            DataColumn(label: Text('AD SOYAD')),
            DataColumn(label: Text('TELEFON')),
            DataColumn(label: Text('DURUM')),
            DataColumn(label: Text('İŞLEMLER')),
          ],
          rows: filtered.map<DataRow>((r) {
            final row = Map<String, dynamic>.from(r);
            final active = row['is_active'] == 1 || row['is_active'] == true || '${row['is_active']}' == '1';
            return DataRow(
              onSelectChanged: (_) => edit(row),
              cells: [
                DataCell(TableText('${row['block_name']} / ${row['door_no']}', strong: true)),
                DataCell(TableText('${row['full_name'] ?? '-'}', strong: true)),
                DataCell(TableText('${row['phone'] ?? '-'}')),
                DataCell(StatusPill(active ? 'AKTİF' : 'PASİF', active ? success : muted)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Düzenle',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => edit(row),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        tooltip: active ? 'Pasife al' : 'Aktif et',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => toggle(row),
                        icon: Icon(active ? Icons.person_off_outlined : Icons.person_add_alt_1_outlined, size: 19),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ReportsManagerPage extends StatefulWidget{const ReportsManagerPage({super.key});@override State<ReportsManagerPage> createState()=>_ReportsManagerPageState();}class _ReportsManagerPageState extends State<ReportsManagerPage>{Map? d;@override void initState(){super.initState();load();}Future<void>load()async{d=await Api.request('manager?action=reports');if(mounted)setState((){});}@override Widget build(BuildContext c)=>d==null?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[head('Raporlar',null),const Text('Aylık Tahsilat',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:10),...(d!['monthly'] as List).map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:SoftCard(child:Row(children:[const IconBubble(Icons.bar_chart_rounded,success),const SizedBox(width:12),Expanded(child:Text('${r['period']}',style:const TextStyle(fontWeight:FontWeight.w800))),Text(money(r['income']),style:const TextStyle(fontWeight:FontWeight.w900,color:success))])))),const SizedBox(height:18),const Text('En Yüksek Açık Borçlar',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:10),...(d!['debts'] as List).map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:SoftCard(child:Row(children:[const IconBubble(Icons.warning_amber_rounded,danger),const SizedBox(width:12),Expanded(child:Text('${r['block_name']} / ${r['door_no']}\n${r['owner_name']??''}',style:const TextStyle(fontWeight:FontWeight.w700))),Text(money(r['balance']),style:const TextStyle(fontWeight:FontWeight.w900,color:danger))]))))]));}
class NotificationsManagerPage extends StatefulWidget{const NotificationsManagerPage({super.key});@override State<NotificationsManagerPage> createState()=>_NotificationsManagerPageState();}class _NotificationsManagerPageState extends State<NotificationsManagerPage>{List blocks=[],history=[];bool busy=true;@override void initState(){super.initState();load();}Future<void>load()async{final d=await Api.request('manager?action=notification_data');blocks=d['blocks'];history=d['history'];busy=false;if(mounted)setState((){});}Future<void>send()async{if(!await requireManagerPackage(context))return;final title=TextEditingController(),body=TextEditingController();int? block;final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,showDragHandle:true,builder:(x)=>StatefulBuilder(builder:(x,setLocal)=>Padding(padding:EdgeInsets.fromLTRB(20,8,20,MediaQuery.of(x).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Firebase Bildirimi Gönder',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:14),DropdownButtonFormField<int?>(initialValue:block,decoration:const InputDecoration(labelText:'Hedef'),items:[const DropdownMenuItem<int?>(value:null,child:Text('Tüm daire sakinleri')),...blocks.map<DropdownMenuItem<int?>>((b)=>DropdownMenuItem(value:int.parse('${b['id']}'),child:Text('${b['name']} bloğu')))],onChanged:(v)=>setLocal(()=>block=v)),const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'Başlık')),const SizedBox(height:12),TextField(controller:body,maxLines:4,decoration:const InputDecoration(labelText:'Mesaj')),const SizedBox(height:16),FilledButton.icon(onPressed:()=>Navigator.pop(x,true),icon:const Icon(Icons.send_rounded),label:const Text('Bildirimi Gönder'))])))))??false;if(ok){final r=await Api.request('manager',method:'POST',body:{'action':'send_notification','title':title.text,'body':body.text,'block_id':block});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gönderim: ${r['push']?['success']??0}/${r['push']?['total']??0} cihaz')));load();}}@override Widget build(BuildContext c)=>busy?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[head('Bildirimler',send),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF101828),Color(0xFF344054)]),borderRadius:BorderRadius.circular(22)),child:const Row(children:[Icon(Icons.notifications_active_rounded,color:brand,size:32),SizedBox(width:12),Expanded(child:Text('Tüm siteye veya seçtiğiniz bloğa Firebase üzerinden anlık bildirim gönderin.',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700,height:1.4)))])),const SizedBox(height:18),...history.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${r['title']}',style:const TextStyle(fontWeight:FontWeight.w900))),StatusPill(r['block_name']??'Genel',blue)]),const SizedBox(height:6),Text('${r['body']}',style:const TextStyle(color:muted)),const SizedBox(height:8),Text('${r['success_count']}/${r['recipient_count']} cihaz • ${r['created_at']}',style:const TextStyle(fontSize:11,color:muted))]))))]));}
class AutomationManagerPage extends StatefulWidget{const AutomationManagerPage({super.key});@override State<AutomationManagerPage> createState()=>_AutomationManagerPageState();}
class _AutomationManagerPageState extends State<AutomationManagerPage>{
 bool busy=true,auto=false,overdue=true,wa=true,push=true;int day=1,hour=10;List logs=[];
 final overdueDays=TextEditingController(),before=TextEditingController(),after=TextEditingController();
 @override void initState(){super.initState();load();}
 Future<void>load()async{final d=await Api.request('manager?action=automation');final s=d['settings'];auto=s['auto_generate_dues']==1||s['auto_generate_dues']=='1';overdue=s['overdue_enabled']==1||s['overdue_enabled']=='1';wa=s['whatsapp_enabled']==1||s['whatsapp_enabled']=='1';push=s['push_enabled']==1||s['push_enabled']=='1';day=int.tryParse('${s['generate_day']}')??1;hour=int.tryParse('${s['notification_hour']}')??10;overdueDays.text='${s['overdue_days']??'1,3,7,15'}';before.text='${s['push_before_days']??'3,1'}';after.text='${s['push_after_days']??'1,3,7'}';logs=d['logs']??[];busy=false;if(mounted)setState((){});}
 Future<void>save()async{if(!await requireManagerPackage(context))return;await Api.request('manager',method:'POST',body:{'action':'automation','auto_generate_dues':auto,'generate_day':day,'overdue_enabled':overdue,'overdue_days':overdueDays.text,'whatsapp_enabled':wa,'notification_hour':hour,'push_enabled':push,'push_before_days':before.text,'push_after_days':after.text});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Otomasyon ve bildirim ayarları kaydedildi.')));await load();}
 @override Widget build(BuildContext c)=>busy?const Center(child:BrandLoader()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
  head('Otomasyon Ayarları',null),
  SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Otomatik aidat oluşturma',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Belirlenen ay gününde aidatları otomatik hazırlar.'),value:auto,onChanged:(v)=>setState(()=>auto=v)),
   Slider(value:day.toDouble(),min:1,max:28,divisions:27,label:'$day. gün',onChanged:(v)=>setState(()=>day=v.round())),
   const Divider(height:24),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Gecikme takibi',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Belirlenen gecikme günlerinde açık borçları kontrol eder.'),value:overdue,onChanged:(v)=>setState(()=>overdue=v)),
   TextField(controller:overdueDays,decoration:const InputDecoration(labelText:'WhatsApp gecikme günleri',hintText:'1,3,7,15')),
   const SizedBox(height:12),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('WhatsApp otomasyonu',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Gecikme hatırlatmalarını otomatik işler.'),value:wa,onChanged:(v)=>setState(()=>wa=v)),
   const SizedBox(height:8),
   DropdownButtonFormField<int>(initialValue:hour,decoration:const InputDecoration(labelText:'Otomatik işlem saati',prefixIcon:Icon(Icons.schedule_rounded)),items:List.generate(24,(h)=>DropdownMenuItem(value:h,child:Text('${h.toString().padLeft(2,'0')}:00'))),onChanged:(v)=>setState(()=>hour=v??10)),
   const SizedBox(height:8),
   const Text('Saat dilimi Europe/Istanbul. Sunucu cron kaydı her saat başı çalışmalıdır (0 * * * *).',style:TextStyle(fontSize:11,color:muted,height:1.4))
  ])),
  const SizedBox(height:14),
  SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Row(children:[Icon(Icons.notifications_active_rounded,color:violet),SizedBox(width:10),Text('Firebase Bildirim Ayarları',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))]),
   const SizedBox(height:6),const Text('Her yönetici kendi sitesinin aidat hatırlatma günlerini belirler.',style:TextStyle(color:muted)),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Aidat push bildirimleri'),value:push,onChanged:(v)=>setState(()=>push=v)),
   TextField(controller:before,decoration:const InputDecoration(labelText:'Son ödeme tarihinden kaç gün önce?',hintText:'7,3,1')),
   const SizedBox(height:12),TextField(controller:after,decoration:const InputDecoration(labelText:'Son ödeme tarihinden kaç gün sonra?',hintText:'1,3,7,15'))
  ])),
  const SizedBox(height:14),
  SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[const IconBubble(Icons.history_rounded,blue),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Otomasyon Çalışma Durumu',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text('${hour.toString().padLeft(2,'0')}:00 çalışma saati',style:const TextStyle(fontSize:11,color:muted))]))]),
   const SizedBox(height:12),
   if(logs.isEmpty)const Text('Henüz otomasyon çalışma kaydı yok.',style:TextStyle(color:muted))
   else ...logs.map((r)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(14),border:Border.all(color:line)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(r['result']=='ok'?Icons.check_circle_rounded:r['result']=='skip'?Icons.info_rounded:Icons.error_rounded,size:18,color:r['result']=='ok'?success:r['result']=='skip'?muted:danger),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['job']}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${r['message']??'-'}',style:const TextStyle(fontSize:11,color:muted)),Text('${r['created_at']??''}',style:const TextStyle(fontSize:10,color:muted))]))])))
  ])),
  const SizedBox(height:18),
  SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:save,icon:const Icon(Icons.save_rounded),label:const Text('Ayarları Kaydet')))
 ]));}

class CardPaymentIntegrationPage extends StatefulWidget{const CardPaymentIntegrationPage({super.key});@override State<CardPaymentIntegrationPage> createState()=>_CardPaymentIntegrationPageState();}
class _CardPaymentIntegrationPageState extends State<CardPaymentIntegrationPage>{
 bool busy=true,saving=false,enabled=false,hasSecret=false,hasWebhook=false;String env='sandbox',publicKey='',secretKey='',webhookSecret='',webhookUrl='';int? accountId;List accounts=[];
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{final d=await Api.request('card-payment-config');final c=Map<String,dynamic>.from(d['config']??{});env='${c['environment']??'sandbox'}';publicKey='${c['public_key']??''}';hasSecret=c['has_secret']==true;hasWebhook=c['has_webhook_secret']==true;enabled=c['is_enabled']==true;webhookUrl='${c['webhook_url']??''}';accountId=int.tryParse('${c['finance_account_id']??''}');accounts=(d['accounts'] as List?)??[];}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}finally{busy=false;if(mounted)setState((){});}}
 Future<void>save()async{if(!await requireManagerPackage(context))return;setState(()=>saving=true);try{await Api.request('card-payment-config',method:'POST',body:{'environment':env,'public_key':publicKey.trim(),'secret_key':secretKey.trim(),'webhook_secret':webhookSecret.trim(),'finance_account_id':accountId,'is_enabled':enabled});secretKey='';webhookSecret='';await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sanal POS ayarları kaydedildi.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}finally{saving=false;if(mounted)setState((){});}}
 Future<void>apply()async{final u=Uri.parse('https://www.tahsilat.com/basvuru/');await launchUrl(u,mode:LaunchMode.externalApplication);}
 @override Widget build(BuildContext c){if(busy)return const Center(child:BrandLoader());return ListView(padding:const EdgeInsets.all(20),children:[const PageTitle('Sanal POS Entegrasyonu',subtitle:'Her site kendi Tahsilat.com hesabını bağlar. Önce Sandbox ile test edin.'),const SizedBox(height:12),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tahsilat.com Başvurusu',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Henüz hesabınız yoksa başvuruyu kendi site yönetiminiz adına tamamlayın.',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:12),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:apply,icon:const Icon(Icons.open_in_new_rounded),label:const Text('Tahsilat.com Başvuru Sayfasını Aç')))])),const SizedBox(height:12),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('API Bağlantısı',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:14),DropdownButtonFormField<String>(initialValue:env,decoration:const InputDecoration(labelText:'Ortam'),items:const [DropdownMenuItem(value:'sandbox',child:Text('Sandbox / Test')),DropdownMenuItem(value:'live',child:Text('Canlı'))],onChanged:(v)=>setState(()=>env=v??'sandbox')),const SizedBox(height:12),TextFormField(initialValue:publicKey,decoration:const InputDecoration(labelText:'Public Key',hintText:'pk_test_...'),onChanged:(v)=>publicKey=v),const SizedBox(height:12),TextFormField(obscureText:true,decoration:InputDecoration(labelText:'Secret Key',hintText:hasSecret?'Kayıtlı · değiştirmek için yeni değer':'sk_test_...'),onChanged:(v)=>secretKey=v),const SizedBox(height:12),TextFormField(obscureText:true,decoration:InputDecoration(labelText:'Webhook Secret',hintText:hasWebhook?'Kayıtlı · değiştirmek için yeni değer':'Webhook secret'),onChanged:(v)=>webhookSecret=v),const SizedBox(height:12),DropdownButtonFormField<int?>(initialValue:accountId,decoration:const InputDecoration(labelText:'Tahsilatın İşleneceği Kasa / Banka'),items:[const DropdownMenuItem<int?>(value:null,child:Text('Hesap hareketi oluşturma')),...accounts.map((x)=>DropdownMenuItem<int?>(value:int.tryParse('${x['id']}'),child:Text('${x['name']}')))],onChanged:(v)=>setState(()=>accountId=v)),const SizedBox(height:8),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Kredi kartı ile aidat ödemesini etkinleştir',style:TextStyle(fontWeight:FontWeight.w800)),value:enabled,onChanged:(v)=>setState(()=>enabled=v)),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.shield_rounded),label:Text(saving?'Kaydediliyor...':'Entegrasyonu Kaydet')))])),const SizedBox(height:12),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Webhook URL',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:6),SelectableText(webhookUrl,style:const TextStyle(fontSize:11,color:muted)),const SizedBox(height:8),const Text('Bu adresi Tahsilat.com Üye İşyeri Panelindeki webhook yönetimine tanımlayın. Başarılı ödeme yalnız imzalı webhook ile aidata işlenir.',style:TextStyle(fontSize:11,color:muted))]))]);}
}
