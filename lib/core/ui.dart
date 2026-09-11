import 'package:flutter/material.dart';

const ink=Color(0xFF101828), muted=Color(0xFF667085), bg=Color(0xFFF5F7FB), brand=Color(0xFFB9F227), brandDark=Color(0xFF7FAE00), blue=Color(0xFF4F6EF7), violet=Color(0xFF7C5CFC), danger=Color(0xFFEF476F), success=Color(0xFF16B364), orange=Color(0xFFF79009);

class PageTitle extends StatelessWidget{final String title,subtitle;final Widget? action;const PageTitle(this.title,{super.key,this.subtitle='',this.action});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(20,18,20,14),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,letterSpacing:-.7,color:ink)),if(subtitle.isNotEmpty)...[const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:muted,fontSize:13))]])),if(action!=null)action!]));}
class SoftCard extends StatelessWidget{final Widget child;final EdgeInsets padding;final VoidCallback? onTap;const SoftCard({super.key,required this.child,this.padding=const EdgeInsets.all(16),this.onTap});@override Widget build(BuildContext c)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(22),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(22),child:Container(padding:padding,decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFEAECF0)),boxShadow:const [BoxShadow(color:Color(0x0A101828),blurRadius:18,offset:Offset(0,6))]),child:child)));}
class IconBubble extends StatelessWidget{final IconData icon;final Color color;const IconBubble(this.icon,this.color,{super.key});@override Widget build(BuildContext c)=>Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha:.11),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color,size:22));}
class MetricCard extends StatelessWidget{final String label,value;final IconData icon;final Color color;const MetricCard({super.key,required this.label,required this.value,required this.icon,required this.color});@override Widget build(BuildContext c)=>SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[IconBubble(icon,color),const Spacer(),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:ink,letterSpacing:-.4)),const SizedBox(height:4),Text(label,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:muted,fontWeight:FontWeight.w600))]));}
class StatusPill extends StatelessWidget{final String text;final Color color;const StatusPill(this.text,this.color,{super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:color.withValues(alpha:.10),borderRadius:BorderRadius.circular(999)),child:Text(text,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w800)));}
Widget emptyState(String text,IconData icon)=>Padding(padding:const EdgeInsets.symmetric(vertical:80),child:Column(children:[Icon(icon,size:42,color:const Color(0xFF98A2B3)),const SizedBox(height:12),Text(text,style:const TextStyle(color:muted,fontWeight:FontWeight.w600))]));

