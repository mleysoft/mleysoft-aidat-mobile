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
Future<void> _openPush(PushOpen p)async{if(!mounted)return;final r=p.route.toLowerCase();if((r=='due_detail'||r=='due-detail')&&p.id!=null){try{if(p.apartmentId!=null){final sw=await Api.request('resident-switch',method:'POST',body:{'apartment_id':int.tryParse(p.apartmentId!)});await Api.saveToken('${sw['token']}');await loadProfile();}if(!mounted)return;final id=int.tryParse(p.id!);if(id!=null){await Navigator.push(context,MaterialPageRoute(builder:(_)=>DueDetailPage(dueId:id)));if(mounted&&p.apartmentId!=null)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AppShell()),(_)=>false);}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}return;}var target=0;if(r=='announcements'||r=='announcement')target=3;else if(r=='tickets'||r=='ticket')target=4;else if(r=='dues'||r=='due')target=1;else if(r=='payments'||r=='payment')target=2;setState(()=>index=target);if(target==3)refreshBadge();}
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
@override Widget build(BuildContext c){if(d==null&&error==null)return const Center(child:BrandLoader());if(error!=null)return Center(child:Text(error!));final s=Map<String,dynamic>.from(d!['stats']??{}),me=Map<String,dynamic>.from(d!['me']??{}),recent=(d!['recent'] as List?)??[];return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:110),children:[Padding(padding:const EdgeInsets.fromLTRB(20,18,20,0),child:Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF0B1220),Color(0xFF26354D)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(28),boxShadow:const[BoxShadow(color:Color(0x25101828),blurRadius:28,offset:Offset(0,14))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.home_work_rounded,color:ink)),const Spacer(),const StatusPill('AKTİF',brand)]),const SizedBox(height:20),Text('${me['site_name']??'Sitem'}',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.5)),const SizedBox(height:5),Text('${me['name']??''}  •  ${me['apartment']??'Daire Sakini'}',style:const TextStyle(color:Color(0xFFD0D5DD),fontSize:12,fontWeight:FontWeight.w600))]))),if(d!['active_due']!=null)Padding(padding:const EdgeInsets.fromLTRB(20,16,20,0),child:_ActiveDueCard(Map<String,dynamic>.from(d!['active_due']))),const ResidentHeader('Finansal Durum','Aidat ve ödeme durumunuzun güncel özeti',Icons.insights_rounded),Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.12,children:[MetricCard(label:'Toplam Borcum',value:tl(s['debt']),icon:Icons.account_balance_wallet_rounded,color:danger),MetricCard(label:'Toplam Ödenen',value:tl(s['paid']),icon:Icons.verified_rounded,color:success),MetricCard(label:'Bu Ay Kalan',value:tl(s['this_month']),icon:Icons.calendar_month_rounded,color:orange),MetricCard(label:'Yeni Duyuru',value:'${s['unread_announcements']??0}',icon:Icons.notifications_active_rounded,color:violet)])),const Padding(padding:EdgeInsets.fromLTRB(20,26,20,10),child:Text('Son Aidat Hareketleri',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:ink))),...recent.map((x){final r=Map<String,dynamic>.from(x);final due=nv(r['balance'])>0;return Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:SoftCard(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>DueDetailPage(dueId:int.parse('${r['id']}')))),child:Row(children:[IconBubble(due?Icons.schedule_rounded:Icons.check_rounded,due?orange:success),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['period']??''}',style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:3),Text('${r['apartment']??''} • Ref: ${r['reference']??'-'}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:muted))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(tl(r['amount']),style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:4),StatusPill(due?'${tl(r['balance'])} kaldı':'Ödendi',due?danger:success)])])));})]));}}

class ModernList extends StatefulWidget{final String path,title,subtitle;final IconData icon;final Widget Function(Map<String,dynamic>) builder;const ModernList({super.key,required this.path,required this.title,required this.subtitle,required this.icon,required this.builder});@override State<ModernList> createState()=>_ModernListState();}
class _ModernListState extends State<ModernList>{bool busy=true;String? error;List items=[];Future<void>load()async{if(mounted)setState(()=>busy=true);try{final d=await Api.request(widget.path);items=d['items']??[];error=null;}catch(e){error='$e'.replaceFirst('Exception: ','');}if(mounted)setState(()=>busy=false);}@override void initState(){super.initState();load();}@override Widget build(BuildContext c){if(busy)return const Center(child:BrandLoader());return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:110),children:[ResidentHeader(widget.title,widget.subtitle,widget.icon),if(error!=null)Padding(padding:const EdgeInsets.all(20),child:SoftCard(child:Text(error!,style:const TextStyle(color:danger))))else if(items.isEmpty)emptyState('Henüz kayıt bulunmuyor',widget.icon)else ...items.map((x)=>Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:widget.builder(Map<String,dynamic>.from(x))))]));}}

