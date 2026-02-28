import 'package:flutter/material.dart';
import '../data/local_db.dart';
import 'inventory.dart';
import 'repair.dart';
import 'debt.dart';
import 'reminder.dart';
import 'records.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _todayRevenue = 0;
  int _todayOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final revenue = await LocalDB.getTodayRevenue();
    final orders = await LocalDB.getTodayOrders();
    setState(() {
      _todayRevenue = revenue;
      _todayOrders = orders.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汽修管家'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const SettingsPage())
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日收入', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '¥${_todayRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('$_todayOrders 单', 
                    style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildButton('开维修单', Icons.build, Colors.orange, 
                    () => _openPage(const RepairPage())),
                  const SizedBox(width: 8),
                  _buildButton('查库存', Icons.inventory, Colors.green,
                    () => _openPage(const InventoryPage())),
                  const SizedBox(width: 8),
                  _buildButton('欠账', Icons.account_balance_wallet, Colors.red,
                    () => _openPage(const DebtPage())),
                  const SizedBox(width: 8),
                  _buildButton('保养提醒', Icons.notifications, Colors.blue,
                    () => _openPage(const ReminderPage())),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: LocalDB.getTodayOrders(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final orders = snapshot.data as List;
                  if (orders.isEmpty) return const Center(child: Text('今日暂无工单'));
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(order['plate']),
                          subtitle: Text(order['customer'] ?? '散客'),
                          trailing: Text('¥${order['total'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            )),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(text, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
      .then((_) => _loadData());
  }
}
