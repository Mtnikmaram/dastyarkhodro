import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000/api/v1');

class ApiClient {
  String? token;
  Map<String, String> get headers => {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};

  String error(http.Response r) {
    try {
      final data = jsonDecode(r.body);
      if (data is Map && data.isNotEmpty) {
        final value = data.values.first;
        return value is List ? value.first.toString() : value.toString();
      }
    } catch (_) {}
    return 'خطا در ارتباط با سرور (${r.statusCode})';
  }

  Future<void> register(String username, String phone, String first, String last, String password) async {
    final r = await http.post(Uri.parse('$apiBaseUrl/auth/register/'), headers: headers, body: jsonEncode({
      'username': username, 'phone': phone, 'first_name': first, 'last_name': last, 'password': password,
    }));
    if (r.statusCode != 201) throw Exception(error(r));
  }

  Future<void> login(String username, String password) async {
    final r = await http.post(Uri.parse('$apiBaseUrl/auth/token/'), headers: headers, body: jsonEncode({'username': username, 'password': password}));
    if (r.statusCode != 200) throw Exception(error(r));
    token = jsonDecode(r.body)['access'];
  }

  Future<List<dynamic>> list(String path) async {
    final r = await http.get(Uri.parse('$apiBaseUrl/$path/'), headers: headers);
    if (r.statusCode != 200) throw Exception(error(r));
    final data = jsonDecode(r.body);
    return data is List ? data : (data['results'] ?? []);
  }

  Future<void> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$apiBaseUrl/$path/'), headers: headers, body: jsonEncode(body));
    if (r.statusCode != 201) throw Exception(error(r));
  }
}

void main() => runApp(const App());

InputDecoration deco(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
);

String fuelName(dynamic value) {
  const names = {'petrol': 'بنزین', 'diesel': 'دیزل', 'hybrid': 'هیبریدی', 'electric': 'برقی', 'lpg': 'LPG', 'cng': 'CNG', 'other': 'سایر'};
  return names[value] ?? value.toString();
}

