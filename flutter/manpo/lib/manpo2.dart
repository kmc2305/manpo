import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:js_interop';

/// Web側の window.ManpoKei を参照する
@JS('ManpoKei')
external JSObject get _manpo;

/// JSとの橋渡し
extension ManpoKeiJsApi on JSObject {
  external JSPromise requestMotionPermission();
  external void startMotion(JSFunction onData);
  external void stopMotion();
}

class ManpoKeiPage extends StatefulWidget {
  const ManpoKeiPage({super.key});
  @override
  State<ManpoKeiPage> createState() => _ManpoKeiState();
}
class _ManpoKeiState extends State<ManpoKeiPage> 
{
      // ===== 表示する値 =====
  double x = 0, y = 0, z = 0, m = 0; // 加速度センサーの値
  bool running = false;              // 計測中かどうか

    // ===== UI更新の間引き =====
  int _lastUi = 0;
  final int uiFps = 33; // 約30fps

  // 操作：開始
  Future<void> start() async {
    if (running) return;

    await _manpo.requestMotionPermission().toDart;

    setState(() {
      running = true;
    });

    // JSから (ax,ay,az,t) を受け取って状態更新する
    _manpo.startMotion(((num ax, num ay, num az, num t) {
      _onMotion(ax, ay, az, t);
    }).toJS);
  }

    /// 加速度センサーの更新処理
  void _onMotion(num ax, num ay, num az, num t) {
    final now = t.toInt();
    final dx = ax.toDouble();
    final dy = ay.toDouble();
    final dz = az.toDouble();
    final mm = sqrt(dx*dx + dy*dy + dz*dz); // 合成加速度

    // --- UI更新はuiFps間隔以上に（高頻度対策）---
    if (now - _lastUi >= uiFps) {
      _lastUi = now;
      setState(() {
        x = dx;
        y = dy;
        z = dz;
        m = mm;
      });
    }
  }

      // 操作：停止
    void stop() {
      _manpo.stopMotion();
      setState(() => running = false);
    }

    void reset() {
    setState(() {
      x = y = z = m = 0;
    });
  }

    @override
  void dispose() {
    _manpo.stopMotion();
    super.dispose();
  }
  
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐧スマホで万歩計🐾')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            OutlinedButton(onPressed: start, child: const Text('開始')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: reset, child: const Text('リセット')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: stop, child: const Text('停止')),
            const SizedBox(width: 12),
            Text(running ? '計測中' : '停止中'),
          ]),
                    _line('↔️ x', x.toStringAsFixed(2)),
          _line('↕️ y', y.toStringAsFixed(2)),
          _line('⤵️ z', z.toStringAsFixed(2)),
          _line('📐 m', m.toStringAsFixed(2)),
        ]),
      ),
    );
  }
    Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 80, child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ]),
      );

}
