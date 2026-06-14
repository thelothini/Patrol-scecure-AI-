import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';
import 'view_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Teacher teacher;
  const AdminDashboardScreen({super.key, required this.teacher});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<AccessRequest>     _requests = [];
  List<PatrolReport>      _reports  = [];
  List<LoginHistoryItem>  _history  = [];
  bool _loadingReqs = true, _loadingRep = true, _loadingHist = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _fetchAll() { _fetchRequests(); _fetchReports(); _fetchHistory(); }

  // ── GET /admin/access_requests ───────────────────────────
  Future<void> _fetchRequests() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/admin/access_requests'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _requests = list.map((j) => AccessRequest.fromJson(j)).toList(); _loadingReqs = false; });
      } else { setState(() => _loadingReqs = false); }
    } catch (_) { setState(() => _loadingReqs = false); }
  }

  // ── GET /get_reports ─────────────────────────────────────
  Future<void> _fetchReports() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/get_reports'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _reports = list.map((j) => PatrolReport.fromJson(j)).toList(); _loadingRep = false; });
      } else { setState(() => _loadingRep = false); }
    } catch (_) { setState(() => _loadingRep = false); }
  }

  // ── GET /login_history ───────────────────────────────────
  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/login_history'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _history = list.map((j) => LoginHistoryItem.fromJson(j)).toList(); _loadingHist = false; });
      } else { setState(() => _loadingHist = false); }
    } catch (_) { setState(() => _loadingHist = false); }
  }

  // ── PUT /admin/access_requests/<id> ─────────────────────
  Future<void> _updateRequest(AccessRequest req, String action) async {
    try {
      final res = await http.put(
        Uri.parse('${Url.Urls}/admin/access_requests/${req.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': action}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => req.status = action);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Request $action'), backgroundColor: action == 'Approved' ? kSuccess : kError));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot connect to server.'), backgroundColor: kError));
    }
  }

  int get _pending => _requests.where((r) => r.status == 'Pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SafeArea(child: Column(children: [
          _header(context),
          _statsRow(),
          const SizedBox(height: 8),
          _tabBar(),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _accessTab(),
            _reportsTab(context),
            _historyTab(),
          ])),
        ])),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), child: Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
              borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: kGold.withOpacity(0.3), blurRadius: 12)]),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Admin Panel', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w800, color: kTextPri)),
        Text('PATROL SECURE ADMIN', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 10, color: kGold, letterSpacing: 2.5)),
      ])),
      GestureDetector(
        onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
        child: Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kError.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kError.withOpacity(0.3))),
            child: const Icon(Icons.logout, size: 18, color: kError)),
      ),
    ]));
  }

  Widget _statsRow() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
      _stat('Pending\nReqs', '$_pending', Icons.pending_actions, kWarning),
      const SizedBox(width: 10),
      _stat('Total\nReports', '${_reports.length}', Icons.assignment, kAccent),
      const SizedBox(width: 10),
      _stat('Failed\nLogins', '${_history.where((h) => h.status == 'Failed').length}', Icons.gpp_bad, kError),
      const SizedBox(width: 10),
      _stat('Open\nIssues', '${_reports.where((r) => r.status == 'Open').length}', Icons.error_outline, const Color(0xFFE67E22)),
    ]));
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(gradient: kCardGrad, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2), width: 0.7)),
        child: Column(children: [
          Icon(icon, size: 18, color: color), const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 10, color: kTextMut, height: 1.2)),
        ])));
  }

  Widget _tabBar() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: kInputFill, borderRadius: BorderRadius.circular(12)),
        child: TabBar(controller: _tabCtrl,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(10)),
            indicatorPadding: const EdgeInsets.all(3),
            labelColor: kPrimary, unselectedLabelColor: kTextMut,
            labelStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            tabs: [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('ACCESS'), const SizedBox(width: 4),
                if (_pending > 0) Container(width: 16, height: 16, decoration: const BoxDecoration(color: kError, shape: BoxShape.circle),
                    child: Center(child: Text('$_pending', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)))),
              ])),
              const Tab(text: 'REPORTS'),
              const Tab(text: 'LOGINS'),
            ]));
  }

  // ── ACCESS REQUESTS TAB ──────────────────────────────────
  Widget _accessTab() {
    if (_loadingReqs) return const Center(child: CircularProgressIndicator(color: kAccent));
    if (_requests.isEmpty) return const Center(child: Text('No access requests', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani')));
    return RefreshIndicator(onRefresh: _fetchRequests, color: kAccent, backgroundColor: kCardBg,
      child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _requests.length, itemBuilder: (ctx, i) {
        final req = _requests[i];
        final sc = req.status == 'Approved' ? kSuccess : req.status == 'Rejected' ? kError : kWarning;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: KCard(
          borderColor: req.status == 'Pending' ? kWarning.withOpacity(0.3) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_add_outlined, color: kWarning, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(req.email, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w700, color: kTextPri)),
                Text(req.deviceName, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
                Text(req.requestTime, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 11)),
              ])),
              KBadge(label: req.status, color: sc),
            ]),
            if (req.status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => _updateRequest(req, 'Rejected'),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: kError.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kError.withOpacity(0.3))),
                      child: const Center(child: Text('REJECT', style: TextStyle(color: kError, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)))))),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(onTap: () => _updateRequest(req, 'Approved'),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kSuccess.withOpacity(0.3))),
                      child: const Center(child: Text('APPROVE', style: TextStyle(color: kSuccess, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)))))),
              ]),
            ],
          ]),
        ));
      }),
    );
  }

  // ── ALL REPORTS TAB ──────────────────────────────────────
  Widget _reportsTab(BuildContext context) {
    if (_loadingRep) return const Center(child: CircularProgressIndicator(color: kAccent));
    return RefreshIndicator(onRefresh: _fetchReports, color: kAccent, backgroundColor: kCardBg,
      child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _reports.length, itemBuilder: (ctx, i) {
        final r = _reports[i];
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: KCard(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r))).then((_) => _fetchReports()),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.studentName, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w700, color: kTextPri)),
              Text('${r.registerNumber}  •  ${r.issueType}', style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
              Text('By: ${r.teacherName}  •  ${r.dateTime}', style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 11)),
            ])),
            KBadge(label: r.status, color: r.status == 'Open' ? kWarning : kSuccess),
          ]),
        ));
      }),
    );
  }

  // ── LOGIN HISTORY TAB ────────────────────────────────────
  Widget _historyTab() {
    if (_loadingHist) return const Center(child: CircularProgressIndicator(color: kAccent));
    return RefreshIndicator(onRefresh: _fetchHistory, color: kAccent, backgroundColor: kCardBg,
      child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _history.length, itemBuilder: (ctx, i) {
        final h = _history[i];
        final ok = h.status == 'Success';
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: KCard(
          borderColor: ok ? null : kError.withOpacity(0.4),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: ok ? kSuccess.withOpacity(0.1) : kError.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(ok ? Icons.login : Icons.gpp_bad, color: ok ? kSuccess : kError, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.teacherName, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w700, color: kTextPri)),
              Text('${h.teacherId}  •  ${h.deviceName}', style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
              if (h.failReason.isNotEmpty) Text('Reason: ${h.failReason}', style: const TextStyle(color: kError, fontFamily: 'Rajdhani', fontSize: 11)),
              Text(h.loginTime, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 11)),
            ])),
            KBadge(label: h.status, color: ok ? kSuccess : kError),
          ]),
        ));
      }),
    );
  }
}
