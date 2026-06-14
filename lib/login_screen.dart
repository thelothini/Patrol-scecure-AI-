import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:patrol_secure/screens/location_helper.dart';
import 'url.dart';

import 'signup_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

// ═══════════════════════════════════════════════════════════
//  SHARED COLORS  (public — importable everywhere)
// ═══════════════════════════════════════════════════════════
const kPrimary   = Color(0xFF0A1628);
const kCardBg    = Color(0xFF142035);
const kInputFill = Color(0xFF0D1E35);
const kDivider   = Color(0xFF1E3555);
const kAccent    = Color(0xFF00C2FF);
const kGold      = Color(0xFFFFB800);
const kSuccess   = Color(0xFF00E096);
const kError     = Color(0xFFFF4D6A);
const kWarning   = Color(0xFFFFB800);
const kTextPri   = Color(0xFFFFFFFF);
const kTextSec   = Color(0xFF8BA3C0);
const kTextMut   = Color(0xFF4A6080);

const kAccentGrad = LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF0070FF)]);
const kCardGrad   = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF142035), Color(0xFF0F2040)],
);

// ═══════════════════════════════════════════════════════════
//  SHARED DATA MODELS
// ═══════════════════════════════════════════════════════════
class Teacher {
  final int    id;
  final String name, teacherId, email, phone, department, deviceName, role;
  Teacher({required this.id, required this.name, required this.teacherId,
    required this.email, required this.phone, required this.department,
    required this.deviceName, required this.role});
  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
    id: j['id'] ?? 0,               name: j['name'] ?? '',
    teacherId: j['teacher_id'] ?? '', email: j['email'] ?? '',
    phone: j['phone'] ?? '',          department: j['department'] ?? '',
    deviceName: j['device_name'] ?? '', role: j['role'] ?? 'teacher',
  );
}

class PatrolReport {
  final int    id;
  final String studentName, registerNumber, department, yearSection,
      issueType, location, remarks, reportedBy, teacherName, dateTime;
  String status;
  PatrolReport({required this.id, required this.studentName, required this.registerNumber,
    required this.department, required this.yearSection, required this.issueType,
    required this.location, required this.remarks, required this.reportedBy,
    required this.teacherName, required this.dateTime, this.status = 'Open'});
  factory PatrolReport.fromJson(Map<String, dynamic> j) => PatrolReport(
    id: j['id'] ?? 0,                    studentName: j['student_name'] ?? '',
    registerNumber: j['register_number'] ?? '', department: j['department'] ?? '',
    yearSection: j['year_section'] ?? '',  issueType: j['issue_type'] ?? '',
    location: j['location'] ?? '',         remarks: j['remarks'] ?? '',
    reportedBy: j['reported_by'] ?? '',    teacherName: j['teacher_name'] ?? '',
    dateTime: j['date_time'] ?? '',        status: j['status'] ?? 'Open',
  );
}

class AccessRequest {
  final int    id;
  final String email, deviceName, requestTime;
  String status;
  AccessRequest({required this.id, required this.email, required this.deviceName,
    required this.requestTime, this.status = 'Pending'});
  factory AccessRequest.fromJson(Map<String, dynamic> j) => AccessRequest(
    id: j['id'] ?? 0,           email: j['email'] ?? '',
    deviceName: j['device_name'] ?? '', requestTime: j['request_time'] ?? '',
    status: j['status'] ?? 'Pending',
  );
}

class LoginHistoryItem {
  final int    id;
  final String teacherId, teacherName, email, deviceName, loginTime, status, failReason;
  LoginHistoryItem({required this.id, required this.teacherId, required this.teacherName,
    required this.email, required this.deviceName, required this.loginTime,
    required this.status, required this.failReason});
  factory LoginHistoryItem.fromJson(Map<String, dynamic> j) => LoginHistoryItem(
    id: j['id'] ?? 0,              teacherId: j['teacher_id'] ?? '',
    teacherName: j['teacher_name'] ?? '', email: j['email'] ?? '',
    deviceName: j['device_name'] ?? '',   loginTime: j['login_time'] ?? '',
    status: j['status'] ?? 'Success',     failReason: j['fail_reason'] ?? '',
  );
}

