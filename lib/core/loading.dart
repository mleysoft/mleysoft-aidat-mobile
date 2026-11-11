import 'package:flutter/material.dart';
import 'ui.dart';

/// v195: Marka yükleyicisi (yeniden tasarlandı). Sade, hafif ve iPad'de ortalı.
class BrandLoader extends StatefulWidget {
  final bool compact;
  const BrandLoader({super.key, this.compact = false});
  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.compact ? 56.0 : 76.0;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.scale(scale: 1 + (_c.value * .05), child: child),
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(logoSize * .28), boxShadow: const [BoxShadow(color: Color(0x220F766E), blurRadius: 24, offset: Offset(0, 10))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(logoSize * .28), child: Image.asset('assets/images/aidat_icon.png', fit: BoxFit.cover)),
          ),
        ),
        SizedBox(height: widget.compact ? 16 : 24),
        SizedBox(
          width: widget.compact ? 120 : 150,
          child: ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(minHeight: 4, color: primary, backgroundColor: line)),
        ),
        if (!widget.compact) ...[
          const SizedBox(height: 14),
          const Text('Yükleniyor…', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: muted)),
        ],
      ]),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool loading;
  const LoadingOverlay({super.key, required this.child, required this.loading});
  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        if (loading)
          const Positioned.fill(
            child: ColoredBox(color: Color(0xE6FFFFFF), child: BrandLoader(compact: true)),
          ),
      ]);
}
