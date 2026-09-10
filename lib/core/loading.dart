import 'package:flutter/material.dart';

class _LimeWaves extends StatelessWidget {
  const _LimeWaves();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(height: 180, width: double.infinity, child: CustomPaint(painter: _WavePainter())),
    ),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0x33B9F227);
    final p2 = Paint()..color = const Color(0x66B9F227);
    final p3 = Paint()..color = const Color(0xAAB9F227);
    canvas.drawPath(Path()..moveTo(0,size.height*.38)..quadraticBezierTo(size.width*.28,size.height*.04,size.width*.56,size.height*.42)..quadraticBezierTo(size.width*.78,size.height*.72,size.width,size.height*.20)..lineTo(size.width,size.height)..lineTo(0,size.height)..close(),p1);
    canvas.drawPath(Path()..moveTo(0,size.height*.64)..quadraticBezierTo(size.width*.30,size.height*.38,size.width*.55,size.height*.70)..quadraticBezierTo(size.width*.78,size.height*.92,size.width,size.height*.46)..lineTo(size.width,size.height)..lineTo(0,size.height)..close(),p2);
    canvas.drawPath(Path()..moveTo(0,size.height*.78)..quadraticBezierTo(size.width*.30,size.height*.58,size.width*.58,size.height*.82)..quadraticBezierTo(size.width*.78,size.height*.98,size.width,size.height*.66)..lineTo(size.width,size.height)..lineTo(0,size.height)..close(),p3);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class BrandLoader extends StatelessWidget {
  final bool compact;
  const BrandLoader({super.key,this.compact=false});
  @override
  Widget build(BuildContext context) {
    final lockup = Image.asset('assets/images/brand_lockup.png', fit: BoxFit.contain);
    if (compact) {
      return Center(child:Column(mainAxisSize: MainAxisSize.min, children:[
        SizedBox(width:220,height:78,child:lockup),
        const SizedBox(height:18),
        const SizedBox(width:30,height:30,child:CircularProgressIndicator(strokeWidth:3,color:Color(0xFF9BE000))),
      ]));
    }
    return Stack(children:[
      const Positioned.fill(child:_LimeWaves()),
      Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
        SizedBox(width:330,height:125,child:lockup),
        const SizedBox(height:44),
        const SizedBox(width:44,height:44,child:CircularProgressIndicator(strokeWidth:4,color:Color(0xFF9BE000),backgroundColor:Color(0xFFE4E7EC))),
        const SizedBox(height:16),
        const Text('Yükleniyor...',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:Color(0xFF344054))),
        const SizedBox(height:6),
        const Text('MleySoft Aidat',style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:Color(0xFF98A2B3))),
      ])),
    ]);
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child; final bool loading;
  const LoadingOverlay({super.key,required this.child,required this.loading});
  @override Widget build(BuildContext context)=>Stack(children:[child,if(loading)Positioned.fill(child:ColoredBox(color:Colors.white,child:const BrandLoader(compact:true)))]);
}
