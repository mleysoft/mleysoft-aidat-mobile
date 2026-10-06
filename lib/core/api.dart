import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
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
  static const _store=FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences:true));
  static const _sharedAuth=MethodChannel('com.mleysoft.aidat/shared_auth');
  static Future<void> _syncSharedAuth(String? value) async {
    if(!Platform.isIOS)return;
    try{await _sharedAuth.invokeMethod('setToken',{'token':value??''}).timeout(const Duration(seconds:2));}catch(_){}
  }
  static Future<String?> token() async {final v=await _store.read(key:'token');await _syncSharedAuth(v);return v;}
  static Future<void> saveToken(String v) async {await _store.write(key:'token',value:v);await _syncSharedAuth(v);}
  static Future<void> saveRole(String v)=>_store.write(key:'role',value:v);
  static Future<String?> role()=>_store.read(key:'role');
  static Future<void> clear() async {await _store.deleteAll();await _syncSharedAuth(null);}
  static Future<Map<String,dynamic>> request(String path,{String method='GET',Map<String,dynamic>? body,bool auth=true,Duration timeout=const Duration(seconds:20)}) async {
    final h={'Accept':'application/json','Content-Type':'application/json'};
    if(auth){final t=await token().timeout(const Duration(seconds:3),onTimeout:()=>null);if(t!=null)h['Authorization']='Bearer $t';}
    final parts=path.split('?');
    final base=Uri.parse('${AppConfig.apiBase}/${parts.first}.php');
    final uri=parts.length>1?base.replace(query:parts.sublist(1).join('?')):base;
    http.Response r;
    if(method=='POST') r=await http.post(uri,headers:h,body:jsonEncode(body??{})).timeout(timeout);
    else r=await http.get(uri,headers:h).timeout(timeout);
    dynamic d;
    try { d=jsonDecode(r.body); } catch (_) { throw ApiException('Sunucu geçersiz yanıt verdi (HTTP ${r.statusCode}).',r.statusCode); }
    if(d is! Map<String,dynamic>) throw ApiException('Sunucudan geçersiz yanıt alındı (HTTP ${r.statusCode}).',r.statusCode);
    if(r.statusCode>=400 || d['ok']!=true) throw ApiException((d['message']??'İşlem tamamlanamadı.').toString(),r.statusCode);
    return d;
  }
}
