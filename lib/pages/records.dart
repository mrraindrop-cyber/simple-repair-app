import 'package:flutter/material.dart';
import '../data/local_db.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日记录')),
      body: FutureBuilder(
        future: LocalDB.getTodayOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final orders = snapshot.data as List;
          if (orders.isEmpty) return const Center(child: Text('今日暂无记录'));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  title: Text('${order['plate']} - ${order['customer'] ?? '散客'}'),
                  subtitle: Text(order['create_time'].toString().substring(11, 16)),
                  trailing: Text('¥${order['total'].toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
