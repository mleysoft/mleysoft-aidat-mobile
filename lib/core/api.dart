import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);
  @override String toString()=>message;
}

class Api {
  static bool? managerPackageActive;
  static const _store=FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences:true));
  static Future<String?> token()=>_store.read(key:'token');
  static Future<void> saveToken(String v)=>_store.write(key:'token',value:v);
  static Future<void> saveRole(String v)=>_store.write(key:'role',value:v);
  static Future<String?> role()=>_store.read(key:'role');
  static Future<void> clear()=>_store.deleteAll();
  static Future<Map<String,dynamic>> request(String path,{String method='GET',Map<String,dynamic>? body,bool auth=true}) async {
    final h={'Accept':'application/json','Content-Type':'application/json'};
    if(auth){final t=await token();if(t!=null)h['Authorization']='Bearer $t';}
    final parts=path.split('?');
    final base=Uri.parse('${AppConfig.apiBase}/${parts.first}.php');
    final uri=parts.length>1?base.replace(query:parts.sublist(1).join('?')):base;
    http.Response r;
    if(method=='POST') r=await http.post(uri,headers:h,body:jsonEncode(body??{})).timeout(const Duration(seconds:20));
    else r=await http.get(uri,headers:h).timeout(const Duration(seconds:20));
    dynamic d;
    try { d=jsonDecode(r.body); } catch (_) { throw ApiException('Sunucu geçersiz yanıt verdi (HTTP ${r.statusCode}).',r.statusCode); }
    if(d is! Map<String,dynamic>) throw ApiException('Sunucudan geçersiz yanıt alındı (HTTP ${r.statusCode}).',r.statusCode);
    if(r.statusCode>=400 || d['ok']!=true) throw ApiException((d['message']??'İşlem tamamlanamadı.').toString(),r.statusCode);
    if(path.startsWith('manager') && d.containsKey('subscription_active')) managerPackageActive=d['subscription_active']==true;
    return d;
  }
}
