import 'package:flutter/material.dart';

void main() => runApp(const DastyarKhodroApp());

class DastyarKhodroApp extends StatelessWidget {
  const DastyarKhodroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF172B4D);
    const teal = Color(0xFF10A7A0);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دستیار خودرو',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: navy),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _notReady(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature در مرحله بعد فعال می‌شود.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          title: const Text('دستیار خودرو', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(onPressed: () => _notReady(context, 'اعلان‌ها'), icon: const Icon(Icons.notifications_none_rounded)),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF172B4D), Color(0xFF244A73)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('همه‌چیز درباره خودروی شما، یک‌جا', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 10),
                          Text('خودرویت را بهتر بشناس', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Text('سرویس‌ها، هزینه‌ها و یادآوری‌ها را مدیریت کن.', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(child: Text('نمای کلی', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                        FilledButton.icon(
                          onPressed: () => _notReady(context, 'افزودن خودرو'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('افزودن خودرو'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: wide ? 3 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 2.2 : 3.4,
                      children: const [
                        _MetricCard(icon: Icons.directions_car_filled_outlined, title: 'خودروهای من', value: 'هنوز خودرویی ثبت نشده', tint: Color(0xFFE8F2FF)),
                        _MetricCard(icon: Icons.build_circle_outlined, title: 'سرویس‌های پیش رو', value: 'بعد از ثبت خودرو', tint: Color(0xFFE4F8F4)),
                        _MetricCard(icon: Icons.payments_outlined, title: 'هزینه‌های ثبت‌شده', value: '۰', tint: Color(0xFFFFF2DD)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text('دسترسی سریع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 1.5 : 1.15,
                      children: [
                        _ActionCard(icon: Icons.history_rounded, title: 'سوابق سرویس', subtitle: 'تعمیرات و نگهداری', onTap: () => _notReady(context, 'سوابق سرویس')),
                        _ActionCard(icon: Icons.receipt_long_rounded, title: 'هزینه‌ها', subtitle: 'مدیریت مخارج', onTap: () => _notReady(context, 'هزینه‌ها')),
                        _ActionCard(icon: Icons.notifications_active_outlined, title: 'یادآورها', subtitle: 'سرویس و بیمه', onTap: () => _notReady(context, 'یادآورها')),
                        _ActionCard(icon: Icons.smart_toy_outlined, title: 'دستیار هوشمند', subtitle: 'راهنمای اولیه خودرو', onTap: () => _notReady(context, 'دستیار هوشمند')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(child: Text('نسخه آزمایشی • ۰٫۱٫۰', style: TextStyle(color: Color(0xFF7D8798), fontSize: 12))),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.title, required this.value, required this.tint});
  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF172B4D), size: 25)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ])),
      ]),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFF10A7A0), size: 28),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
        ]),
      ),
    ),
  );
}