// ═══════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════
class KGradBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient? gradient;
  const KGradBtn({super.key, required this.label, this.onPressed,
    this.isLoading = false, this.icon, this.gradient});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? kAccentGrad,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: isLoading ? null : onPressed, borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (isLoading)
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kPrimary)))
              else ...[
                if (icon != null) ...[Icon(icon, color: kPrimary, size: 18), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16,
                    fontWeight: FontWeight.w700, color: kPrimary, letterSpacing: 1.5)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class KField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  const KField({super.key, required this.label, this.hint, this.prefixIcon,
    this.suffixIcon, this.obscureText = false, this.controller,
    this.keyboardType, this.validator, this.maxLines = 1,
    this.readOnly = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, obscureText: obscureText, keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines, readOnly: readOnly, onTap: onTap, validator: validator,
      style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 15),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani'),
        hintStyle: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani'),
        filled: true, fillColor: kInputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kError)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: kTextMut) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class KBadge extends StatelessWidget {
  final String label; final Color color;
  const KBadge({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontFamily: 'Rajdhani',
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

class KCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding;
  final VoidCallback? onTap; final Color? borderColor;
  const KCard({super.key, required this.child, this.padding, this.onTap, this.borderColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: kCardGrad, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? kDivider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
            child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child)),
      ),
    );
  }
}

class KSecHeader extends StatelessWidget {
  final String title; final String? actionLabel; final VoidCallback? onAction;
  const KSecHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(width: 3, height: 18,
            decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16,
            fontWeight: FontWeight.w700, color: kTextPri, letterSpacing: 1.0)),
      ]),
      if (actionLabel != null)
        GestureDetector(onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: kAccent,
                fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w600))),
    ]);
  }
}

class KInfoRow extends StatelessWidget {
  final String label; final String value; final IconData? icon;
  const KInfoRow({super.key, required this.label, required this.value, this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: kAccent), const SizedBox(width: 8)],
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: kTextMut,
            fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(color: kTextPri,
            fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

PreferredSizeWidget kAppBar(String title, BuildContext context, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent, elevation: 0,
    leading: Navigator.canPop(context) ? IconButton(
      icon: Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDivider, width: 0.5)),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kTextPri)),
      onPressed: () => Navigator.pop(context),
    ) : null,
    title: Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'Rajdhani',
        fontSize: 18, fontWeight: FontWeight.w700, color: kTextPri, letterSpacing: 2.0)),
    actions: actions,
    flexibleSpace: Container(decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2040), Colors.transparent]))),
  );
}