const _detailLabels=<String,String>{
  'date':'Ödeme Tarihi','apartment':'Daire','period':'Dönem','amount':'Tutar','method':'Ödeme Yöntemi',
  'balance':'Kalan Borç','reference':'Referans Kodu','due_date':'Son Ödeme Tarihi','title':'Başlık','description':'Açıklama',
  'status':'Durum','created_at':'Oluşturulma Tarihi','updated_at':'Güncellenme Tarihi','manager_note':'Yönetici Notu',
  'block_name':'Blok','door_no':'Daire No','owner_name':'Ad Soyad','owner_phone':'Telefon','floor_no':'Kat',
  'category':'Kategori','expense_date':'Gider Tarihi','note':'Not','site_name':'Site','sender_name':'Gönderen','transfer_date':'Transfer Tarihi',
  'payment_date':'Ödeme Tarihi','name':'Ad','email':'E-posta','phone':'Telefon','province':'İl','district':'İlçe','address':'Adres',
  'package_name':'Paket','billing_months':'Faturalama Süresi','grace_days':'Ek Süre','max_apartments':'Daire Limiti'
};
const _hiddenDetailKeys=<String>{'id','user_id','site_id','apartment_id','block_id','due_id','payment_id','finance_account_id','receipt_url','url','token','device_token','reference_id','created_by','updated_by','is_active'};
String detailStatus(dynamic v){switch('${v??''}'.toLowerCase()){case 'new':return 'Yeni';case 'in_progress':return 'İşlemde';case 'resolved':return 'Çözüldü';case 'closed':return 'Kapatıldı';case 'approved':return 'Onaylandı';case 'pending':return 'Bekliyor';case 'rejected':return 'Reddedildi';case 'paid':return 'Ödendi';case 'unpaid':return 'Ödenmedi';case 'cash':return 'Nakit';case 'bank':return 'Banka';case 'transfer':return 'Havale / EFT';default:return '${v??'-'}';}}
String detailValue(String key,dynamic value){if(key=='status'||key=='method')return detailStatus(value);if(['amount','balance','price'].contains(key)){final n=double.tryParse('$value');if(n!=null)return '${n.toStringAsFixed(2).replaceAll('.',',')} ₺';}return '$value';}
Future<void>showRecordDetails(BuildContext context,String title,Map<String,dynamic> data,{List<String>? fields})async{
  final keys=(fields??data.keys.where((k)=>_detailLabels.containsKey(k)&&!_hiddenDetailKeys.contains(k)).toList()).where((k)=>data[k]!=null&&'${data[k]}'.trim().isNotEmpty).toList();
  await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(x)=>Container(constraints:BoxConstraints(maxHeight:MediaQuery.of(x).size.height*.82),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(30))),child:SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[Container(margin:const EdgeInsets.only(top:10),width:42,height:4,decoration:BoxDecoration(color:const Color(0xFFD0D5DD),borderRadius:BorderRadius.circular(99))),Padding(padding:const EdgeInsets.fromLTRB(20,18,12,12),child:Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:ink,letterSpacing:-.4))),IconButton(onPressed:()=>Navigator.pop(x),icon:const Icon(Icons.close_rounded))])),const Divider(height:1),Flexible(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,18,20,28),child:Column(children:keys.map((k)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(16)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:4,child:Text(_detailLabels[k]??k,style:const TextStyle(fontSize:12,color:muted,fontWeight:FontWeight.w700))),const SizedBox(width:12),Expanded(flex:6,child:Text(detailValue(k,data[k]),textAlign:TextAlign.right,style:const TextStyle(fontSize:13,color:ink,fontWeight:FontWeight.w800,height:1.35)))]))).toList())))]))));
}


Future<Map<String,dynamic>?> showApartmentPicker(
  BuildContext context,
  List<Map<String,dynamic>> items, {
  dynamic selectedId,
  String title = 'Site / Daire Seçin',
}) async {
  final search = TextEditingController();
  String query = '';

  final result = await showModalBottomSheet<Map<String,dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .48,
      maxChildSize: .94,
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setLocal) {
          final q = query.trim().toLowerCase();
          final filtered = items.where((r) {
            if (q.isEmpty) return true;
            final haystack = '${r['site_name'] ?? ''} ${r['block_name'] ?? ''} ${r['door_no'] ?? ''}'.toLowerCase();
            return haystack.contains(q);
          }).toList();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink)),
                              const SizedBox(height: 3),
                              Text('${items.length} kayıtlı daire • Tüm kayıtlar kaydırılabilir ve aranabilir.', style: const TextStyle(fontSize: 11, color: muted)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      controller: search,
                      autofocus: false,
                      onChanged: (v) => setLocal(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Site, blok veya daire ara...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  search.clear();
                                  setLocal(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${filtered.length} / ${items.length} daire gösteriliyor', style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? emptyState('Aramanıza uygun daire bulunamadı.', Icons.search_off_rounded)
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              final active = '${r['apartment_id']}' == '$selectedId';
                              return Card(
                                elevation: 0,
                                color: active ? const Color(0xFFEAF8EF) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: active ? const Color(0xFF9BD8AE) : const Color(0xFFEAECF0)),
                                ),
                                child: ListTile(
                                  enabled: !active,
                                  leading: Icon(active ? Icons.check_circle_rounded : Icons.apartment_rounded, color: active ? success : ink),
                                  title: Text('${r['site_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  subtitle: Text('${r['block_name'] ?? ''} • Daire ${r['door_no'] ?? ''}'),
                                  trailing: Text(active ? 'Aktif' : 'Seç', style: TextStyle(fontWeight: FontWeight.w800, color: active ? success : ink)),
                                  onTap: active ? null : () => Navigator.pop(sheetContext, r),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  search.dispose();
  return result;
}
