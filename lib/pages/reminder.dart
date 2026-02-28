import 'package:flutter/material.dart';
import '../data/local_db.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({Key? key}) : super(key: key);

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map> _overdue = [];

  @override
  void initState() {
    super.initState();
    _loadOverdue();
  }

  void _loadOverdue() async {
    final list = await LocalDB.getOverdueMaintenance();
    setState(() => _overdue = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('保养提醒')),
      body: _overdue.isEmpty
          ? const Center(child: Text('暂无到期客户'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _overdue.length,
              itemBuilder: (context, index) {
                final item = _overdue[index];
                
                return Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active, color: Colors.orange),
                    title: Text('${item['plate']} - ${item['customer'] ?? '散客'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('上次里程: ${item['mileage']} km'),
                        Text('建议保养: ${item['next_oil_change']} km'),
                        if (item['phone'] != null)
                          Text('电话: ${item['phone']}'),
                      ],
                    ),
                    trailing: item['phone'] != null
                        ? IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {},
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
