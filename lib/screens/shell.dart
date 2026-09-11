import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/loading.dart';
import '../core/ui.dart';
import '../core/push.dart';
import 'login.dart';

double nv(dynamic v)=>v is num?v.toDouble():double.tryParse('$v')??0;
String tl(dynamic v)=>'${nv(v).toStringAsFixed(2).replaceAll('.', ',')} ₺';

class AppShell extends StatefulWidget{const AppShell({super.key});@override State<AppShell> createState()=>_AppShellState();}
class _AppShellState extends State<AppShell>{int index=0,unread=0;Map<String,dynamic>? user;final pages=const[HomePage(),DuesPage(),PaymentsPage(),AnnouncementsPage(),TicketsPage()];
StreamSubscription<PushOpen>? _pushSub;
@override void initState(){super.initState();PushService.init();loadProfile();refreshBadge();_pushSub=PushService.opens.listen(_openPush);WidgetsBinding.instance.addPostFrameCallback((_){final p=PushService.takePendingOpen();if(p!=null)_openPush(p);});}
void _openPush(PushOpen p){if(!mounted)return;final r=p.route.toLowerCase();var target=0;if(r=='announcements'||r=='announcement')target=3;else if(r=='tickets'||r=='ticket')target=4;else if(r=='dues'||r=='due')target=1;else if(r=='payments'||r=='payment')target=2;setState(()=>index=target);if(target==3)refreshBadge();}
@override void dispose(){_pushSub?.cancel();super.dispose();}
Future<void>loadProfile()async{try{final d=await Api.request('me');if(mounted)setState(()=>user=Map<String,dynamic>.from(d['user']??{}));}catch(_){}}
Future<void>refreshBadge()async{try{final d=await Api.request('dashboard');final v=d['stats']?['unread_announcements'];if(mounted)setState(()=>unread=v is num?v.toInt():0);}catch(_){}}
Future<void>switchResidentApartment()async{
 try{
  final d=await Api.request('resident-apartments');
  final items=List<Map<String,dynamic>>.from((d['items'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)));
  final selected=d['selected_apartment_id'];
  if(!mounted)return;
  final pick=await showApartmentPicker(context,items,selectedId:selected,title:'Site / Daire Değiştir');
  if(pick==null)return;
  final sw=await Api.request('resident-switch',method:'POST',body:{'apartment_id':pick['apartment_id']});
  await Api.saveToken('${sw['token']}');
  if(!mounted)return;
  Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AppShell()),(_)=>false);
 }catch(e){
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));
 }
}
Future<void>logout()async{try{await Api.request('logout',method:'POST');}catch(_){}await Api.clear();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
@override
Widget build(BuildContext c) {
  final name = "${user?['name'] ?? 'Daire Sakini'}";
  final site = "${user?['site_name'] ?? 'MleySoft Aidat'}";
  return Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      toolbarHeight: 72, backgroundColor: bg, surfaceTintColor: Colors.transparent, titleSpacing: 18,
      title: Row(children: [
        Container(width: 42, height: 42, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEAECF0))), child: Image.asset('assets/images/logo.png')),
        const SizedBox(width: 11),
        Expanded(child: InkWell(borderRadius:BorderRadius.circular(12),onTap:switchResidentApartment,child:Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children:[Expanded(child:Text(site, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ink))),const SizedBox(width:4),const Icon(Icons.swap_horiz_rounded,size:16,color:success)]),Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600))])))),
      ]),
      actions: [PopupMenuButton<String>(
        icon: const CircleAvatar(radius: 18, backgroundColor: ink, child: Icon(Icons.person_rounded, color: brand, size: 19)),
        onSelected: (v) { if (v == 'logout') logout(); },
        itemBuilder: (_) => [PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text("${user?['apartment'] ?? ''}", style: const TextStyle(fontSize: 11, color: muted))])), const PopupMenuDivider(), const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded, color: danger), SizedBox(width: 9), Text('Çıkış Yap')]))],
      )],
    ),
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEAECF0)))),
      child: NavigationBar(
        height: 72, backgroundColor: Colors.white, indicatorColor: brand.withValues(alpha: .25), selectedIndex: index,
        onDestinationSelected: (v) { setState(() => index = v); if (v == 3) refreshBadge(); },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Anasayfa'),
          const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Aidatlar'),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Ödemeler'),
          NavigationDestination(icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none_rounded)), selectedIcon: const Icon(Icons.notifications_rounded), label: 'Duyurular'),
          const NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent_rounded), label: 'Talepler'),
        ],
      ),
    ),
  );
}
}