String money(dynamic value) {
  final text = (double.tryParse(value.toString()) ?? 0).round().toString();
  return text.replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',');
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دستیار خودرو',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0B8F87), scaffoldBackgroundColor: const Color(0xFFF6F8F8)),
      home: LoginPage(api: ApiClient()),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api});
  final ApiClient api;
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final phone = TextEditingController();
  final first = TextEditingController();
  final last = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;

  void msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> submit() async {
    final user = username.text.trim();
    final mobile = phone.text.trim().replaceAll(' ', '');
    if (user.isEmpty || password.text.length < 8) {
      msg('نام کاربری و رمز عبور حداقل ۸ کاراکتر الزامی است.');
      return;
    }
    if (register && (first.text.trim().isEmpty || last.text.trim().isEmpty || !RegExp(r'^09\d{9}$').hasMatch(mobile))) {
      msg('نام، نام خانوادگی و شماره موبایل معتبر الزامی است.');
      return;
    }
    setState(() => busy = true);
    try {
      if (register) await widget.api.register(user, mobile, first.text.trim(), last.text.trim(), password.text);
      await widget.api.login(user, password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(api: widget.api)));
    } catch (e) {
      msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(TextEditingController c, String label, IconData icon, {bool secret = false, TextInputType? type}) {
    return TextField(controller: c, obscureText: secret, keyboardType: type, decoration: deco(label, icon));
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Icon(Icons.directions_car_filled, size: 60, color: Color(0xFF0B8F87)),
      const SizedBox(height: 10),
      const Text('دستیار خودرو', style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(register ? 'ساخت حساب کاربری' : 'ورود به حساب کاربری'),
      const SizedBox(height: 24),
      field(username, 'نام کاربری', Icons.person_outline),
    ];
    if (register) {
      children.addAll([
        const SizedBox(height: 12), field(first, 'نام', Icons.badge_outlined),
        const SizedBox(height: 12), field(last, 'نام خانوادگی', Icons.badge_outlined),
        const SizedBox(height: 12), field(phone, 'شماره موبایل', Icons.phone_android_outlined, type: TextInputType.phone),
      ]);
    }
    children.addAll([
      const SizedBox(height: 12), field(password, 'رمز عبور', Icons.lock_outline, secret: true),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'در حال اتصال...' : register ? 'ساخت حساب' : 'ورود'))),
      TextButton(onPressed: busy ? null : () => setState(() => register = !register), child: Text(register ? 'حساب دارم؛ ورود' : 'حساب ندارم؛ ثبت‌نام')),
    ]);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(margin: const EdgeInsets.all(24), child: Padding(padding: const EdgeInsets.all(26), child: SingleChildScrollView(child: Column(children: children)))),
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.api});
  final ApiClient api;
  @override State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;
  bool loading = true;
  String? error;
  List<dynamic> cars = [];
  List<dynamic> services = [];
  List<dynamic> expenses = [];
  int? selectedId;

  dynamic get car => cars.where((x) => x['id'] == selectedId).isEmpty ? null : cars.firstWhere((x) => x['id'] == selectedId);
  List<dynamic> get myServices => services.where((x) => x['vehicle'] == selectedId).toList();
  List<dynamic> get myExpenses => expenses.where((x) => x['vehicle'] == selectedId).toList();

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = await Future.wait([widget.api.list('vehicles'), widget.api.list('maintenance'), widget.api.list('expenses')]);
      if (!mounted) return;
      cars = result[0]; services = result[1]; expenses = result[2];
      if (selectedId == null && cars.isNotEmpty) selectedId = cars.first['id'];
      if (selectedId != null && !cars.any((x) => x['id'] == selectedId)) selectedId = cars.isEmpty ? null : cars.first['id'];
      setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> addVehicle() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddVehicle(api: widget.api)));
    if (ok == true) await load();
  }

  Future<void> addRecord(bool service) async {
    if (selectedId == null || car == null) { snack('اول یک خودرو ثبت کن.'); return; }
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RecordPage(api: widget.api, vehicleId: selectedId!, service: service, odometer: car['current_odometer_km'] ?? 0)));
    if (ok == true) await load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!)));
    } else if (tab == 0) {
      body = home();
    } else if (tab == 1) {
      body = records(true);
    } else if (tab == 2) {
      body = records(false);
    } else {
      body = reminders();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دستیار خودرو', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage(api: widget.api)), (_) => false);
              },
              itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('خروج از حساب'))],
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'داشبورد'),
            NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'سرویس‌ها'),
            NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'هزینه‌ها'),
            NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'یادآوری‌ها'),
          ],
        ),
        floatingActionButton: tab == 0 ? FloatingActionButton.extended(onPressed: addVehicle, icon: const Icon(Icons.add), label: const Text('افزودن خودرو')) : tab == 1 ? FloatingActionButton.extended(onPressed: () => addRecord(true), icon: const Icon(Icons.add), label: const Text('ثبت سرویس')) : tab == 2 ? FloatingActionButton.extended(onPressed: () => addRecord(false), icon: const Icon(Icons.add), label: const Text('ثبت هزینه')) : null,
      ),
    );
  }

  Widget hero() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF0B8F87), Color(0xFF0A6D68)])),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('خودرویت را هوشمند مدیریت کن', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)), SizedBox(height: 7), Text('سرویس‌ها، هزینه‌ها و یادآوری‌ها همه یکجا', style: TextStyle(color: Colors.white70))]),
  );

  Widget stat(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6), child: Column(children: [Icon(icon, size: 24), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(title, style: const TextStyle(fontSize: 12))])));
  Widget activity(IconData icon, String title, String subtitle) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title), subtitle: Text(subtitle)));

  Widget home() {
    if (cars.isEmpty) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        hero(), const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
          const Icon(Icons.directions_car_outlined, size: 64), const SizedBox(height: 12),
          const Text('هنوز خودرویی ثبت نشده', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text('اولین خودرویت را ثبت کن تا مدیریت سرویس‌ها، هزینه‌ها و یادآوری‌ها را شروع کنیم.'), const SizedBox(height: 18),
          FilledButton.icon(onPressed: addVehicle, icon: const Icon(Icons.add), label: const Text('افزودن خودرو')),
        ]))),
      ]);
    }

    final total = myExpenses.fold<double>(0, (sum, x) => sum + (double.tryParse(x['amount'].toString()) ?? 0));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 100), children: [
      hero(), const SizedBox(height: 14),
      DropdownButtonFormField<int>(value: selectedId, decoration: deco('خودروی فعال', Icons.directions_car), items: cars.map<DropdownMenuItem<int>>((x) => DropdownMenuItem<int>(value: x['id'], child: Text('${x['make']} ${x['model']}'))).toList(), onChanged: (v) => setState(() => selectedId = v)),
      const SizedBox(height: 14),
      Row(children: [Expanded(child: stat('سرویس‌ها', '${myServices.length}', Icons.build_circle_outlined)), const SizedBox(width: 8), Expanded(child: stat('هزینه‌ها', money(total), Icons.payments_outlined)), const SizedBox(width: 8), Expanded(child: stat('کیلومتر', '${car['current_odometer_km']}', Icons.speed))]),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${car['make']} ${car['model']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        Text('${car['nickname']} • ${car['year'] ?? 'سال نامشخص'} • ${fuelName(car['fuel_type'])}'), const Divider(height: 25),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(avatar: const Icon(Icons.build, size: 18), label: const Text('ثبت سرویس'), onPressed: () => addRecord(true)),
          ActionChip(avatar: const Icon(Icons.payments, size: 18), label: const Text('ثبت هزینه'), onPressed: () => addRecord(false)),
          ActionChip(avatar: const Icon(Icons.notifications, size: 18), label: const Text('یادآوری‌ها'), onPressed: () => setState(() => tab = 3)),
        ]),
      ]))),
      const SizedBox(height: 16), const Text('آخرین فعالیت‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      if (myServices.isEmpty && myExpenses.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('هنوز فعالیتی ثبت نشده است.'))),
      ...myServices.take(3).map((x) => activity(Icons.build, x['title'].toString(), '${x['service_date']} • ${money(x['cost'])} ریال')),
      ...myExpenses.take(3).map((x) => activity(Icons.payments, x['title'].toString(), '${x['expense_date']} • ${money(x['amount'])} ریال')),
    ]);
  }

  Widget records(bool service) {
    final list = service ? myServices : myExpenses;
    final title = service ? 'سوابق سرویس و تعمیرات' : 'هزینه‌های خودرو';
    final description = service ? 'تعویض روغن، ترمز، لاستیک، باتری و تعمیرات' : 'سوخت، تعمیرات، بیمه، مالیات، پارکینگ و سایر هزینه‌ها';
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(description), const SizedBox(height: 16),
      if (list.isEmpty)
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(service ? Icons.build_outlined : Icons.payments_outlined, size: 55), const SizedBox(height: 10), Text(service ? 'هنوز سرویس یا تعمیراتی ثبت نشده.' : 'هنوز هزینه‌ای ثبت نشده.'), const SizedBox(height: 12), FilledButton.icon(onPressed: () => addRecord(service), icon: const Icon(Icons.add), label: Text(service ? 'ثبت اولین سرویس' : 'ثبت اولین هزینه'))])))
      else
        ...list.map((x) => Card(child: ListTile(leading: CircleAvatar(child: Icon(service ? Icons.build : Icons.payments)), title: Text(x['title'] ?? ''), subtitle: Text('${service ? x['service_date'] : x['expense_date']} • ${x['odometer_km'] ?? '-'} کیلومتر'), trailing: Text('${money(service ? x['cost'] : x['amount'])}\nریال', textAlign: TextAlign.center)))),
    ]);
  }

  Widget reminders() {
    if (car == null) return const Center(child: Text('برای شروع یک خودرو ثبت کن.'));
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('یادآوری‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('موارد مهم خودرو را از دست نده.'), const SizedBox(height: 18),
      rem('تعویض روغن', 'بر اساس کیلومتر فعلی خودرو برنامه‌ریزی شود.', Icons.local_gas_station),
      rem('معاینه فنی', 'تاریخ اعتبار معاینه فنی را ثبت کن.', Icons.fact_check_outlined),
      rem('بیمه شخص ثالث', 'تاریخ سررسید بیمه را ثبت کن.', Icons.verified_user_outlined),
      rem('لاستیک و باتری', 'وضعیت قطعات مصرفی را دوره‌ای بررسی کن.', Icons.tire_repair),
      const SizedBox(height: 10), Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('${car['make']} ${car['model']} • کیلومتر فعلی: ${car['current_odometer_km']}'))),
    ]);
  }

  Widget rem(String title, String subtitle, IconData icon) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_left)));
}

