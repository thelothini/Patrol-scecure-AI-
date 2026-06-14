import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';

class StudentHistoryScreen extends StatefulWidget {
  final String registerNumber;
  const StudentHistoryScreen({super.key, required this.registerNumber});
  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  List<PatrolReport> _reports = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  // ── GET /student_history/<reg_no> or /get_reports ────────
  Future<void> _fetch() async {
    try {
      final url = widget.registerNumber.isEmpty
          ? '${Url.Urls}/get_reports'
          : '${Url.Urls}/student_history/${widget.registerNumber.toUpperCase()}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _reports = list.map((j) => PatrolReport.fromJson(j)).toList(); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final name = _reports.isNotEmpty ? _reports.first.studentName : 'Student';
    final dept = _reports.isNotEmpty ? _reports.first.department   : '-';
    final regNo = widget.registerNumber.isEmpty ? 'All Students' : widget.registerNumber.toUpperCase();

    return Scaffold(
      appBar: kAppBar('Student History', context),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccent))
            : _reports.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history, size: 64, color: kTextMut), SizedBox(height: 16),
                    Text('No History Found', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, color: kTextPri, fontWeight: FontWeight.w700)),
                  ]))
                : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _header(name, regNo, dept, _reports.length),
                    const SizedBox(height: 24),
                    _breakdown(),
                    const SizedBox(height: 24),
                    const KSecHeader(title: 'INCIDENT TIMELINE'),
                    const SizedBox(height: 14),
                    _timeline(),
                  ])),
      ),
    );
  }

  Widget _header(String name, String regNo, String dept, int total) {
    return KCard(borderColor: kAccent.withOpacity(0.3), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(name.substring(0,1), style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 26, fontWeight: FontWeight.w800, color: kPrimary)))),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w700, color: kTextPri)),
          Text(regNo, style: const TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600)),
          Text(dept, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 13)),
        ]),
      ]),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: total >= 3 ? kError.withOpacity(0.08) : kWarning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: total >= 3 ? kError.withOpacity(0.2) : kWarning.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(total >= 3 ? Icons.warning : Icons.info_outline, size: 18, color: total >= 3 ? kError : kWarning),
          const SizedBox(width: 10),
          Text('Total $total patrol report${total != 1 ? 's' : ''} on record',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600, color: total >= 3 ? kError : kWarning)),
        ]),
      ),
    ]));
  }

  Widget _breakdown() {
    final counts = <String, int>{};
    for (final r in _reports) counts[r.issueType] = (counts[r.issueType] ?? 0) + 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const KSecHeader(title: 'ISSUE BREAKDOWN'), const SizedBox(height: 14),
      ...counts.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e.key, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 13, color: kTextSec)),
          Text('${e.value}x', style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 13, color: kAccent, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
            value: e.value / _reports.length, backgroundColor: kDivider,
            valueColor: const AlwaysStoppedAnimation<Color>(kAccent), minHeight: 6)),
      ]))),
    ]);
  }

  Widget _timeline() {
    return Column(children: List.generate(_reports.length, (i) {
      final r = _reports[i];
      final isLast = i == _reports.length - 1;
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 32, child: Column(children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(
              color: r.status == 'Open' ? kWarning : kSuccess, shape: BoxShape.circle,
              border: Border.all(color: kPrimary, width: 2))),
          if (!isLast) Expanded(child: Container(width: 2, color: kDivider, margin: const EdgeInsets.symmetric(vertical: 2))),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: KCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(r.issueType, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w700, color: kTextPri)),
            KBadge(label: r.status, color: r.status == 'Open' ? kWarning : kSuccess),
          ]),
          if (r.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.remarks, style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 12, color: kTextMut), const SizedBox(width: 4),
            Text(r.teacherName, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
            const SizedBox(width: 10),
            const Icon(Icons.access_time, size: 12, color: kTextMut), const SizedBox(width: 4),
            Text(r.dateTime, style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 12)),
          ]),
        ])))),
      ]));
    }));
  }
}
