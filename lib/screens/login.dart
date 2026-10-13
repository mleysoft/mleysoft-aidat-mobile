import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/turkey_provinces.dart';
import '../core/api.dart';import '../core/loading.dart';import '../core/push.dart';import '../core/ui.dart';import 'shell.dart';import 'manager_shell.dart';import 'admin_shell.dart';
class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_LoginScreenState();}
class _LoginScreenState extends State<LoginScreen>{
static final TextInputFormatter _residentPhoneFormatter=TextInputFormatter.withFunction((oldValue,newValue){
  var digits=newValue.text.replaceAll(RegExp(r'\D'),'');
  final addedZero=digits.startsWith('5');
  if(addedZero)digits='0$digits';
  if(digits.length>11)digits=digits.substring(0,11);
  var offset=newValue.selection.baseOffset+(addedZero?1:0);
  if(offset<0)offset=0;if(offset>digits.length)offset=digits.length;
  return TextEditingValue(text:digits,selection:TextSelection.collapsed(offset:offset));
});int tab=0;bool busy=false,hide=true,otpSent=false,register=false;String? err,province;final email=TextEditingController(),pw=TextEditingController(),phone=TextEditingController(),otp=TextEditingController(),name=TextEditingController(),regPhone=TextEditingController(),districtController=TextEditingController();
Future<void>_openLegal(String page)async{
  final base=AppConfig.legalUrl(page);
  final uri=Uri.parse(base).replace(queryParameters:{...Uri.parse(base).queryParameters,'app':'1'});
  try{
    // HTTPS sayfaları için canLaunchUrl kontrolü kullanmıyoruz. iOS'ta bu kontrol,
    // sistem sorgu izinleri nedeniyle URL açılabilir olsa bile false dönebiliyor.
    var opened=await launchUrl(uri,mode:LaunchMode.inAppBrowserView);
    if(!opened){opened=await launchUrl(uri,mode:LaunchMode.inAppWebView);}
    if(!opened){opened=await launchUrl(uri,mode:LaunchMode.externalApplication);}
    if(!opened)throw Exception('URL açılamadı');
  }catch(_){
    if(mounted)setState(()=>err='Bağlantı açılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.');
  }
}
Widget _legalLinks()=>Wrap(alignment:WrapAlignment.center,spacing:4,runSpacing:2,children:[TextButton(onPressed:()=>_openLegal('gizlilik-politikasi.php'),child:const Text('Gizlilik Politikası',style:TextStyle(fontSize:11))),TextButton(onPressed:()=>_openLegal('kullanim-kosullari.php'),child:const Text('Kullanım Koşulları',style:TextStyle(fontSize:11))),TextButton(onPressed:()=>_openLegal('kvkk.php'),child:const Text('KVKK',style:TextStyle(fontSize:11)))]);
Future<void>managerLogin()async{await _run(()async{final d=await Api.request('login',method:'POST',auth:false,body:{'identifier':email.text.trim(),'password':pw.text});await _enter(d);});}
Future<void>sendOtp()async{await _run(()async{final d=await Api.request('resident-otp-request',method:'POST',auth:false,body:{'phone':phone.text.trim()});if(d['demo_login']==true&&d['token']!=null){await _enter(d);return;}if(mounted)setState(()=>otpSent=true);});}
Future<void>verifyOtp()async{await _run(()async{
 final d=await Api.request('resident-otp-verify',method:'POST',auth:false,body:{'phone':phone.text.trim(),'code':otp.text.trim()});
 if(d['selection_required']==true){
  final choices=List<Map<String,dynamic>>.from((d['choices'] as List).map((e)=>Map<String,dynamic>.from(e)));
  if(!mounted)return;
  final pick=await showApartmentPicker(context,choices,title:'Dairenizi Seçin');
  if(pick==null)return;
  final selected=await Api.request('resident-select',method:'POST',auth:false,body:{'selection_token':d['selection_token'],'apartment_id':pick['apartment_id']});
  await _enter(selected);
  return;
 }
 await _enter(d);
});}
Future<void>doRegister() async {
  final fullName=name.text.trim();
  final mail=email.text.trim();
  final mobile=regPhone.text.trim().replaceAll(RegExp(r'\D'), '');
  if(fullName.length<3){setState(()=>err='Lütfen adınızı ve soyadınızı girin.');return;}
  if(!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(mail)){setState(()=>err='Geçerli bir e-posta adresi girin.');return;}
  if(!RegExp(r'^(0?5\d{9}|905\d{9})$').hasMatch(mobile)){setState(()=>err='Geçerli bir cep telefonu numarası girin.');return;}
  if(province==null||province!.isEmpty){setState(()=>err='Lütfen il seçin.');return;}
  final district=districtController.text.trim();
  if(district.length<2||district.length>100){setState(()=>err='Lütfen geçerli bir ilçe adı girin (2-100 karakter).');return;}
  if(pw.text.length<6){setState(()=>err='Şifre en az 6 karakter olmalıdır.');return;}
  await _run(()async{
    final d=await Api.request('register',method:'POST',auth:false,body:{
      'full_name':fullName,'email':mail,'phone':mobile,'province':province,'district':district,'password':pw.text
    });
    await _enter(d);
  });
}
Future<void>_enter(Map<String,dynamic>d)async{await Api.saveToken(d['token']);final u=Map<String,dynamic>.from(d['user']);final role=(u['role']??'resident').toString();await Api.saveRole(role);try{await PushService.syncToken().timeout(const Duration(seconds:4));}catch(_){}if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>role=='manager'?const ManagerShell():role=='super_admin'?const AdminShell():const AppShell()),(_)=>false);}
Future<void>_run(Future<void> Function() f)async{setState(()=>{busy=true,err=null});try{await f();}catch(e){if(mounted)setState(()=>err=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}
@override Widget build(BuildContext c)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:()=>FocusManager.instance.primaryFocus?.unfocus(),child:Scaffold(resizeToAvoidBottomInset:true,body:LoadingOverlay(loading:busy,child:Container(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFFF7FCEB),bg])),child:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(children:[Image.asset('assets/images/brand_lockup.png',height:72),const SizedBox(height:24),Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:const Color(0xFFE9EDF2),borderRadius:BorderRadius.circular(17)),child:Row(children:[_tab('Yönetici Girişi',0,Icons.admin_panel_settings_rounded),_tab('Daire Girişi',1,Icons.home_rounded)])),const SizedBox(height:20),SoftCard(padding:const EdgeInsets.all(20),child:register?_register():tab==0?_manager():_resident()),const SizedBox(height:18),const Text('MleySoft • Güvenli Aidat Yönetimi',style:TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w700)),const SizedBox(height:4),_legalLinks()])))))))));
Widget _tab(String t,int i,IconData icon)=>Expanded(child:InkWell(borderRadius:BorderRadius.circular(13),onTap:()=>setState(()=>{tab=i,register=false,err=null}),child:AnimatedContainer(duration:const Duration(milliseconds:180),padding:const EdgeInsets.symmetric(vertical:13),decoration:BoxDecoration(color:tab==i&&!register?ink:Colors.transparent,borderRadius:BorderRadius.circular(13)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:18,color:tab==i&&!register?Colors.white:muted),const SizedBox(width:6),Text(t,style:TextStyle(fontWeight:FontWeight.w800,color:tab==i&&!register?Colors.white:muted))]))));
Widget _error()=>err==null?const SizedBox.shrink():Container(width:double.infinity,margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:danger.withValues(alpha:.08),borderRadius:BorderRadius.circular(12)),child:Text(err!,style:const TextStyle(color:danger,fontWeight:FontWeight.w600)));
Widget _manager()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Yönetici girişi',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:5),const Text('Süper admin ve site yöneticileri için.',style:TextStyle(color:muted)),const SizedBox(height:18),_error(),TextField(controller:email,keyboardType:TextInputType.emailAddress,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'E-posta',prefixIcon:Icon(Icons.mail_rounded))),const SizedBox(height:12),TextField(controller:pw,obscureText:hide,textInputAction:TextInputAction.done,onSubmitted:(_)=>FocusManager.instance.primaryFocus?.unfocus(),decoration:InputDecoration(labelText:'Şifre',prefixIcon:const Icon(Icons.lock_rounded),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:managerLogin,child:const Text('Yönetici Girişi'))),TextButton(onPressed:()=>setState((){register=true;err=null;}),child:const Text('Hesabınız yok mu? Kayıt Ol'))]);
Widget _resident()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Daire sakini girişi',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:5),const Text('Şifre yok. Giriş anahtarınız WhatsApp mesajı olarak gelir.',style:TextStyle(color:muted,height:1.4)),const SizedBox(height:16),Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFEFFFE8),borderRadius:BorderRadius.circular(13)),child:const Row(children:[Icon(Icons.chat_rounded,color:success),SizedBox(width:9),Expanded(child:Text('Kayıtlı cep telefonunuza 6 haneli tek kullanımlık kod gönderilir.',style:TextStyle(fontWeight:FontWeight.w700,color:ink)))])),const SizedBox(height:16),_error(),TextField(controller:phone,readOnly:otpSent,keyboardType:TextInputType.phone,textInputAction:TextInputAction.done,onSubmitted:(_)=>FocusManager.instance.primaryFocus?.unfocus(),inputFormatters:[_residentPhoneFormatter],decoration:const InputDecoration(labelText:'Cep Telefonu',hintText:'05xx xxx xx xx',prefixIcon:Icon(Icons.phone_iphone_rounded))),if(otpSent)...[const SizedBox(height:12),TextField(controller:otp,keyboardType:TextInputType.number,textInputAction:TextInputAction.done,onSubmitted:(_)=>FocusManager.instance.primaryFocus?.unfocus(),maxLength:6,textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,letterSpacing:7),decoration:const InputDecoration(labelText:'WhatsApp Kodu',counterText:''))],const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:otpSent?verifyOtp:sendOtp,icon:Icon(otpSent?Icons.verified_user_rounded:Icons.send_rounded),label:Text(otpSent?'Kodu Onayla ve Giriş Yap':'WhatsApp Kodunu Gönder'))),if(otpSent)TextButton(onPressed:()=>setState(()=>{otpSent=false,otp.clear()}),child:const Text('Farklı numara kullan'))]);
Widget _register()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[IconButton(onPressed:()=>setState(()=>register=false),icon:const Icon(Icons.arrow_back_rounded)),const Expanded(child:Text('Yeni Yönetici Kaydı',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:ink)))]),const Text('Ücretsiz yönetici hesabınızı oluşturun. Giriş yaptıktan sonra ilk sitenizi ekleyip blok, daire ve aidat işlemlerini kullanabilirsiniz. Kayıt sırasında ödeme veya paket seçimi istenmez.',style:TextStyle(color:muted,height:1.4)),const SizedBox(height:16),_error(),TextField(controller:name,decoration:const InputDecoration(labelText:'Ad Soyad *',prefixIcon:Icon(Icons.person_rounded))),const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'E-posta *',prefixIcon:Icon(Icons.mail_rounded))),const SizedBox(height:10),TextField(controller:regPhone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefon *',prefixIcon:Icon(Icons.phone_rounded))),const SizedBox(height:10),DropdownButtonFormField<String>(value:province,isExpanded:true,menuMaxHeight:330,decoration:const InputDecoration(labelText:'İl *',prefixIcon:Icon(Icons.location_city_rounded)),hint:const Text('İl seçiniz'),items:turkeyProvinces.map((p)=>DropdownMenuItem<String>(value:p,child:Text(p,overflow:TextOverflow.ellipsis))).toList(),onChanged:busy?null:(v)=>setState((){province=v;districtController.clear();err=null;})),const SizedBox(height:10),TextField(controller:districtController,textCapitalization:TextCapitalization.words,textInputAction:TextInputAction.next,maxLength:100,decoration:const InputDecoration(labelText:'İlçe *',hintText:'Örn. Çankaya',prefixIcon:Icon(Icons.place_outlined),counterText:'')),const SizedBox(height:10),TextField(controller:pw,obscureText:hide,textInputAction:TextInputAction.done,onSubmitted:(_)=>FocusManager.instance.primaryFocus?.unfocus(),decoration:const InputDecoration(labelText:'Şifre (en az 6 karakter) *',prefixIcon:Icon(Icons.lock_rounded))),const SizedBox(height:12),const SoftCard(child:Text('Kayıt ücretsizdir. İlk siteyi giriş yaptıktan sonra oluşturabilirsiniz; mobil uygulamada yazılım paketi satın alma işlemi bulunmaz.',style:TextStyle(color:muted,fontSize:12,fontWeight:FontWeight.w700))),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:doRegister,child:const Text('Ücretsiz Yönetici Hesabı Oluştur')))]);
}
