import 'package:flutter/material.dart';

// ─── Notification Model ───────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'alert' | 'info' | 'warning'
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id, required this.title, required this.message,
    required this.type, required this.time, this.isRead = false,
  });
}

// In-memory list — replace with GET /api/notifications in backend phase
final List<AppNotification> _notifications = [
  AppNotification(id: '1', title: 'Unknown Device Login Attempt', message: 'Login attempted from an unregistered device for teacher@college.edu', type: 'alert', time: DateTime.now().subtract(const Duration(hours: 2))),
  AppNotification(id: '2', title: 'New Patrol Report', message: 'Dr. Priya Sharma submitted a new report for student 22CS001', type: 'info', time: DateTime.now().subtract(const Duration(hours: 3))),
  AppNotification(id: '3', title: 'Repeated Violation Alert', message: 'Student 22CS001 (Arjun Kumar) has 3 reports this month — escalation recommended', type: 'warning', time: DateTime.now().subtract(const Duration(hours: 5))),
  AppNotification(id: '4', title: 'New Patrol Report', message: 'Prof. Karthik Raj submitted a report for student 22EC045 — Mobile Usage in Library', type: 'info', time: DateTime.now().subtract(const Duration(hours: 6))),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _bg = Color(0xFF0A1628);
  static const Color _card = Color(0xFF142035);
  static const Color _inputFill = Color(0xFF0D1E35);
  static const Color _divider = Color(0xFF1E3555);
  static const Color _accent = Color(0xFF00C2FF);
  static const Color _accentEnd = Color(0xFF0070FF);
  static const Color _warning = Color(0xFFFFB800);
  static const Color _success = Color(0xFF00E096);
  static const Color _error = Color(0xFFFF4D6A);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF8BA3C0);
  static const Color _textMuted = Color(0xFF4A6080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider, width: 0.5)),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('NOTIFICATIONS', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              for (final n in _notifications) n.isRead = true;
            }),
            child: const Text('Mark all read', style: TextStyle(color: _accent, fontFamily: 'Rajdhani', fontSize: 13)),
          ),
        ],
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2040), Colors.transparent]))),
      ),
      body: _notifications.isEmpty
          ? _empty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) => _card_(_notifications[i]),
            ),
    );
  }

  Widget _empty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.notifications_none, size: 64, color: Color(0xFF4A6080)),
      SizedBox(height: 16),
      Text('No Notifications', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
      Text("You're all caught up!", style: TextStyle(color: Color(0xFF4A6080), fontFamily: 'Rajdhani')),
    ]));
  }

  Widget _card_(AppNotification n) {
    final cfg = _config(n.type);
    final color = cfg['color'] as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => n.isRead = true),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF142035), Color(0xFF0D1E35)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: n.isRead ? _divider : color.withOpacity(0.4), width: n.isRead ? 0.5 : 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(cfg['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(n.title,
                      style: TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w700,
                          color: n.isRead ? _textSecondary : _textPrimary))),
                  if (!n.isRead)
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 4),
                Text(n.message, style: const TextStyle(color: _textMuted, fontFamily: 'Rajdhani', fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(cfg['label'] as String,
                        style: TextStyle(fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 8),
                  Text(_timeAgo(n.time), style: const TextStyle(color: _textMuted, fontFamily: 'Rajdhani', fontSize: 11)),
                ]),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Map<String, dynamic> _config(String type) {
    switch (type) {
      case 'alert': return {'icon': Icons.security, 'color': _error, 'label': 'SECURITY ALERT'};
      case 'warning': return {'icon': Icons.warning_amber, 'color': _warning, 'label': 'WARNING'};
      default: return {'icon': Icons.notifications, 'color': _accent, 'label': 'INFO'};
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