class AddVehicle extends StatefulWidget {
  const AddVehicle({super.key, required this.api});
  final ApiClient api;
  @override State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  final nick = TextEditingController(), make = TextEditingController(), model = TextEditingController(), year = TextEditingController(), odo = TextEditingController();
  String fuel = 'petrol';
  bool busy = false;
  void msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> save() async {
    final odometer = int.tryParse(odo.text.trim());
    final buildYear = int.tryParse(year.text.trim());
    if (nick.text.trim().isEmpty || make.text.trim().isEmpty || model.text.trim().isEmpty || odometer == null) { msg('نام خودرو، برند، مدل و کیلومتر الزامی است.'); return; }
    if (year.text.trim().isNotEmpty && (buildYear == null || buildYear < 1885 || buildYear > 2200)) { msg('سال ساخت معتبر نیست.'); return; }
    setState(() => busy = true);
    try {
      final body = <String, dynamic>{'nickname': nick.text.trim(), 'make': make.text.trim(), 'model': model.text.trim(), 'current_odometer_km': odometer, 'fuel_type': fuel};
      if (buildYear != null) body['year'] = buildYear;
      await widget.api.post('vehicles', body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      const Text('مشخصات خودرو', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      TextField(controller: nick, decoration: deco('نام دلخواه خودرو', Icons.label_outline)), const SizedBox(height: 14),
      TextField(controller: make, decoration: deco('برند', Icons.directions_car)), const SizedBox(height: 14),
      TextField(controller: model, decoration: deco('مدل', Icons.car_repair)), const SizedBox(height: 14),
      TextField(controller: year, keyboardType: TextInputType.number, decoration: deco('سال ساخت', Icons.calendar_today_outlined)), const SizedBox(height: 14),
      TextField(controller: odo, keyboardType: TextInputType.number, decoration: deco('کیلومتر فعلی', Icons.speed)), const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: fuel, decoration: deco('نوع سوخت', Icons.local_gas_station_outlined), items: const [DropdownMenuItem(value: 'petrol', child: Text('بنزین')), DropdownMenuItem(value: 'diesel', child: Text('دیزل')), DropdownMenuItem(value: 'hybrid', child: Text('هیبریدی')), DropdownMenuItem(value: 'electric', child: Text('برقی')), DropdownMenuItem(value: 'lpg', child: Text('LPG')), DropdownMenuItem(value: 'cng', child: Text('CNG')), DropdownMenuItem(value: 'other', child: Text('سایر'))], onChanged: (v) { if (v != null) setState(() => fuel = v); }),
      const SizedBox(height: 24), SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save), label: Text(busy ? 'در حال ذخیره...' : 'ثبت خودرو'))),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('افزودن خودرو')), body: ListView(padding: const EdgeInsets.all(20), children: fields)));
  }
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key, required this.api, required this.vehicleId, required this.service, required this.odometer});
  final ApiClient api; final int vehicleId; final bool service; final dynamic odometer;
  @override State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final title = TextEditingController(), date = TextEditingController(), odo = TextEditingController(), amount = TextEditingController(), notes = TextEditingController();
  String category = 'other'; bool busy = false;
  final serviceCategories = const {'oil':'روغن','filter':'فیلتر','brakes':'ترمز','tires':'لاستیک','battery':'باتری','inspection':'معاینه فنی','repair':'تعمیرات','other':'سایر'};
  final expenseCategories = const {'fuel':'سوخت','repair':'تعمیرات','maintenance':'نگهداری','insurance':'بیمه','tax':'مالیات','parking':'پارکینگ','wash':'کارواش','other':'سایر'};
  void msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override void initState() { super.initState(); date.text = DateTime.now().toIso8601String().substring(0, 10); odo.text = widget.odometer.toString(); category = widget.service ? 'oil' : 'fuel'; }

  Future<void> save() async {
    final odometer = int.tryParse(odo.text.trim()) ?? 0;
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (title.text.trim().isEmpty || value == null) { msg('عنوان و مبلغ را کامل وارد کن.'); return; }
    setState(() => busy = true);
    try {
      if (widget.service) {
        await widget.api.post('maintenance', {'vehicle': widget.vehicleId, 'category': category, 'title': title.text.trim(), 'service_date': date.text.trim(), 'odometer_km': odometer, 'cost': value, 'currency': 'IRR', 'notes': notes.text.trim()});
      } else {
        await widget.api.post('expenses', {'vehicle': widget.vehicleId, 'category': category, 'title': title.text.trim(), 'expense_date': date.text.trim(), 'odometer_km': odometer, 'amount': value, 'currency': 'IRR', 'notes': notes.text.trim()});
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.service ? serviceCategories : expenseCategories;
    final fields = <Widget>[
      Text(widget.service ? 'سرویس یا تعمیر جدید' : 'هزینه جدید', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      TextField(controller: title, decoration: deco('عنوان', widget.service ? Icons.build : Icons.payments)), const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: category, decoration: deco('دسته‌بندی', Icons.category_outlined), items: categories.entries.map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value))).toList(), onChanged: (v) { if (v != null) setState(() => category = v); }),
      const SizedBox(height: 14), TextField(controller: amount, keyboardType: TextInputType.number, decoration: deco('مبلغ (ریال)', Icons.currency_exchange)), const SizedBox(height: 14),
      TextField(controller: date, decoration: deco('تاریخ YYYY-MM-DD', Icons.calendar_today)), const SizedBox(height: 14), TextField(controller: odo, keyboardType: TextInputType.number, decoration: deco('کیلومتر', Icons.speed)), const SizedBox(height: 14),
      TextField(controller: notes, maxLines: 3, decoration: deco('توضیحات', Icons.notes)), const SizedBox(height: 24),
      SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save), label: Text(busy ? 'در حال ذخیره...' : 'ذخیره'))),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(widget.service ? 'ثبت سرویس' : 'ثبت هزینه')), body: ListView(padding: const EdgeInsets.all(20), children: fields)));
  }
}