// ═══════════════════════════════════════════════════════════
//  LOGIN SCREEN
// ═══════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _devCtrl   = TextEditingController(text: 'Samsung Galaxy S23');
  bool _hidePass = true, _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  double? _lat;
  double? _lng;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationHelper.getCurrentLocation();
    if (mounted) {
      setState(() {
        _lat = pos?.latitude;
        _lng = pos?.longitude;
        _locationLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _devCtrl.dispose();
    super.dispose();
  }

  // ── POST /login ──────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Url.Urls}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email'      : _emailCtrl.text.trim(),
          'password'   : _passCtrl.text,
          'device_name': _devCtrl.text.trim(),
          'latitude'   : _lat,
          'longitude'  : _lng,
        }),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final teacher = Teacher.fromJson(body['teacher']);
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => teacher.role == 'admin'
              ? AdminDashboardScreen(teacher: teacher)
              : HomeScreen(teacher: teacher),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      } else if (res.statusCode == 403) {
        _showMismatchDialog(body['code'] ?? '', body['error'] ?? '');
      } else {
        _snack(body['error'] ?? 'Login failed', kError);
      }
    } catch (_) {
      setState(() => _loading = false);
      _snack('Cannot connect to server. Check your network.', kError);
    }
  }

  void _showMismatchDialog(String code, String message) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(code == 'DEVICE_MISMATCH' ? Icons.devices_other : Icons.location_off, color: kGold),
        const SizedBox(width: 10),
        Text(code == 'DEVICE_MISMATCH' ? 'Device Mismatch' : 'Location Mismatch',
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: kTextPri, fontSize: 18)),
      ]),
      content: Text(message, style: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kTextMut, fontFamily: 'Rajdhani'))),
        GestureDetector(onTap: () { Navigator.pop(context); _requestAccess(); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(8)),
              child: const Text('Request Access', style: TextStyle(fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700, color: kPrimary, fontSize: 14))),
        ),
      ],
    ));
  }

  // ── POST /request_access ─────────────────────────────────
  Future<void> _requestAccess() async {
    try {
      final res = await http.post(
        Uri.parse('${Url.Urls}/request_access'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email'      : _emailCtrl.text.trim(),
          'device_name': _devCtrl.text.trim(),
          'latitude'   : _lat,
          'longitude'  : _lng,
        }),
      );
      final body = jsonDecode(res.body);
      _snack(res.statusCode == 201
          ? 'Access request submitted! Admin will review shortly.'
          : body['error'] ?? 'Failed',
          res.statusCode == 201 ? kSuccess : kError);
    } catch (_) {
      _snack('Cannot connect to server.', kError);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color.withOpacity(0.9)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: SafeArea(child: FadeTransition(opacity: _fadeAnim,
          child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 48),
              // Logo row
              Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 12)]),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PatrolSecure', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w800, color: kTextPri)),
                  Text('TEACHER PORTAL', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, color: kAccent, letterSpacing: 3, fontWeight: FontWeight.w600)),
                ]),
              ]),
              const SizedBox(height: 48),
              const Text('Welcome\nBack', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 42,
                  fontWeight: FontWeight.w900, color: kTextPri, height: 1.1, letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text('Sign in to continue patrol operations',
                  style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani', fontSize: 15)),
              const SizedBox(height: 28),
              // GPS chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _locationLoading
                      ? kTextMut.withOpacity(0.08)
                      : _lat != null
                      ? kSuccess.withOpacity(0.08)
                      : kError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _locationLoading
                        ? kTextMut.withOpacity(0.25)
                        : _lat != null
                        ? kSuccess.withOpacity(0.25)
                        : kError.withOpacity(0.25),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_locationLoading)
                    const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kTextMut))
                  else
                    Container(width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: _lat != null ? kSuccess : kError, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    _locationLoading
                        ? 'Fetching location...'
                        : _lat != null
                        ? 'Location: ${_lat!.toStringAsFixed(4)}° N, ${_lng!.toStringAsFixed(4)}° E'
                        : 'Location unavailable — enable GPS',
                    style: TextStyle(
                      color: _locationLoading ? kTextMut : _lat != null ? kSuccess : kError,
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              Form(key: _formKey, child: Column(children: [
                KField(label: 'Email Address', hint: 'teacher@college.edu',
                    prefixIcon: Icons.alternate_email, controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Email required' : null),
                const SizedBox(height: 16),
                KField(label: 'Password', hint: '••••••••', prefixIcon: Icons.lock_outline,
                    controller: _passCtrl, obscureText: _hidePass,
                    suffixIcon: IconButton(
                        icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility, size: 20, color: kTextMut),
                        onPressed: () => setState(() => _hidePass = !_hidePass)),
                    validator: (v) => v == null || v.isEmpty ? 'Password required' : null),
                const SizedBox(height: 16),
                KField(label: 'Device Name', hint: 'Auto-detected device name',
                    prefixIcon: Icons.smartphone, controller: _devCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Device name required' : null),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity,
                    child: KGradBtn(label: 'SIGN IN', onPressed: _login, isLoading: _loading, icon: Icons.login)),
              ])),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani')),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Register Now', style: TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        )),
      ),
    );
  }
}