class DuesPage extends StatelessWidget{const DuesPage({super.key});@override Widget build(BuildContext c)=>ModernList(path:'dues',title:'Aidatlarım',subtitle:'Borç, dönem ve referans bilgilerinizi takip edin',icon:Icons.account_balance_wallet_rounded,builder:(r){final due=nv(r['balance'])>0;return SoftCard(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>DueDetailPage(dueId:int.parse('${r['id']}')))),child:Column(children:[Row(children:[IconBubble(Icons.calendar_month_rounded,due?orange:success),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['period']??''}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:ink)),Text('${r['apartment']??''}',style:const TextStyle(fontSize:12,color:muted))])),StatusPill(due?'BORÇ VAR':'ÖDENDİ',due?danger:success)]),const Divider(height:24),Row(children:[Expanded(child:_mini('Aidat',tl(r['amount']))),Expanded(child:_mini('Kalan',tl(r['balance'])))]),const SizedBox(height:10),Align(alignment:Alignment.centerLeft,child:Text('Referans: ${r['reference']??'-'}',style:const TextStyle(fontSize:11,color:muted,fontWeight:FontWeight.w600))) ]));});}

class _ActiveDueCard extends StatelessWidget{final Map<String,dynamic> due;const _ActiveDueCard(this.due);@override Widget build(BuildContext c){final balance=nv(due['balance']);return InkWell(borderRadius:BorderRadius.circular(24),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>DueDetailPage(dueId:int.parse('${due['id']}')))),child:Ink(decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF101828),Color(0xFF344054)]),borderRadius:BorderRadius.circular(24),boxShadow:const[BoxShadow(color:Color(0x25101828),blurRadius:24,offset:Offset(0,10))]),padding:const EdgeInsets.all(18),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.receipt_long_rounded,color:ink)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('AKTİF AİDAT · DETAYLARI GÖR',style:TextStyle(fontSize:10,color:brand,fontWeight:FontWeight.w900,letterSpacing:.5)),const SizedBox(height:4),Text('${due['period']??''}',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text('${due['apartment']??''} • Son ödeme ${due['due_date']??'-'}',style:const TextStyle(color:Color(0xFFD0D5DD),fontSize:10.5))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(tl(due['amount']),style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(balance>0?'Kalan ${tl(balance)}':'Ödendi',style:TextStyle(color:balance>0?const Color(0xFFFFD166):const Color(0xFF9EF0BE),fontSize:10.5,fontWeight:FontWeight.w800)),const SizedBox(height:4),const Icon(Icons.chevron_right_rounded,color:Colors.white70,size:19)])])));}}

