import 'package:flutter/material.dart';
import '../data/local_db.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({Key? key}) : super(key: key);

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  List<Map> _debts = [];
  double _totalDebt = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  void _loadDebts() async {
    final debts = await LocalDB.getUnpaidOrders();
    final total = debts.fold<double>(0, (sum, d) => 
      sum + ((d['total'] as double) - (d['paid_amount'] as double)));
    
    setState(() {
      _debts = debts;
      _totalDebt = total;
    });
  }

  void _pay(int id, double owed) {
    final ctrl = TextEditingController(text: owed.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('收款'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('应收: ¥${owed.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '实收金额',
                prefixText: '¥',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount > 0) {
                await LocalDB.payDebt(id, amount);
                Navigator.pop(context);
                _loadDebts();
              }
            },
            child: const Text('确认收款'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('欠账管理'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '共欠: ¥${_totalDebt.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _debts.isEmpty
          ? const Center(child: Text('无欠账'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _debts.length,
              itemBuilder: (context, index) {
                final debt = _debts[index];
                final owed = (debt['total'] as double) - (debt['paid_amount'] as double);
                
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(debt['customer']?.substring(0, 1) ?? '散'),
                    ),
                    title: Text('${debt['plate']} - ${debt['customer'] ?? '散客'}'),
                    subtitle: Text('${debt['create_time'].toString().substring(0, 10)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '欠¥${owed.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: owed > 0 ? () => _pay(debt['id'], owed) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('收款'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
