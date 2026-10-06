import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/loading.dart';
import '../core/ui.dart';
import '../core/push.dart';
import 'login.dart';

class AccountPage extends StatefulWidget{
  const AccountPage({super.key});
  @override State<AccountPage> createState()=>_AccountPageState();
}
class _AccountPageState extends State<AccountPage>{
  Map<String,dynamic>? user; String? error; bool deleting=false;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    try{final d=await Api.request('me');user=Map<String,dynamic>.from(d['user']??{});error=null;}
    catch(e){error='$e'.replaceFirst('Exception: ','');}
    if(mounted)setState((){});
  }
  Future<void> deleteAccount()async{
    final first=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(
      icon:const Icon(Icons.delete_forever_rounded,color:danger,size:38),
      title:const Text('Hesabımı Sil'),
      content:const Text('Hesabınız silindiğinde ad, soyad, telefon, e-posta ve giriş bilgileriniz kalıcı olarak kaldırılır. Aidat, tahsilat ve diğer finansal/operasyonel kayıtlar sistem bütünlüğü için silinmez; bu kayıtlarda kullanıcı adı “Silinen Hesap” olarak görünür. Bu işlem geri alınamaz.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Vazgeç')),FilledButton(style:FilledButton.styleFrom(backgroundColor:danger),onPressed:()=>Navigator.pop(x,true),child:const Text('Devam Et'))]
    ))??false;
    if(!first||!mounted)return;
    final finalOk=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(
      title:const Text('Son Onay'),
      content:const Text('Kişisel hesabınızı kalıcı olarak silmek istediğinize emin misiniz?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Hayır')),FilledButton(style:FilledButton.styleFrom(backgroundColor:danger),onPressed:()=>Navigator.pop(x,true),child:const Text('Evet, Hesabımı Sil'))]
    ))??false;
    if(!finalOk||!mounted)return;
    setState(()=>deleting=true);
    try{
      await Api.request('account',method:'POST',body:{'action':'delete_account','confirm':'DELETE'});
      try{await PushService.deactivateForLogout();}catch(_){}
      await Api.clear();
      if(!mounted)return;
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hesabınız ve kişisel bilgileriniz kalıcı olarak silindi.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'.replaceFirst('Exception: ',''))));}
    finally{deleting=false;if(mounted)setState((){});}
  }
  Widget row(IconData icon,String label,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:20,color:muted),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w800,color:muted)),const SizedBox(height:2),Text(value.trim().isEmpty?'—':value,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:ink))]))]));
  @override Widget build(BuildContext c)=>Scaffold(backgroundColor:bg,appBar:AppBar(title:const Text('Hesabım')),body:user==null&&error==null?const Center(child:BrandLoader()):ListView(padding:const EdgeInsets.all(18),children:[
    if(error!=null)SoftCard(child:Text(error!,style:const TextStyle(color:danger))) else ...[
      SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Hesap Bilgileri',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),row(Icons.person_outline_rounded,'AD SOYAD','${user!['name']??''}'),row(Icons.phone_outlined,'TELEFON','${user!['phone']??''}'),row(Icons.mail_outline_rounded,'E-POSTA','${user!['email']??''}'),if('${user!['site_name']??''}'.trim().isNotEmpty)row(Icons.apartment_rounded,'SİTE','${user!['site_name']}'),if('${user!['apartment']??''}'.trim().isNotEmpty)row(Icons.door_front_door_outlined,'DAİRE','${user!['apartment']}')])) ,
      const SizedBox(height:22),
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:danger.withValues(alpha:.055),borderRadius:BorderRadius.circular(18),border:Border.all(color:danger.withValues(alpha:.22))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.warning_amber_rounded,color:danger),SizedBox(width:8),Text('Hesap Silme',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:danger))]),const SizedBox(height:8),const Text('Kişisel bilgileriniz kalıcı olarak silinir. Finansal ve operasyonel kayıtlar korunur ve geçmiş kayıtlarda kullanıcı “Silinen Hesap” olarak gösterilir.',style:TextStyle(color:muted,height:1.45)),const SizedBox(height:14),SizedBox(width:double.infinity,child:OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:danger,side:const BorderSide(color:danger),padding:const EdgeInsets.symmetric(vertical:14)),onPressed:deleting?null:deleteAccount,icon:deleting?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.delete_forever_rounded),label:Text(deleting?'Hesap siliniyor...':'Hesabımı Kalıcı Olarak Sil')))]))
    ]
  ]));
}
