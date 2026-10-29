import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

class ApiClient {
  String? token;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String error(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map && d.isNotEmpty) {
        final v = d.values.first;
        return v is List ? v.first.toString() : v.toString();
      }
    } catch (_) {}
    return 'خطا در ارتباط با سرور (${r.statusCode})';
  }

  Future<void> register({
    required String username,
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final r = await http.post(
      Uri.parse('$apiBaseUrl/auth/register/'),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }),
    );
    if (r.statusCode != 201) throw Exception(error(r));
  }

  Future<void> login(String username, String password) async {
    final r = await http.post(
      Uri.parse('$apiBaseUrl/auth/token/'),
      headers: headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception(error(r));
    token = jsonDecode(r.body)['access'];
  }

  Future<List<dynamic>> vehicles() async {
    final r = await http.get(
      Uri.parse('$apiBaseUrl/vehicles/'),
      headers: headers,
    );
    if (r.statusCode != 200) throw Exception(error(r));
    return jsonDecode(r.body);
  }
}

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دستیار خودرو',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF10A7A0),
      ),
      home: LoginPage(api: ApiClient()),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final phone = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();

  bool registerMode = false;
  bool busy = false;

  InputDecoration field(String label, IconData icon) => InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  Future<void> submit() async {
    final u = username.text.trim();
    final p = phone.text.trim().replaceAll(' ', '');

    if (u.isEmpty || password.text.length < 8) {
      show('نام کاربری و رمز عبور حداقل ۸ کاراکتر الزامی است.');
      return;
    }

    if (registerMode &&
        (firstName.text.trim().isEmpty ||
            lastName.text.trim().isEmpty ||
            !RegExp(r'^09\d{9}$').hasMatch(p))) {
      show('نام، نام خانوادگی و شماره موبایل معتبر الزامی است.');
      return;
    }

    setState(() => busy = true);
    try {
      if (registerMode) {
        await widget.api.register(
          username: u,
          phone: p,
          firstName: firstName.text.trim(),
          lastName: lastName.text.trim(),
          password: password.text,
        );
      }
      await widget.api.login(u, password.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Dashboard(api: widget.api)),
        );
      }
    } catch (e) {
      show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      TextField(
        controller: username,
        decoration: field('نام کاربری', Icons.person_outline),
      ),
      if (registerMode) ...[
        const SizedBox(height: 12),
        TextField(
          controller: firstName,
          decoration: field('نام', Icons.badge_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: lastName,
          decoration: field('نام خانوادگی', Icons.badge_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: field('شماره موبایل', Icons.phone_android_outlined),
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: password,
        obscureText: true,
        decoration: field('رمز عبور', Icons.lock_outline),
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy ? 'در حال اتصال...' : (registerMode ? 'ساخت حساب' : 'ورود'),
          ),
        ),
      ),
      TextButton(
        onPressed: busy ? null : () => setState(() => registerMode = !registerMode),
        child: Text(
          registerMode ? 'حساب دارم؛ ورود' : 'حساب ندارم؛ ثبت‌نام',
        ),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.directions_car_filled_rounded,
                        size: 55,
                        color: Color(0xFF10A7A0),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'دستیار خودرو',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        registerMode
                            ? 'ساخت حساب کاربری'
                            : 'ورود به حساب کاربری',
                      ),
                      const SizedBox(height: 25),
                      ...fields,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.api});
  final ApiClient api;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<dynamic> cars = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.vehicles();
      if (mounted) setState(() => cars = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دستیار خودرو')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'خودروهای من',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Text(error!)
            else if (cars.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Text('هنوز خودرویی ثبت نکرده‌ای.'),
                ),
              )
            else
              ...cars.map(
                (v) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('${v['make']} ${v['model']}'),
                    subtitle: Text(
                      '${v['nickname']} • ${v['current_odometer_km']} کیلومتر',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