class ResidentHeader extends StatelessWidget{final String title,subtitle;final IconData icon;const ResidentHeader(this.title,this.subtitle,this.icon,{super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(20,18,20,14),child:Row(children:[IconBubble(icon,blue),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:-.6,color:ink)),const SizedBox(height:2),Text(subtitle,style:const TextStyle(color:muted,fontSize:12))]))]));}

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{Map<String,dynamic>? d;String? error;Future<void>load()async{try{final a=await Api.request('dashboard'),m=await Api.request('me');d={...a,'me':m['user']};error=null;}catch(e){error='$e'.replaceFirst('Exception: ','');}if(mounted)setState((){});}@override void initState(){super.initState();load();}
@override Widget build(BuildContext c){if(d==null&&error==null)return const Center(child:BrandLoader());if(error!=null)return Center(child:Text(error!));final s=Map<String,dynamic>.from(d!['stats']??{}),me=Map<String,dynamic>.from(d!['me']??{}),recent=(d!['recent'] as List?)??[];return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:110),children:[Padding(padding:const EdgeInsets.fromLTRB(20,18,20,0),child:Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF0B1220),Color(0xFF26354D)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(28),boxShadow:const[BoxShadow(color:Color(0x25101828),blurRadius:28,offset:Offset(0,14))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.home_work_rounded,color:ink)),const Spacer(),const StatusPill('AKTİF',brand)]),const SizedBox(height:20),Text('${me['site_name']??'Sitem'}',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.5)),const SizedBox(height:5),Text('${me['name']??''}  •  ${me['apartment']??'Daire Sakini'}',style:const TextStyle(color:Color(0xFFD0D5DD),fontSize:12,fontWeight:FontWeight.w600))]))),const ResidentHeader('Finansal Durum','Aidat ve ödeme durumunuzun güncel özeti',Icons.insights_rounded),Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.12,children:[MetricCard(label:'Toplam Borcum',value:tl(s['debt']),icon:Icons.account_balance_wallet_rounded,color:danger),MetricCard(label:'Toplam Ödenen',value:tl(s['paid']),icon:Icons.verified_rounded,color:success),MetricCard(label:'Bu Ay Kalan',value:tl(s['this_month']),icon:Icons.calendar_month_rounded,color:orange),MetricCard(label:'Yeni Duyuru',value:'${s['unread_announcements']??0}',icon:Icons.notifications_active_rounded,color:violet)])),const Padding(padding:EdgeInsets.fromLTRB(20,26,20,10),child:Text('Son Aidat Hareketleri',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:ink))),...recent.map((x){final r=Map<String,dynamic>.from(x);final due=nv(r['balance'])>0;return Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:SoftCard(child:Row(children:[IconBubble(due?Icons.schedule_rounded:Icons.check_rounded,due?orange:success),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['period']??''}',style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:3),Text('${r['apartment']??''} • Ref: ${r['reference']??'-'}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:muted))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(tl(r['amount']),style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:4),StatusPill(due?'${tl(r['balance'])} kaldı':'Ödendi',due?danger:success)])])));})]));}}

class ModernList extends StatefulWidget{final String path,title,subtitle;final IconData icon;final Widget Function(Map<String,dynamic>) builder;const ModernList({super.key,required this.path,required this.title,required this.subtitle,required this.icon,required this.builder});@override State<ModernList> createState()=>_ModernListState();}
class _ModernListState extends State<ModernList>{bool busy=true;String? error;List items=[];Future<void>load()async{if(mounted)setState(()=>busy=true);try{final d=await Api.request(widget.path);items=d['items']??[];error=null;}catch(e){error='$e'.replaceFirst('Exception: ','');}if(mounted)setState(()=>busy=false);}@override void initState(){super.initState();load();}@override Widget build(BuildContext c){if(busy)return const Center(child:BrandLoader());return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:110),children:[ResidentHeader(widget.title,widget.subtitle,widget.icon),if(error!=null)Padding(padding:const EdgeInsets.all(20),child:SoftCard(child:Text(error!,style:const TextStyle(color:danger))))else if(items.isEmpty)emptyState('Henüz kayıt bulunmuyor',widget.icon)else ...items.map((x)=>Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:widget.builder(Map<String,dynamic>.from(x))))]));}}

