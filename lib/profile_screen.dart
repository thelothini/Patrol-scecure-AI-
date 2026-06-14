import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final Teacher teacher;
  const ProfileScreen({super.key, required this.teacher});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false, _saving = false;
  late TextEditingController _nameCtrl, _phoneCtrl;
  int _myReports = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.teacher.name);
    _phoneCtrl = TextEditingController(text: widget.teacher.phone);
    _fetchMyReportCount();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _fetchMyReportCount() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/get_reports'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() => _myReports = list.where((j) => j['reported_by'] == widget.teacher.teacherId).length);
      }
    } catch (_) {}
  }

  // ── PUT /update_profile/<email> ──────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final res = await http.put(
        Uri.parse('${Url.Urls}/update_profile/${widget.teacher.email}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()}),
      );
      if (!mounted) return;
      setState(() { _saving = false; _editing = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.statusCode == 200 ? 'Profile updated' : 'Failed to update'),
          backgroundColor: res.statusCode == 200 ? kSuccess : kError));
    } catch (_) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot connect to server.'), backgroundColor: kError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    return Scaffold(
      appBar: kAppBar('Profile', context, actions: [
        IconButton(
          onPressed: () { if (_editing) _saveProfile(); else setState(() => _editing = true); },
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kSuccess))
              : Icon(_editing ? Icons.check_circle_outline : Icons.edit_outlined, color: _editing ? kSuccess : kTextSec),
        ),
      ]),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SingleChildScrollView(child: Column(children: [
          _hero(t),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const KSecHeader(title: 'PERSONAL DETAILS'), const SizedBox(height: 16),
              if (_editing) ...[
                KField(label: 'Full Name', prefixIcon: Icons.person_outline, controller: _nameCtrl),
                const SizedBox(height: 12),
                KField(label: 'Phone Number', prefixIcon: Icons.phone_outlined, controller: _phoneCtrl, keyboardType: TextInputType.phone),
              ] else ...[
                KInfoRow(label: 'Full Name', value: t.name, icon: Icons.person_outline),
                KInfoRow(label: 'Teacher ID', value: t.teacherId, icon: Icons.badge_outlined),
                KInfoRow(label: 'Email', value: t.email, icon: Icons.alternate_email),
                KInfoRow(label: 'Phone', value: t.phone, icon: Icons.phone_outlined),
                KInfoRow(label: 'Department', value: t.department, icon: Icons.school_outlined),
              ],
            ])),
            const SizedBox(height: 14),
            KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const KSecHeader(title: 'DEVICE INFORMATION'), const SizedBox(height: 16),
              KInfoRow(label: 'Device Name', value: t.deviceName, icon: Icons.smartphone),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: kSuccess.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.verified, size: 12, color: kSuccess), SizedBox(width: 4),
                    Text('Registered Device', style: TextStyle(color: kSuccess, fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
            ])),
            const SizedBox(height: 14),
            KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const KSecHeader(title: 'ACTIVITY SUMMARY'), const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _statChip('My Reports', '$_myReports', kAccent)),
                const SizedBox(width: 10),
                Expanded(child: _statChip('Role', t.role.toUpperCase(), kGold)),
                const SizedBox(width: 10),
                Expanded(child: _statChip('Dept', t.department, kSuccess)),
              ]),
            ])),
            const SizedBox(height: 14),
            KCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryScreen())),
              child: const Row(children: [
                Icon(Icons.history_toggle_off, color: kAccent, size: 24), SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Login History', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w700, color: kTextPri)),
                  Text('View device login activity', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
                ])),
                Icon(Icons.chevron_right, color: kTextMut),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: KGradBtn(label: 'LOGOUT', icon: Icons.logout,
                gradient: const LinearGradient(colors: [Color(0xFFFF4D6A), Color(0xFFCC0033)]),
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false))),
            const SizedBox(height: 24),
          ])),
        ])),
      ),
    );
  }

  Widget _hero(Teacher t) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF0F2040), kPrimary.withOpacity(0)])),
        child: Column(children: [
          Stack(children: [
            Container(width: 88, height: 88,
                decoration: BoxDecoration(gradient: kAccentGrad, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]),
                child: Center(child: Text(t.name.substring(0,1),
                    style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 40, fontWeight: FontWeight.w800, color: kPrimary)))),
            Positioned(bottom: 0, right: 0, child: Container(width: 26, height: 26,
                decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 16, color: Colors.white))),
          ]),
          const SizedBox(height: 14),
          Text(t.name, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w800, color: kTextPri)),
          Text(t.teacherId, style: const TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kDivider)),
              child: Text(t.role.toUpperCase(), style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 11, letterSpacing: 2))),
        ]));
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(value, style: TextStyle(fontFamily: 'Rajdhani', fontSize: value.length > 4 ? 14 : 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 11, color: kTextMut), textAlign: TextAlign.center),
        ]));
  }
}

// ─────────────────────────────────────────────
//  LOGIN HISTORY SCREEN
// ─────────────────────────────────────────────
class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});
  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  List<LoginHistoryItem> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  // ── GET /login_history ───────────────────────────────────
  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/login_history'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _history = list.map((j) => LoginHistoryItem.fromJson(j)).toList(); _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kAppBar('Login History', context),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccent))
            : _history.isEmpty
                ? const Center(child: Text('No login history', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani')))
                : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _history.length, itemBuilder: (ctx, i) {
                    final h = _history[i];
                    final ok = h.status == 'Success';
                    return Padding(padding: const EdgeInsets.only(bottom: 10), child: KCard(
                      borderColor: ok ? null : kError.withOpacity(0.3),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: ok ? kSuccess.withOpacity(0.1) : kError.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(ok ? Icons.login : Icons.gpp_bad_outlined, color: ok ? kSuccess : kError, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h.teacherName, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w700, color: kTextPri)),
                          Text('ID: ${h.teacherId}  •  ${h.deviceName}', style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
                          if (h.failReason.isNotEmpty)
                            Text('Reason: ${h.failReason}', style: const TextStyle(color: kError, fontFamily: 'Rajdhani', fontSize: 11)),
                          Text(h.loginTime, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 11)),
                        ])),
                        KBadge(label: h.status, color: ok ? kSuccess : kError),
                      ]),
                    ));
                  }),
      ),
    );
  }
}
