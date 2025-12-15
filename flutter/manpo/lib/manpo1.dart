import 'package:flutter/material.dart';
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

    void start() {
    setState(() {
      running = true;
      x = 1.0;
      y = 2.0;
      z = 3.0;
      m = 3.7;
    });
  }
    void stop() {
    setState(() {
      running = false;
    });
  }
    void reset() {
    setState(() {
      x = y = z = m = 0;
    });
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
