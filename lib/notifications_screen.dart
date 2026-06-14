import 'package:flutter/material.dart';
import 'login_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notifications are kept local for now.
  // Wire to your backend by adding a /notifications endpoint later.
  final List<Map<String, dynamic>> _notifs = [
    {'title':'Unknown Device Login Attempt','message':'Login attempted from an unregistered device','type':'alert','time':'2h ago','read':false},
    {'title':'New Patrol Report','message':'A new report was submitted for student 22CS001','type':'info','time':'3h ago','read':false},
    {'title':'Repeated Violation Alert','message':'Student 22CS001 has 3 reports this month','type':'warning','time':'5h ago','read':true},
    {'title':'New Patrol Report','message':'A report was submitted for student 22EC045','type':'info','time':'6h ago','read':true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kAppBar('Notifications', context, actions: [
        TextButton(onPressed: () => setState(() => _notifs.forEach((n) => n['read'] = true)),
            child: const Text('Mark all read', style: TextStyle(color: kAccent, fontFamily: 'Rajdhani', fontSize: 13))),
      ]),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2040)])),
        child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _notifs.length, itemBuilder: (ctx, i) {
          final n = _notifs[i];
          final cfg = _config(n['type']);
          final c = cfg['color'] as Color;
          return Padding(padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(onTap: () => setState(() => n['read'] = true),
              child: Container(
                decoration: BoxDecoration(gradient: kCardGrad, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: n['read'] == true ? kDivider : c.withOpacity(0.4), width: n['read'] == true ? 0.5 : 1)),
                child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(cfg['icon'] as IconData, color: c, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(n['title'], style: TextStyle(fontFamily: 'Rajdhani', fontSize: 15,
                          fontWeight: FontWeight.w700, color: n['read'] == true ? kTextSec : kTextPri))),
                      if (n['read'] == false) Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n['message'], style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(cfg['label'] as String, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.5))),
                      const SizedBox(width: 8),
                      Text(n['time'], style: const TextStyle(color: kTextMut, fontFamily: 'Rajdhani', fontSize: 11)),
                    ]),
                  ])),
                ])),
              ),
            ),
          );
        }),
      ),
    );
  }

  Map<String, dynamic> _config(String type) {
    if (type == 'alert')   return {'icon': Icons.security,       'color': kError,   'label': 'SECURITY ALERT'};
    if (type == 'warning') return {'icon': Icons.warning_amber,  'color': kWarning, 'label': 'WARNING'};
    return                        {'icon': Icons.notifications,  'color': kAccent,  'label': 'INFO'};
  }
}
