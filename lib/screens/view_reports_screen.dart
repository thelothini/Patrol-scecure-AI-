import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_screen.dart';
import '../url.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});
  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<PatrolReport> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _fetch();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── GET /get_reports ─────────────────────────────────────
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${Url.Urls}/get_reports'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _all = list.map((j) => PatrolReport.fromJson(j)).toList(); _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (_) { setState(() => _loading = false); }
  }

  List<PatrolReport> get _filtered {
    if (_tabCtrl.index == 1) return _all.where((r) => r.status == 'Open').toList();
    if (_tabCtrl.index == 2) return _all.where((r) => r.status == 'Resolved').toList();
    return _all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: const Size.fromHeight(110),
        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2040), Colors.transparent])),
          child: SafeArea(child: Column(children: [
            kAppBar('View Reports', context),
            TabBar(controller: _tabCtrl, indicatorColor: kAccent, indicatorWeight: 2,
                labelColor: kAccent, unselectedLabelColor: kTextMut,
                labelStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
                tabs: const [Tab(text: 'ALL'), Tab(text: 'OPEN'), Tab(text: 'RESOLVED')]),
          ])),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccent))
            : _filtered.isEmpty
            ? const Center(child: Text('No reports found', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 15)))
            : RefreshIndicator(onRefresh: _fetch, color: kAccent, backgroundColor: kCardBg,
          child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (ctx, i) {
            final r = _filtered[i];
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: KCard(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r))).then((_) => _fetch()),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _issueIcon(r.issueType), const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.studentName, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w700, color: kTextPri)),
                    Text(r.registerNumber, style: const TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w600)),
                  ])),
                  KBadge(label: r.status, color: r.status == 'Open' ? kWarning : kSuccess),
                ]),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: kInputFill, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_outlined, size: 14, color: kWarning), const SizedBox(width: 6),
                      Text(r.issueType, style: const TextStyle(color: kWarning, fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: kTextMut), const SizedBox(width: 4),
                  Text(r.location, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 13, color: kTextMut), const SizedBox(width: 4),
                  Text(r.dateTime, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
                ]),
              ]),
            ));
          }),
        ),
      ),
    );
  }

  Widget _issueIcon(String t) {
    final m = {'ID Card Missing':[Icons.badge_outlined,kWarning],'Mobile Usage':[Icons.smartphone,kError],'Late Coming':[Icons.access_time,kAccent],'Uniform Issue':[Icons.checkroom,const Color(0xFF9B59B6)]};
    final e = m[t] ?? [Icons.report_problem, kTextMut];
    final c = e[1] as Color;
    return Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(e[0] as IconData, color: c, size: 20));
  }
}

// ─────────────────────────────────────────────
//  REPORT DETAILS SCREEN
// ─────────────────────────────────────────────
class ReportDetailsScreen extends StatefulWidget {
  final PatrolReport report;
  const ReportDetailsScreen({super.key, required this.report});
  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late String _status;
  bool _updating = false;

  @override
  void initState() { super.initState(); _status = widget.report.status; }

  // ── PUT /update_report_status/<id> ───────────────────────
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      final res = await http.put(
        Uri.parse('${Url.Urls}/update_report_status/${widget.report.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      if (!mounted) return;
      setState(() { _updating = false; });
      if (res.statusCode == 200) {
        setState(() { _status = newStatus; widget.report.status = newStatus; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: newStatus == 'Resolved' ? kSuccess : kWarning));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update'), backgroundColor: kError));
      }
    } catch (_) {
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot connect to server.'), backgroundColor: kError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: kAppBar('Report Details', context, actions: [
        Padding(padding: const EdgeInsets.only(right: 16),
            child: KBadge(label: _status, color: _status == 'Open' ? kWarning : kSuccess)),
      ]),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [kWarning.withOpacity(0.2), kWarning.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: kWarning.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.report_problem, color: kWarning, size: 36), const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.issueType, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w800, color: kWarning)),
                  Text('Reported on ${r.dateTime}', style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 13)),
                ])),
              ])),
          const SizedBox(height: 20),
          KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KSecHeader(title: 'STUDENT DETAILS'), const SizedBox(height: 14),
            KInfoRow(label: 'Name', value: r.studentName, icon: Icons.person_outline),
            KInfoRow(label: 'Register No.', value: r.registerNumber, icon: Icons.numbers),
            KInfoRow(label: 'Department', value: r.department, icon: Icons.school_outlined),
            KInfoRow(label: 'Year / Section', value: r.yearSection, icon: Icons.class_outlined),
          ])),
          const SizedBox(height: 14),
          KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KSecHeader(title: 'INCIDENT DETAILS'), const SizedBox(height: 14),
            KInfoRow(label: 'Location', value: r.location, icon: Icons.location_on_outlined),
            KInfoRow(label: 'Date & Time', value: r.dateTime, icon: Icons.access_time),
            KInfoRow(label: 'Reported By', value: r.teacherName, icon: Icons.person_pin_outlined),
            const Divider(color: kDivider), const SizedBox(height: 8),
            const Text('Remarks', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(r.remarks, style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 14)),
          ])),
          const SizedBox(height: 20),
          const KSecHeader(title: 'UPDATE STATUS'), const SizedBox(height: 14),
          _updating
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : Row(children: [
            Expanded(child: _statusBtn('Open', kWarning)),
            const SizedBox(width: 12),
            Expanded(child: _statusBtn('Resolved', kSuccess)),
            const SizedBox(width: 12),
            Expanded(child: _statusBtn('Pending', kAccent)),
          ]),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _statusBtn(String label, Color color) {
    final sel = _status == label;
    return GestureDetector(onTap: () => _updateStatus(label),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: sel ? color.withOpacity(0.2) : kInputFill,
            borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? color : kDivider, width: sel ? 1.5 : 0.5)),
        child: Center(child: Text(label, style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700,
            fontSize: 13, color: sel ? color : kTextMut, letterSpacing: 0.5))),
      ),
    );
  }
}