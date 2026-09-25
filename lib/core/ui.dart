import 'package:flutter/material.dart';

const ink=Color(0xFF101828), muted=Color(0xFF667085), bg=Color(0xFFF5F7FB), line=Color(0xFFEAECF0), brand=Color(0xFFB9F227), brandDark=Color(0xFF7FAE00), blue=Color(0xFF4F6EF7), violet=Color(0xFF7C5CFC), danger=Color(0xFFEF476F), success=Color(0xFF16B364), orange=Color(0xFFF79009);

class PageTitle extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;
  const PageTitle(this.title, {super.key, this.subtitle = '', this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.55, color: ink)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: muted, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}
class SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeading(
    this.title, {
    super.key,
    this.subtitle = '',
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brand.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: ink),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink, letterSpacing: -.2)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, height: 1.35, color: muted, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
              boxShadow: const [BoxShadow(color: Color(0x06101828), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: child,
          ),
        ),
      );
}
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const IconBubble(this.icon, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      );
}
class MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const MetricCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [IconBubble(icon, color), const Spacer(), Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle))]),
            const SizedBox(height: 12),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink, letterSpacing: -.3)),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
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

class CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  const CompactStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.05,
                    color: ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (caption != null && caption!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryScroller extends StatelessWidget {
  final List<Widget> children;
  const SummaryScroller({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class FilterSurface extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Widget? trailing;

  const FilterSurface({
    super.key,
    this.title = 'Filtreler',
    this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.tune_rounded, color: ink, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          trailing: trailing,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class TableText extends StatelessWidget {
  final String text;
  final bool strong;
  final Color color;
  final int maxLines;
  final TextAlign textAlign;

  const TableText(
    this.text, {
    super.key,
    this.strong = false,
    this.color = ink,
    this.maxLines = 2,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.25,
        color: color,
        fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      ),
    );
  }
}

class TableAmount extends StatelessWidget {
  final String text;
  final Color color;
  const TableAmount(this.text, {super.key, this.color = ink});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 12.5,
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class ProfessionalDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final String emptyText;
  final IconData emptyIcon;

  const ProfessionalDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 760,
    this.emptyText = 'Kayıt bulunamadı.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(18),border: Border.all(color: line)),
    child: Column(children:[Icon(emptyIcon,size:34,color:const Color(0xFF98A2B3)),const SizedBox(height:9),Text(emptyText,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w700))]),
  );

  String _columnName(DataColumn c, int i) {
    final w=c.label;
    if(w is Text) return w.data ?? 'Alan ${i+1}';
    return 'Alan ${i+1}';
  }

  @override Widget build(BuildContext context) {
    if(rows.isEmpty) return _empty();
    return LayoutBuilder(builder:(context,constraints){
      // Telefonda web tablosu yerine yoğun, okunabilir mobil kayıt satırları.
      if(constraints.maxWidth < 700){
        return Column(children:List.generate(rows.length,(ri){
          final row=rows[ri];
          final cells=row.cells;
          final primary=cells.isNotEmpty?cells.first.child:const SizedBox.shrink();
          final secondary=cells.length>1?cells[1].child:null;
          return Container(
            margin:EdgeInsets.only(bottom:ri==rows.length-1?0:10),
            decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:line),boxShadow:const[BoxShadow(color:Color(0x07101828),blurRadius:14,offset:Offset(0,4))]),
            child:Material(color:Colors.transparent,borderRadius:BorderRadius.circular(18),child:InkWell(
              borderRadius:BorderRadius.circular(18),
              onTap:row.onSelectChanged==null?null:()=>row.onSelectChanged!(true),
              child:Padding(padding:const EdgeInsets.fromLTRB(15,14,15,13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Container(width:4,height:38,decoration:BoxDecoration(color:brandDark,borderRadius:BorderRadius.circular(99))),
                  const SizedBox(width:10),
                  Expanded(child:DefaultTextStyle.merge(style:const TextStyle(fontSize:14,color:ink,fontWeight:FontWeight.w900,height:1.2),child:primary)),
                  if(cells.length>2) ...[const SizedBox(width:10),Flexible(child:Align(alignment:Alignment.topRight,child:DefaultTextStyle.merge(style:const TextStyle(fontSize:13,color:ink,fontWeight:FontWeight.w900),child:cells.last.child)))],
                ]),
                if(secondary!=null)...[const SizedBox(height:5),Padding(padding:const EdgeInsets.only(left:14),child:DefaultTextStyle.merge(style:const TextStyle(fontSize:11.5,color:muted,fontWeight:FontWeight.w600),child:secondary))],
                if(cells.length>2)...[
                  const SizedBox(height:12),
                  Container(height:1,color:line),
                  const SizedBox(height:9),
                  Wrap(spacing:8,runSpacing:8,children:List.generate(cells.length-2,(j){
                    final ci=j+2;
                    // Son hücre mobil kaydın sağ üstünde zaten gösteriliyor.
                    // Böylece özellikle İŞLEMLER hücresi ikinci kez ayrı bir kutu olarak tekrarlanmaz.
                    if(ci==cells.length-1) return const SizedBox.shrink();
                    return Container(
                      constraints:BoxConstraints(minWidth:(constraints.maxWidth-54)/2,maxWidth:constraints.maxWidth-30),
                      padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),
                      decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12)),
                      child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
                        Text(_columnName(columns[ci],ci).toUpperCase(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9,color:muted,fontWeight:FontWeight.w800,letterSpacing:.25)),
                        const SizedBox(height:3),
                        DefaultTextStyle.merge(style:const TextStyle(fontSize:11.5,color:ink,fontWeight:FontWeight.w700,height:1.25),child:cells[ci].child),
                      ]),
                    );
                  }))
                ]
              ])),
            )),
          );
        }));
      }
      final width=constraints.maxWidth>minWidth?constraints.maxWidth:minWidth;
      return Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:line)),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(scrollDirection:Axis.horizontal,physics:const BouncingScrollPhysics(),child:ConstrainedBox(constraints:BoxConstraints(minWidth:width),child:DataTable(
        headingRowHeight:42,dataRowMinHeight:50,dataRowMaxHeight:62,columnSpacing:22,horizontalMargin:14,dividerThickness:.7,showCheckboxColumn:false,
        headingRowColor:WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle:const TextStyle(fontSize:10.5,color:muted,fontWeight:FontWeight.w900,letterSpacing:.15),
        dataTextStyle:const TextStyle(fontSize:12.5,color:ink,fontWeight:FontWeight.w600),columns:columns,rows:rows,
      ))));
    });
  }
}
