import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';
import 'add_patrol_report_screen.dart';
import 'search_student_screen.dart';
import 'view_reports_screen.dart';
import 'student_history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Teacher teacher;
  const HomeScreen({super.key, required this.teacher});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PatrolReport> _reports = [];
  bool _loadingReports = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // ── GET /get_reports ─────────────────────────────────────
  Future<void> _fetchReports() async {
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/get_reports'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _reports = list.map((j) => PatrolReport.fromJson(j)).toList(); _loadingReports = false; });
      }
    } catch (_) {
      setState(() => _loadingReports = false);
    }
  }

  int get _open     => _reports.where((r) => r.status == 'Open').length;
  int get _resolved => _reports.where((r) => r.status == 'Resolved').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SafeArea(child: RefreshIndicator(
          onRefresh: _fetchReports, color: kAccent, backgroundColor: kCardBg,
          child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _topBar(context),
              _greeting(),
              _statsRow(),
              const SizedBox(height: 28),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const KSecHeader(title: 'QUICK ACTIONS')),
              const SizedBox(height: 16),
              _actionGrid(context),
              const SizedBox(height: 28),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KSecHeader(title: 'RECENT REPORTS', actionLabel: 'View All',
                    onAction: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ViewReportsScreen())).then((_) => _fetchReports())),
              ),
              const SizedBox(height: 14),
              _recentReports(context),
              const SizedBox(height: 24),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 10),
        const Text('PatrolSecure', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w800, color: kTextPri)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider, width: 0.5)),
              child: const Icon(Icons.notifications_outlined, size: 20, color: kTextPri)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(teacher: widget.teacher))).then((_) => _fetchReports()),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(widget.teacher.name.substring(0, 1),
                  style: const TextStyle(fontFamily: 'Rajdhani', color: kPrimary, fontWeight: FontWeight.w800, fontSize: 18)))),
        ),
      ]),
    );
  }

  Widget _greeting() {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';
    return Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$g,', style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 15)),
        const SizedBox(height: 2),
        Text(widget.teacher.name, style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.school, size: 13, color: kTextMut), const SizedBox(width: 5),
          Text('${widget.teacher.department} Department', style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 13)),
        ]),
      ]),
    );
  }

  Widget _statsRow() {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(children: [
        Expanded(child: _statCard('Total', '${_reports.length}', Icons.assignment, kAccent)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Open', '$_open', Icons.error_outline, kWarning)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Resolved', '$_resolved', Icons.check_circle_outline, kSuccess)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(gradient: kCardGrad, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.7)),
      child: _loadingReports
          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kAccent)))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 11, color: kTextMut)),
            ]),
    );
  }

  Widget _actionGrid(BuildContext context) {
    final items = [
      ['Add Patrol\nReport', Icons.add_circle_outline, kAccent,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPatrolReportScreen(teacher: widget.teacher))).then((_) => _fetchReports())],
      ['Search\nStudent', Icons.search, kGold,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchStudentScreen()))],
      ['View\nReports', Icons.list_alt, const Color(0xFF9B59B6),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewReportsScreen())).then((_) => _fetchReports())],
      ['Student\nHistory', Icons.history, const Color(0xFF27AE60),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentHistoryScreen(registerNumber: '')))],
      ['Notifications', Icons.notifications_outlined, const Color(0xFFE74C3C),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))],
      ['Profile', Icons.person_outline, const Color(0xFF3498DB),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(teacher: widget.teacher))).then((_) => _fetchReports())],
      ['Login\nHistory', Icons.history_toggle_off, const Color(0xFF1ABC9C),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryScreen()))],
      ['Logout', Icons.logout, kError, _logout],
    ];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85,
          children: items.map((a) => GestureDetector(onTap: a[3] as VoidCallback,
            child: Container(
              decoration: BoxDecoration(gradient: kCardGrad, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (a[2] as Color).withOpacity(0.2), width: 0.7)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: (a[2] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(a[1] as IconData, color: a[2] as Color, size: 20)),
                const SizedBox(height: 8),
                Text(a[0] as String, textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 11, color: kTextSec, height: 1.2, fontWeight: FontWeight.w600)),
              ]),
            ),
          )).toList()),
    );
  }

  Widget _recentReports(BuildContext context) {
    if (_loadingReports) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: kAccent)));
    if (_reports.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: KCard(child: const Center(child: Text('No reports yet', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani')))));
    return Column(children: _reports.take(3).map((r) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: KCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r))).then((_) => _fetchReports()),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: _issueColor(r.issueType).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(_issueIcon(r.issueType), color: _issueColor(r.issueType), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.studentName, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: kTextPri)),
            const SizedBox(height: 2),
            Text(r.issueType, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 12, color: kTextMut)),
          ])),
          KBadge(label: r.status, color: r.status == 'Open' ? kWarning : kSuccess),
        ]),
      ),
    )).toList());
  }

  Color _issueColor(String t) => {'ID Card Missing': kWarning, 'Mobile Usage': kError, 'Late Coming': kAccent}[t] ?? kTextSec;
  IconData _issueIcon(String t) => {'ID Card Missing': Icons.badge_outlined, 'Mobile Usage': Icons.smartphone, 'Late Coming': Icons.access_time}[t] ?? Icons.warning_amber;

  void _logout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kCardBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: kTextPri)),
      content: const Text('Are you sure you want to logout?', style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani'))),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false); },
            child: const Text('Logout', style: TextStyle(color: kError, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700))),
      ],
    ));
  }
}
