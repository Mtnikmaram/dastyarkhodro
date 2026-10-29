import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000/api/v1');

class ApiClient {
  String? token;
  Map<String, String> get headers => {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  String error(http.Response r) { try { final d = jsonDecode(r.body); if (d is Map && d.isNotEmpty) { final v = d.values.first; return v is List ? v.first.toString() : v.toString(); } } catch (_) {} return 'خطا در ارتباط با سرور (${r.statusCode})'; }

  Future<void> register({required String username, required String phone, required String firstName, required String lastName, required String password}) async {
    final r = await http.post(Uri.parse('$apiBaseUrl/auth/register/'), headers: headers, body: jsonEncode({'username': username, 'phone': phone, 'first_name': firstName, 'last_name': lastName, 'password': password}));
    if (r.statusCode != 201) throw Exception(error(r));
  }
  Future<void> login(String username, String password) async {
    final r = await http.post(Uri.parse('$apiBaseUrl/auth/token/'), headers: headers, body: jsonEncode({'username': username, 'password': password}));
    if (r.statusCode != 200) throw Exception(error(r));
    token = jsonDecode(r.body)['access'];
  }
  Future<List<dynamic>> vehicles() async {
    final r = await http.get(Uri.parse('$apiBaseUrl/vehicles/'), headers: headers);
    if (r.statusCode != 200) throw Exception(error(r));
    return jsonDecode(r.body);
  }
  Future<void> addVehicle({required String nickname, required String make, required String model, int? year, required int odometer, required String fuelType}) async {
    final body = {'nickname': nickname, 'make': make, 'model': model, 'current_odometer_km': odometer, 'fuel_type': fuelType};
    if (year != null) body['year'] = year;
    final r = await http.post(Uri.parse('$apiBaseUrl/vehicles/'), headers: headers, body: jsonEncode(body));
    if (r.statusCode != 201) throw Exception(error(r));
  }
}

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'دستیار خودرو', theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF10A7A0)), home: LoginPage(api: ApiClient()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api}); final ApiClient api;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(), phone = TextEditingController(), firstName = TextEditingController(), lastName = TextEditingController(), password = TextEditingController();
  bool registerMode = false, busy = false;
  InputDecoration field(String label, IconData icon) => InputDecoration(labelText: '$label *', prefixIcon: Icon(icon), border: const OutlineInputBorder());
  Future<void> submit() async {
    final u = username.text.trim(), p = phone.text.trim().replaceAll(' ', '');
    if (u.isEmpty || password.text.length < 8) { show('نام کاربری و رمز عبور حداقل ۸ کاراکتر الزامی است.'); return; }
    if (registerMode && (firstName.text.trim().isEmpty || lastName.text.trim().isEmpty || !RegExp(r'^09\d{9}$').hasMatch(p))) { show('نام، نام خانوادگی و شماره موبایل معتبر الزامی است.'); return; }
    setState(() => busy = true);
    try { if (registerMode) await widget.api.register(username: u, phone: p, firstName: firstName.text.trim(), lastName: lastName.text.trim(), password: password.text); await widget.api.login(u, password.text); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(api: widget.api))); }
    catch (e) { show(e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); }
  }
  void show(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override Widget build(BuildContext context) {
    final fields = <Widget>[TextField(controller: username, decoration: field('نام کاربری', Icons.person_outline)), if (registerMode) ...[const SizedBox(height: 12), TextField(controller: firstName, decoration: field('نام', Icons.badge_outlined)), const SizedBox(height: 12), TextField(controller: lastName, decoration: field('نام خانوادگی', Icons.badge_outlined)), const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: field('شماره موبایل', Icons.phone_android_outlined))], const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: field('رمز عبور', Icons.lock_outline)), const SizedBox(height: 18), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'در حال اتصال...' : (registerMode ? 'ساخت حساب' : 'ورود')))), TextButton(onPressed: busy ? null : () => setState(() => registerMode = !registerMode), child: Text(registerMode ? 'حساب دارم؛ ورود' : 'حساب ندارم؛ ثبت‌نام'))];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Card(margin: const EdgeInsets.all(24), child: Padding(padding: const EdgeInsets.all(28), child: SingleChildScrollView(child: Column(children: [const Icon(Icons.directions_car_filled_rounded, size: 55, color: Color(0xFF10A7A0)), const SizedBox(height: 12), const Text('دستیار خودرو', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(registerMode ? 'ساخت حساب کاربری' : 'ورود به حساب کاربری'), const SizedBox(height: 25), ...fields])))))));
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.api}); final ApiClient api;
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  List<dynamic> cars = []; bool loading = true; String? error;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { setState(() { loading = true; error = null; }); try { final data = await widget.api.vehicles(); if (mounted) setState(() => cars = data); } catch (e) { if (mounted) setState(() => error = e.toString()); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> openAdd() async { final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddVehiclePage(api: widget.api))); if (added == true) load(); }
  String fuelLabel(String value) => {'petrol':'بنزین','diesel':'دیزل','hybrid':'هیبریدی','electric':'برقی','lpg':'LPG','cng':'CNG','other':'سایر'}[value] ?? value;
  @override Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('دستیار خودرو'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]), floatingActionButton: FloatingActionButton.extended(onPressed: openAdd, icon: const Icon(Icons.add), label: const Text('افزودن خودرو')), body: RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [const Text('خودروهای من', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('خودروها را ثبت کن تا سرویس، هزینه و یادآوری‌ها را مدیریت کنیم.'), const SizedBox(height: 18), if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())) else if (error != null) Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(error!))) else if (cars.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.directions_car_outlined, size: 60), const SizedBox(height: 12), const Text('هنوز خودرویی ثبت نکرده‌ای.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('از دکمه «افزودن خودرو» شروع کن.')])) ) else ...cars.map((v) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.all(12), leading: CircleAvatar(radius: 27, child: const Icon(Icons.directions_car)), title: Text('${v['make']} ${v['model']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), subtitle: Padding(padding: const EdgeInsets.only(top: 7), child: Text('${v['nickname']}  •  ${v['year'] ?? 'سال نامشخص'}\n${v['current_odometer_km']} کیلومتر  •  ${fuelLabel(v['fuel_type'])}')), isThreeLine: true))))]));
  }
}

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key, required this.api}); final ApiClient api;
  @override State<AddVehiclePage> createState() => _AddVehiclePageState();
}
class _AddVehiclePageState extends State<AddVehiclePage> {
  final nickname = TextEditingController(), make = TextEditingController(), model = TextEditingController(), year = TextEditingController(), odo = TextEditingController();
  String fuel = 'petrol'; bool busy = false;
  InputDecoration field(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder());
  Future<void> save() async {
    if (nickname.text.trim().isEmpty || make.text.trim().isEmpty || model.text.trim().isEmpty || int.tryParse(odo.text.trim()) == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام خودرو، برند، مدل و کیلومتر فعلی را کامل وارد کن.'))); return; }
    final y = year.text.trim().isEmpty ? null : int.tryParse(year.text.trim()); if (year.text.trim().isNotEmpty && y == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سال ساخت معتبر نیست.'))); return; }
    setState(() => busy = true);
    try { await widget.api.addVehicle(nickname: nickname.text.trim(), make: make.text.trim(), model: model.text.trim(), year: y, odometer: int.parse(odo.text.trim()), fuelType: fuel); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خودرو با موفقیت ثبت شد.'))); Navigator.pop(context, true); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('افزودن خودرو')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('مشخصات خودرو', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20), TextField(controller: nickname, decoration: field('نام خودرو', Icons.label_outline)), const SizedBox(height: 14), TextField(controller: make, decoration: field('برند', Icons.directions_car)), const SizedBox(height: 14), TextField(controller: model, decoration: field('مدل', Icons.car_repair)), const SizedBox(height: 14), TextField(controller: year, keyboardType: TextInputType.number, decoration: field('سال ساخت (اختیاری)', Icons.calendar_today_outlined)), const SizedBox(height: 14), TextField(controller: odo, keyboardType: TextInputType.number, decoration: field('کیلومتر فعلی', Icons.speed)), const SizedBox(height: 14), DropdownButtonFormField<String>(value: fuel, decoration: field('نوع سوخت', Icons.local_gas_station_outlined), items: const [DropdownMenuItem(value:'petrol', child:Text('بنزین')), DropdownMenuItem(value:'diesel', child:Text('دیزل')), DropdownMenuItem(value:'hybrid', child:Text('هیبریدی')), DropdownMenuItem(value:'electric', child:Text('برقی')), DropdownMenuItem(value:'lpg', child:Text('LPG')), DropdownMenuItem(value:'cng', child:Text('CNG')), DropdownMenuItem(value:'other', child:Text('سایر'))], onChanged: (v) { if (v != null) setState(() => fuel = v); }), const SizedBox(height: 24), SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save_outlined), label: Text(busy ? 'در حال ذخیره...' : 'ثبت خودرو'))])));
}