class DuesPage extends StatelessWidget{const DuesPage({super.key});@override Widget build(BuildContext c)=>ModernList(path:'dues',title:'Aidatlarım',subtitle:'Borç, dönem ve referans bilgilerinizi takip edin',icon:Icons.account_balance_wallet_rounded,builder:(r){final due=nv(r['balance'])>0;return SoftCard(onTap:()=>details(c,'Aidat Detayı',r),child:Column(children:[Row(children:[IconBubble(Icons.calendar_month_rounded,due?orange:success),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['period']??''}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:ink)),Text('${r['apartment']??''}',style:const TextStyle(fontSize:12,color:muted))])),StatusPill(due?'BORÇ VAR':'ÖDENDİ',due?danger:success)]),const Divider(height:24),Row(children:[Expanded(child:_mini('Aidat',tl(r['amount']))),Expanded(child:_mini('Kalan',tl(r['balance'])))]),const SizedBox(height:10),Align(alignment:Alignment.centerLeft,child:Text('Referans: ${r['reference']??'-'}',style:const TextStyle(fontSize:11,color:muted,fontWeight:FontWeight.w600))) ]));});}
class PaymentsPage extends StatelessWidget{const PaymentsPage({super.key});@override Widget build(BuildContext c)=>ModernList(path:'payments',title:'Ödemelerim',subtitle:'Gerçekleşen tahsilatlar ve ödeme geçmişiniz',icon:Icons.receipt_long_rounded,builder:(r)=>SoftCard(onTap:()=>details(c,'Ödeme Detayı',r),child:Row(children:[const IconBubble(Icons.verified_rounded,success),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['period']??''}',style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:3),Text('${r['apartment']??''} • ${r['date']??''}',style:const TextStyle(fontSize:11,color:muted))])),Text(tl(r['amount']),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:success))])));}
class AnnouncementsPage extends StatelessWidget{const AnnouncementsPage({super.key});@override Widget build(BuildContext c)=>ModernList(path:'announcements',title:'Duyurular',subtitle:'Yönetiminizden gelen güncel bilgilendirmeler',icon:Icons.notifications_active_rounded,builder:(r){final read=r['read']==true||r['read']==1;return SoftCard(onTap:()async{try{await Api.request('announcement-read',method:'POST',body:{'id':r['id']});}catch(_){}if(c.mounted)details(c,'${r['title']??'Duyuru'}',r);},child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[IconBubble(read?Icons.campaign_outlined:Icons.notifications_active_rounded,read?muted:violet),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${r['title']??''}',style:const TextStyle(fontWeight:FontWeight.w900,color:ink))),if(!read)const StatusPill('YENİ',violet)]),const SizedBox(height:6),Text('${r['body']??''}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,height:1.35)),const SizedBox(height:8),Text('${r['date']??''}',style:const TextStyle(fontSize:11,color:muted))]))]));});}

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});
  @override State<TicketsPage> createState() => _TicketsPageState();
}
class _TicketsPageState extends State<TicketsPage> {
  int k = 0;
  Future<void> add() async {
    final t = TextEditingController();
    final d = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (x) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(x).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Yeni Talep Oluştur', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          const Text('Yönetime iletmek istediğiniz konuyu açıklayın.', style: TextStyle(color: muted)),
          const SizedBox(height: 18),
          TextField(controller: t, decoration: const InputDecoration(labelText: 'Talep başlığı')),
          const SizedBox(height: 12),
          TextField(controller: d, maxLines: 4, decoration: const InputDecoration(labelText: 'Açıklama')),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await Api.request('tickets', method: 'POST', body: {'title': t.text, 'description': d.text, 'category': 'Genel', 'priority': 'normal'});
              if (x.mounted) Navigator.pop(x, true);
            },
            icon: const Icon(Icons.send_rounded), label: const Text('Yönetime Gönder'),
          ),
        ]),
      ),
    ) ?? false;
    t.dispose(); d.dispose();
    if (ok && mounted) setState(() => k++);
  }
  @override Widget build(BuildContext c) => Stack(children: [
    ModernList(
      key: ValueKey(k), path: 'tickets', title: 'Taleplerim', subtitle: 'Arıza, istek ve yönetim taleplerinizi takip edin', icon: Icons.support_agent_rounded,
      builder: (r) => SoftCard(
        onTap: () => details(c, 'Talep Detayı', r),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const IconBubble(Icons.support_agent_rounded, blue), const SizedBox(width: 12), Expanded(child: Text('${r['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900, color: ink))), StatusPill(detailStatus(r['status']), blue)]),
          const SizedBox(height: 10),
          Text('${r['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, height: 1.35)),
        ]),
      ),
    ),
    Positioned(right: 18, bottom: 18, child: FloatingActionButton.extended(backgroundColor: ink, foregroundColor: Colors.white, onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Yeni Talep', style: TextStyle(fontWeight: FontWeight.w800)))),
  ]);
}

Widget _mini(String a,String b)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:10,color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(b,style:const TextStyle(fontWeight:FontWeight.w900,color:ink))]);
void details(BuildContext c,String title,Map<String,dynamic> r){
  final fields=title.startsWith('Ödeme')
      ? <String>['period','apartment','date','amount','method']
      : title.startsWith('Aidat')
          ? <String>['period','apartment','amount','balance','due_date','reference','status']
          : <String>['title','description','status','created_at','manager_note'];
  showRecordDetails(c,title,r,fields:fields);
}
