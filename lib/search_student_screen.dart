import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';
import 'student_history_screen.dart';

class SearchStudentScreen extends StatefulWidget {
  const SearchStudentScreen({super.key});
  @override
  State<SearchStudentScreen> createState() => _SearchStudentScreenState();
}

class _SearchStudentScreenState extends State<SearchStudentScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false, _searched = false;
  Map<String, dynamic>? _student;
  List<PatrolReport> _reports = [];
  String _errorMsg = '';

  // ── GET /search_student/<reg_no> ─────────────────────────
  Future<void> _search() async {
    final q = _ctrl.text.trim().toUpperCase();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a register number'), backgroundColor: kWarning),
      );
      return;
    }

    // Close keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading  = true;
      _searched = false;
      _student  = null;
      _reports  = [];
      _errorMsg = '';
    });

    try {
      final url = '${Url.Urls}/search_student/$q';
      print('Searching: $url'); // debug

      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Status: ${res.statusCode}'); // debug
      print('Body: ${res.body}');         // debug

      setState(() {
        _loading  = false;
        _searched = true;
      });

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _student = body['student'];
          _reports = (body['reports'] as List)
              .map((j) => PatrolReport.fromJson(j))
              .toList();
        });
      } else if (res.statusCode == 404) {
        setState(() => _errorMsg = 'No student found with register number "$q"');
      } else {
        final body = jsonDecode(res.body);
        setState(() => _errorMsg = body['error'] ?? 'Search failed');
      }
    } catch (e) {
      print('Search error: $e'); // debug
      setState(() {
        _loading  = false;
        _searched = true;
        _errorMsg = 'Cannot connect to server. Check your network.';
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kAppBar('Search Student', context),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // ── Search bar ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: kInputFill, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kDivider)),
              child: Row(children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: kTextMut, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 15),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter Register Number (e.g. 22CS001)',
                      hintStyle: TextStyle(color: kTextMut, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => _search(), // keyboard search button
                  ),
                ),
                // ── SEARCH BUTTON ────────────────────────────
                GestureDetector(
                  onTap: _search, // tap search button
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(10)),
                    child: _loading
                        ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                        : const Text('SEARCH', style: TextStyle(fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700, color: kPrimary, fontSize: 13, letterSpacing: 1)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Results ─────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: kAccent),
              )
            else if (!_searched)
              _placeholder()
            else if (_errorMsg.isNotEmpty)
                _notFound(_errorMsg)
              else if (_student != null)
                  _result(context),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Column(children: [
      const SizedBox(height: 50),
      const Icon(Icons.manage_search, size: 64, color: kTextMut),
      const SizedBox(height: 14),
      const Text('Search by Register Number',
          style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Enter the student\'s register number above',
          style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 13)),
      const SizedBox(height: 24),
      // Quick search chips
      Wrap(spacing: 8, runSpacing: 8, children: ['22CS001','22EC045','21ME023','23IT012'].map((k) =>
          GestureDetector(
            onTap: () { _ctrl.text = k; _search(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kAccent.withOpacity(0.3))),
              child: Text(k, style: const TextStyle(color: kAccent, fontFamily: 'Rajdhani',
                  fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
      ).toList()),
    ]);
  }

  Widget _notFound(String msg) {
    return Column(children: [
      const SizedBox(height: 60),
      Container(width: 80, height: 80,
          decoration: BoxDecoration(color: kError.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.person_search, size: 40, color: kError)),
      const SizedBox(height: 20),
      const Text('Student Not Found', style: TextStyle(fontFamily: 'Rajdhani',
          fontSize: 22, fontWeight: FontWeight.w700, color: kTextPri)),
      const SizedBox(height: 8),
      Text(msg, textAlign: TextAlign.center,
          style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 14)),
    ]);
  }

  Widget _result(BuildContext context) {
    final s = _student!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Student card ──────────────────────────────────────
      KCard(borderColor: kAccent.withOpacity(0.3), child: Column(children: [
        Row(children: [
          Container(width: 56, height: 56,
              decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(
                (s['name'] as String).isNotEmpty ? (s['name'] as String).substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 24, fontWeight: FontWeight.w800, color: kPrimary),
              ))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['name'] ?? '', style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
                fontWeight: FontWeight.w700, color: kTextPri)),
            Text(s['register_number'] ?? '', style: const TextStyle(color: kAccent,
                fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _reports.isEmpty ? kSuccess.withOpacity(0.1) : kWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _reports.isEmpty ? kSuccess.withOpacity(0.3) : kWarning.withOpacity(0.3)),
            ),
            child: Text('${_reports.length} Reports', style: TextStyle(fontFamily: 'Rajdhani',
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _reports.isEmpty ? kSuccess : kWarning)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: kDivider),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _chip(Icons.school_outlined, s['department'] ?? '-')),
          Expanded(child: _chip(Icons.class_outlined, 'Yr ${s['year'] ?? '-'} - ${s['section'] ?? '-'}')),
          Expanded(child: _chip(Icons.phone_outlined, s['phone'] ?? '-')),
        ]),
      ])),
      const SizedBox(height: 20),

      // ── Reports ───────────────────────────────────────────
      if (_reports.isNotEmpty) ...[
        KSecHeader(
          title: 'PATROL HISTORY',
          actionLabel: 'Full History',
          onAction: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StudentHistoryScreen(registerNumber: s['register_number'] ?? ''))),
        ),
        const SizedBox(height: 14),
        ..._reports.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: KCard(child: Row(children: [
            Container(width: 10, height: 48, decoration: BoxDecoration(
                color: r.status == 'Open' ? kWarning : kSuccess,
                borderRadius: BorderRadius.circular(5))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.issueType, style: const TextStyle(fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700, fontSize: 14, color: kTextPri)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: kTextMut),
                const SizedBox(width: 3),
                Flexible(child: Text(r.location, style: const TextStyle(color: kTextMut,
                    fontFamily: 'Rajdhani', fontSize: 12))),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 12, color: kTextMut),
                const SizedBox(width: 3),
                Text(r.dateTime, style: const TextStyle(color: kTextMut,
                    fontFamily: 'Rajdhani', fontSize: 12)),
              ]),
            ])),
            KBadge(label: r.status, color: r.status == 'Open' ? kWarning : kSuccess),
          ])),
        )),
      ] else
        KCard(child: Row(children: [
          const Icon(Icons.verified_user, color: kSuccess, size: 28),
          const SizedBox(width: 14),
          const Expanded(child: Text('No patrol reports for this student.',
              style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 14))),
        ])),
    ]);
  }

  Widget _chip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: kTextMut),
      const SizedBox(width: 5),
      Flexible(child: Text(text, style: const TextStyle(color: kTextSec,
          fontFamily: 'Rajdhani', fontSize: 12), overflow: TextOverflow.ellipsis)),
    ]);
  }
} 