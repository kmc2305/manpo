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

class _ManpoKeiState extends State<ManpoKeiPage> {
  // ===== 表示する値 =====
  double x = 0, y = 0, z = 0, m = 0; // 加速度センサーの値
  bool running = false;
  int steps = 0; // 歩数
  int elapsedSec = 0; // 経過秒

  // ===== 歩数判定パラメータ =====
  static double threshold = 1.2; // 閾値
  static const int minIntervalMs = 300; // 連続カウント防止（最小間隔）

  // ===== 内部状態（アルゴリズム） =====
  double _ema = 0; // 平滑化用（指数移動平均）
  double _diffPrev = 0; // 前回の差分
  int _lastStep = 0; // 前回ステップ判定した時刻(ms)

  // ===== UI更新の間引き =====
  int _lastUi = 0;
  final int uiFps = 33; // 約30fps（ms間隔）

  // 操作：開始
  Future<void> start() async {
    if (running) return;

    // iOS Safari 対応（ボタンタップ後に許可）
    await _manpo.requestMotionPermission().toDart;

    final startMs = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      running = true;
      elapsedSec = 0;
    });

    _manpo.startMotion(((num ax, num ay, num az, num t) {
      _onMotion(ax, ay, az, t, startMs);
    }).toJS);
  }

  // 加速度センサーの更新処理
  void _onMotion(num ax, num ay, num az, num t, int startMs) {
    final now = t.toInt();
    final dx = ax.toDouble();
    final dy = ay.toDouble();
    final dz = az.toDouble();
    final mm = sqrt(dx * dx + dy * dy + dz * dz);

    // 歩数判定（簡易）
    _ema = 0.9 * _ema + 0.1 * mm;
    final diff = mm - _ema;

    // 閾値を下から上に跨いだら1歩（かつ連打防止）
    if (_diffPrev <= threshold &&
        diff > threshold &&
        now - _lastStep > minIntervalMs) {
      steps++;
      _lastStep = now;
    }
    _diffPrev = diff;

    // UI更新（間引き）
    if (now - _lastUi >= uiFps) {
      _lastUi = now;
      setState(() {
        x = dx;
        y = dy;
        z = dz;
        m = mm;
        elapsedSec = ((now - startMs) / 1000).floor();
      });
    }
  }

  // 操作：停止
  void stop() {
    _manpo.stopMotion();
    setState(() => running = false);
  }

  // 操作：リセット
  void reset() {
    setState(() {
      steps = 0;
      x = y = z = m = 0;
      _ema = 0;
      _diffPrev = 0;
      _lastStep = 0;
      elapsedSec = 0;
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
      appBar: AppBar(title: const Text('🐧 スマホで万歩計 🐾')),
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
          const SizedBox(height: 12),
          _line('👟 歩数', '$steps [歩]'),
          _line('⌛ 時間', '$elapsedSec [秒]'),
          const Divider(),
          _line('↔️ x', x.toStringAsFixed(2)),
          _line('↕️ y', y.toStringAsFixed(2)),
          _line('⤵️ z', z.toStringAsFixed(2)),
          _line('📐 m', m.toStringAsFixed(2)),
        ]),
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 80, child: Text(k)),
          Text(
            v,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ]),
      );
}
