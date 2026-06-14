import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'url.dart';
import 'login_screen.dart';

class AddPatrolReportScreen extends StatefulWidget {
  final Teacher teacher;
  const AddPatrolReportScreen({super.key, required this.teacher});
  @override
  State<AddPatrolReportScreen> createState() => _AddPatrolReportScreenState();
}

class _AddPatrolReportScreenState extends State<AddPatrolReportScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _regCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _remarksCtrl  = TextEditingController();
  String? _dept, _yearSec, _issueType;
  bool _loading = false;
  DateTime _dt = DateTime.now();

  final _depts    = ['CSE','ECE','EEE','MECH','CIVIL','IT','AIDS','AIML'];
  final _yearSecs = ['I - A','I - B','II - A','II - B','III - A','III - B','IV - A','IV - B'];
  final _issues   = [
    {'label':'ID Card Missing', 'icon':Icons.badge_outlined,    'color':const Color(0xFFFFB800)},
    {'label':'Uniform Issue',   'icon':Icons.checkroom,         'color':const Color(0xFF9B59B6)},
    {'label':'Late Coming',     'icon':Icons.access_time,       'color':const Color(0xFF00C2FF)},
    {'label':'Mobile Usage',    'icon':Icons.smartphone,        'color':const Color(0xFFFF4D6A)},
    {'label':'Misconduct',      'icon':Icons.warning_amber,     'color':const Color(0xFFE67E22)},
    {'label':'Restricted Area', 'icon':Icons.location_off,      'color':const Color(0xFF8E44AD)},
    {'label':'Other',           'icon':Icons.more_horiz,        'color':const Color(0xFF4A6080)},
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _regCtrl.dispose(); _locationCtrl.dispose(); _remarksCtrl.dispose(); super.dispose(); }

  // ── POST /add_report ─────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dept == null || _yearSec == null || _issueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields'), backgroundColor: kWarning)); return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Url.Urls}/add_report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_name'   : _nameCtrl.text.trim(),
          'register_number': _regCtrl.text.trim().toUpperCase(),
          'department'     : _dept,
          'year_section'   : _yearSec,
          'issue_type'     : _issueType,
          'location'       : _locationCtrl.text.trim(),
          'remarks'        : _remarksCtrl.text.trim(),
          'reported_by'    : widget.teacher.teacherId,
          'teacher_name'   : widget.teacher.name,
        }),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (res.statusCode == 201) {
        _showSuccess();
      } else {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(body['error'] ?? 'Failed to submit'), backgroundColor: kError));
      }
    } catch (_) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot connect to server.'), backgroundColor: kError));
    }
  }

  void _showSuccess() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: kCardBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: kSuccess, size: 36)),
        const SizedBox(height: 20),
        const Text('Report Submitted!', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w800, color: kTextPri)),
        const SizedBox(height: 8),
        const Text('Patrol report has been recorded successfully.', textAlign: TextAlign.center,
            style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 14)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: KGradBtn(label: 'DONE',
            onPressed: () { Navigator.pop(context); Navigator.pop(context); })),
      ]),
    ));
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(context: context, initialDate: _dt,
        firstDate: DateTime(2020), lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: kAccent, surface: kCardBg),
            dialogBackgroundColor: kCardBg), child: child!));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt),
        builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: kAccent, surface: kCardBg),
            dialogBackgroundColor: kCardBg), child: child!));
    if (t == null) return;
    setState(() => _dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kAppBar('Add Patrol Report', context),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: Form(key: _formKey, child: SingleChildScrollView(padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KSecHeader(title: 'SELECT ISSUE TYPE'),
            const SizedBox(height: 14),
            _issueGrid(),
            const SizedBox(height: 24),
            const KSecHeader(title: 'STUDENT INFORMATION'),
            const SizedBox(height: 14),
            KField(label: 'Student Name', prefixIcon: Icons.person_outline, controller: _nameCtrl,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            KField(label: 'Register Number', hint: '22CS001', prefixIcon: Icons.numbers,
                controller: _regCtrl, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _dropdown('Department', _depts, _dept, Icons.school_outlined, (v) => setState(() => _dept = v)),
            const SizedBox(height: 14),
            _dropdown('Year / Section', _yearSecs, _yearSec, Icons.class_outlined, (v) => setState(() => _yearSec = v)),
            const SizedBox(height: 24),
            const KSecHeader(title: 'INCIDENT DETAILS'),
            const SizedBox(height: 14),
            KField(label: 'Location', hint: 'Block A - Corridor', prefixIcon: Icons.location_on_outlined,
                controller: _locationCtrl, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            GestureDetector(onTap: _pickDateTime,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: kInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: kDivider)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: kTextMut), const SizedBox(width: 12),
                  Expanded(child: Text(
                      '${_dt.day}/${_dt.month}/${_dt.year}  ${_dt.hour.toString().padLeft(2,'0')}:${_dt.minute.toString().padLeft(2,'0')}',
                      style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 15))),
                  const Icon(Icons.edit_outlined, size: 16, color: kTextMut),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            KField(label: 'Remarks', hint: 'Describe the incident in detail...',
                prefixIcon: Icons.notes, controller: _remarksCtrl, maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: KGradBtn(label: 'SUBMIT REPORT', onPressed: _submit, isLoading: _loading, icon: Icons.send)),
            const SizedBox(height: 20),
          ]),
        )),
      ),
    );
  }

  Widget _issueGrid() {
    return GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1,
        children: _issues.map((iss) {
          final sel = _issueType == iss['label'];
          final c   = iss['color'] as Color;
          return GestureDetector(onTap: () => setState(() => _issueType = iss['label'] as String),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: sel ? c.withOpacity(0.2) : kInputFill,
                  borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? c : kDivider, width: sel ? 1.5 : 0.5)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(iss['icon'] as IconData, color: sel ? c : kTextMut, size: 24),
                const SizedBox(height: 6),
                Text(iss['label'] as String, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11,
                        color: sel ? c : kTextMut, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ]),
            ),
          );
        }).toList());
  }

  Widget _dropdown(String label, List<String> items, String? value, IconData icon, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value, dropdownColor: kCardBg,
      style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 15),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: kTextMut),
          filled: true, fillColor: kInputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
          labelStyle: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }
}
