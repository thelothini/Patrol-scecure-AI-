import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:patrol_secure/screens/location_helper.dart';
import 'url.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _idCtrl      = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _devCtrl     = TextEditingController(text: 'Samsung Galaxy S23');
  String? _dept;
  bool _hidePass = true, _hideConfirm = true, _loading = false;

  double? _lat;
  double? _lng;
  bool _locationLoading = true;

  final List<String> _depts = ['CSE','ECE','EEE','MECH','CIVIL','IT','AIDS','AIML','MBA','MCA'];

  @override
  void initState() {
    super.initState();
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
    _nameCtrl.dispose(); _idCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose(); _devCtrl.dispose();
    super.dispose();
  }

  // ── POST /signup ─────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dept == null) {
      _snack('Please select a department', kWarning); return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Url.Urls}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name'            : _nameCtrl.text.trim(),
          'teacher_id'      : _idCtrl.text.trim(),
          'email'           : _emailCtrl.text.trim(),
          'phone'           : _phoneCtrl.text.trim(),
          'department'      : _dept,
          'password'        : _passCtrl.text,
          'confirm_password': _confirmCtrl.text,
          'device_name'     : _devCtrl.text.trim(),
          'latitude'        : _lat,   // saved to DB at signup
          'longitude'       : _lng,   // saved to DB at signup
        }),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        _snack('Registration successful! Please log in.', kSuccess);
        Navigator.pop(context);
      } else {
        _snack(body['error'] ?? 'Registration failed', kError);
      }
    } catch (_) {
      setState(() => _loading = false);
      _snack('Cannot connect to server. Check your network.', kError);
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
        child: SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kDivider, width: 0.5)),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kTextPri))),
              const SizedBox(width: 16),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('New Registration', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w800, color: kTextPri)),
                Text('TEACHER ACCOUNT', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 10, color: kAccent, letterSpacing: 2.5)),
              ]),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),
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
                        ? 'Registering from: ${_lat!.toStringAsFixed(4)}° N, ${_lng!.toStringAsFixed(4)}° E'
                        : 'Location unavailable — enable GPS',
                    style: TextStyle(
                      color: _locationLoading ? kTextMut : _lat != null ? kSuccess : kError,
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _sectionLabel('PERSONAL INFORMATION'),
              const SizedBox(height: 14),
              KField(label: 'Full Name', hint: 'Dr. First Last', prefixIcon: Icons.person_outline,
                  controller: _nameCtrl, validator: (v) => v == null || v.isEmpty ? 'Name required' : null),
              const SizedBox(height: 14),
              KField(label: 'Teacher ID', hint: 'T001', prefixIcon: Icons.badge_outlined,
                  controller: _idCtrl, validator: (v) => v == null || v.isEmpty ? 'Teacher ID required' : null),
              const SizedBox(height: 14),
              KField(label: 'Email Address', hint: 'teacher@college.edu', prefixIcon: Icons.alternate_email,
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  validator: (v) { if (v == null || v.isEmpty) return 'Email required'; if (!v.contains('@')) return 'Enter valid email'; return null; }),
              const SizedBox(height: 14),
              KField(label: 'Phone Number', hint: '98765 43210', prefixIcon: Icons.phone_outlined,
                  controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  validator: (v) { if (v == null || v.isEmpty) return 'Phone required'; if (v.length < 10) return 'Enter valid phone number'; return null; }),
              const SizedBox(height: 14),
              _deptDropdown(),
              const SizedBox(height: 14),
              KField(label: 'Device Name', hint: 'Your device name', prefixIcon: Icons.smartphone,
                  controller: _devCtrl, validator: (v) => v == null || v.isEmpty ? 'Device name required' : null),
              const SizedBox(height: 24),
              _sectionLabel('SECURITY'),
              const SizedBox(height: 14),
              KField(label: 'Password', hint: 'Min. 6 characters', prefixIcon: Icons.lock_outline,
                  controller: _passCtrl, obscureText: _hidePass,
                  suffixIcon: IconButton(icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility, size: 20, color: kTextMut),
                      onPressed: () => setState(() => _hidePass = !_hidePass)),
                  validator: (v) { if (v == null || v.isEmpty) return 'Password required'; if (v.length < 6) return 'Minimum 6 characters'; return null; }),
              const SizedBox(height: 14),
              KField(label: 'Confirm Password', hint: 'Re-enter password', prefixIcon: Icons.lock_outline,
                  controller: _confirmCtrl, obscureText: _hideConfirm,
                  suffixIcon: IconButton(icon: Icon(_hideConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: kTextMut),
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm)),
                  validator: (v) { if (v == null || v.isEmpty) return 'Confirm password required'; if (v != _passCtrl.text) return 'Passwords do not match'; return null; }),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity,
                  child: KGradBtn(label: 'CREATE ACCOUNT', onPressed: _register, isLoading: _loading, icon: Icons.how_to_reg)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(color: kTextSec, fontFamily: 'Rajdhani')),
                GestureDetector(onTap: () => Navigator.pop(context),
                    child: const Text('Sign In', style: TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 32),
            ])),
          )),
        ])),
      ),
    );
  }

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w700, color: kTextMut, letterSpacing: 2.5)),
  ]);

  Widget _deptDropdown() => DropdownButtonFormField<String>(
    value: _dept, dropdownColor: kCardBg,
    style: const TextStyle(color: kTextPri, fontFamily: 'Rajdhani', fontSize: 15),
    decoration: InputDecoration(
      labelText: 'Department', prefixIcon: const Icon(Icons.school_outlined, size: 20, color: kTextMut),
      filled: true, fillColor: kInputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
      labelStyle: const TextStyle(color: kTextSec, fontFamily: 'Rajdhani'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    items: _depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
    onChanged: (v) => setState(() => _dept = v),
  );
}