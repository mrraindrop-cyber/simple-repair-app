import 'package:flutter/material.dart';
import '../data/local_db.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Map> _parts = [];
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  void _loadParts() async {
    final parts = await LocalDB.getParts();
    setState(() => _parts = parts);
  }

  void _addStock(int id, int current) async {
    await LocalDB.updateStock(id, current + 1);
    _loadParts();
  }

  void _reduceStock(int id, int current) async {
    if (current > 0) {
      await LocalDB.updateStock(id, current - 1);
      _loadParts();
    }
  }

  void _addNewPart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增配件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名称')),
            TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: '售价'), keyboardType: TextInputType.number),
            TextField(controller: _stockCtrl, decoration: const InputDecoration(labelText: '库存'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await LocalDB.addPart(
                _nameCtrl.text,
                double.parse(_priceCtrl.text),
                int.parse(_stockCtrl.text),
              );
              _nameCtrl.clear(); _priceCtrl.clear(); _stockCtrl.clear();
              Navigator.pop(context);
              _loadParts();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存管理')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          final stock = part['stock'] as int;
          final minStock = part['min_stock'] as int;
          
          return Card(
            child: ListTile(
              title: Text(part['name']),
              subtitle: Text('售价: ¥${part['price']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.orange),
                    onPressed: () => _reduceStock(part['id'], stock),
                  ),
                  Text(
                    '$stock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: stock <= minStock ? Colors.red : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _addStock(part['id'], stock),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPart,
        child: const Icon(Icons.add),
      ),
    );
  }
}