class DueDetailPage extends StatefulWidget{final int dueId;const DueDetailPage({super.key,required this.dueId});@override State<DueDetailPage> createState()=>_DueDetailPageState();}
class _DueDetailPageState extends State<DueDetailPage>{Map<String,dynamic>? data;String? error;@override void initState(){super.initState();load();}Future<void>load()async{try{data=await Api.request('due-detail?id=${widget.dueId}');error=null;}catch(e){error='$e'.replaceFirst('Exception: ','');}if(mounted)setState((){});}
@override Widget build(BuildContext c){if(data==null&&error==null)return const Scaffold(body:Center(child:BrandLoader()));if(error!=null)return Scaffold(appBar:AppBar(title:const Text('Aidat Detayı')),backgroundColor:bg,body:Center(child:Padding(padding:const EdgeInsets.all(24),child:SoftCard(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline_rounded,size:42,color:danger),const SizedBox(height:10),Text(error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('Tekrar Dene'))])))));final d=Map<String,dynamic>.from(data!['due']??{}),sum=Map<String,dynamic>.from(data!['summary']??{}),items=(data!['items'] as List?)??[];final status='${d['status']??'unpaid'}';return Scaffold(backgroundColor:bg,appBar:AppBar(title:const Text('Aidat Detayı')),body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(16,10,16,30),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF101828),Color(0xFF26354D)]),borderRadius:BorderRadius.circular(26),boxShadow:const[BoxShadow(color:Color(0x25101828),blurRadius:24,offset:Offset(0,10))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:brand,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.receipt_long_rounded,color:ink)),const Spacer(),StatusPill(status=='paid'?'ÖDENDİ':status=='partial'?'KISMİ ÖDENDİ':'ÖDEME BEKLİYOR',status=='paid'?success:status=='partial'?orange:danger)]),const SizedBox(height:18),const Text('DÖNEM AİDATI',style:TextStyle(fontSize:10,color:brand,fontWeight:FontWeight.w900,letterSpacing:.8)),const SizedBox(height:3),Text('${d['period_label']??''}',style:const TextStyle(fontSize:26,color:Colors.white,fontWeight:FontWeight.w900)),Text('${d['site_name']??''} • ${d['apartment']??''}',style:const TextStyle(fontSize:11,color:Color(0xFFD0D5DD))),const SizedBox(height:18),Row(children:[Expanded(child:_detailMetric('Toplam Aidat',tl(d['total_amount']))),Expanded(child:_detailMetric('Kalan',tl(d['balance'])))]),const SizedBox(height:12),Row(children:[Expanded(child:_detailMetric('Ödenen',tl(d['paid']))),Expanded(child:_detailMetric('Demirbaş Payı',tl(sum['asset_share'])))])])),
 const SizedBox(height:18),Row(children:[const Expanded(child:Text('Aidatı Oluşturan Giderler',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:ink))),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(99),border:Border.all(color:line)),child:Text('${items.length} kalem',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:muted)))]),const SizedBox(height:4),const Text('Giderin toplamını, bu dönem tutarını ve dairenize düşen payı ayrı ayrı görebilirsiniz.',style:TextStyle(color:muted,fontSize:11.5,height:1.35)),const SizedBox(height:10),
 ...items.asMap().entries.map((entry){final i=entry.key,r=Map<String,dynamic>.from(entry.value);final asset=r['is_fixed_asset']==true||r['is_fixed_asset']==1;final inst=r['installment_number'];final installment='${r['recurrence_type']}'=='installment';final remaining=r['installment_remaining'];return Padding(padding:const EdgeInsets.only(bottom:10),child:SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:asset?blue.withValues(alpha:.1):brand.withValues(alpha:.2),borderRadius:BorderRadius.circular(11)),child:Text('${i+1}'.padLeft(2,'0'),style:TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:asset?blue:ink))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['description']}',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:3),Text('${r['category']} • ${r['scope']} • ${r['applies_to_label']??''}',style:const TextStyle(fontSize:10.5,color:muted))])),if(asset)const StatusPill('DEMİRBAŞ',blue)]),if(inst!=null)Padding(padding:const EdgeInsets.only(top:9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:const Color(0xFFFFF3CD),borderRadius:BorderRadius.circular(99)),child:Text('$inst / ${r['installment_count']}. Taksit',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w900,color:Color(0xFF7A5B00)))),const SizedBox(height:5),Text('Bu taksit sonrası ${remaining??0} taksit kalır.',style:const TextStyle(fontSize:10.5,color:Color(0xFF7A5B00),fontWeight:FontWeight.w700))])),const Divider(height:22),Wrap(spacing:8,runSpacing:8,children:[_detailChip('Giderin Toplamı',tl(r['expense_total'])),_detailChip(installment?'Bu Dönem Taksiti':'Bu Dönem Gideri',tl(r['schedule_amount'])),_detailChip('Paylaştırılan','${r['target_count']??'—'} adet'),_detailChip('Dairenize Düşen',tl(r['share_amount']),strong:true)]),if('${r['note']??''}'.trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Container(width:double.infinity,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12),border:Border.all(color:line)),child:Text('${r['note']}',style:const TextStyle(fontSize:11,color:muted,height:1.35)))) ])));}),
 if(items.isEmpty)const SoftCard(child:Text('Bu eski dönem aidatı için kalem detayı bulunmuyor.',style:TextStyle(color:muted))),
 const SizedBox(height:6),SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Dağılım Özeti',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:12),_sumRow('Normal gider payı',tl(sum['normal_share'])),_sumRow('Demirbaş gider payı',tl(sum['asset_share']),asset:true),const Divider(height:22),_sumRow('Toplam aidat',tl(d['total_amount']),bold:true),if(nv(sum['asset_share'])>0)Padding(padding:const EdgeInsets.only(top:10),child:Text('Demirbaş kalemlerinin bu dönem site/blok toplamı: ${tl(sum['asset_period_total'])}',style:const TextStyle(fontSize:10.5,color:muted)))])),
 const SizedBox(height:12),SoftCard(child:Row(children:[const IconBubble(Icons.tag_rounded,violet),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Ödeme Referansı',style:TextStyle(fontSize:10,color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:2),Text('${d['reference']??'-'}',style:const TextStyle(fontWeight:FontWeight.w900))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[const Text('Son Ödeme',style:TextStyle(fontSize:10,color:muted)),Text('${d['due_date']??'-'}',style:const TextStyle(fontWeight:FontWeight.w900))])]))
 ])));}}
Widget _detailMetric(String l,String v)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l,style:const TextStyle(fontSize:9.5,color:Color(0xFFAEB8C7),fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(v,style:const TextStyle(fontSize:16,color:Colors.white,fontWeight:FontWeight.w900))]);
Widget _sumRow(String l,String v,{bool asset=false,bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[if(asset)...[const Icon(Icons.build_rounded,size:15,color:blue),const SizedBox(width:6)],Expanded(child:Text(l,style:TextStyle(color:bold?ink:muted,fontWeight:bold?FontWeight.w900:FontWeight.w600))),Text(v,style:TextStyle(fontWeight:FontWeight.w900,color:asset?blue:ink,fontSize:bold?16:14))]));
Widget _detailChip(String l,String v,{bool strong=false})=>Container(width:150,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:strong?const Color(0xFFF3FBE3):bg,borderRadius:BorderRadius.circular(12),border:Border.all(color:strong?const Color(0xFFD9EFAD):line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l,style:const TextStyle(fontSize:9.5,color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(v,style:TextStyle(fontSize:13,fontWeight:FontWeight.w900,color:strong?const Color(0xFF355F00):ink))]));

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
