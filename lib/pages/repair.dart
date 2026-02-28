import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local_db.dart';
import '../data/local_storage.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({Key? key}) : super(key: key);

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  final _plateCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  
  final List<Map> _items = [];
  File? _photo;

  final quickItems = [
    {'name': '壳牌机油 4L', 'price': 280.0},
    {'name': '机油滤芯', 'price': 45.0},
    {'name': '空气滤芯', 'price': 65.0},
    {'name': '小保养工时', 'price': 80.0},
    {'name': '换轮胎工时', 'price': 50.0},
    {'name': '刹车片 前片', 'price': 180.0},
  ];

  double get _total => _items.fold(0.0, (sum, item) => sum + item['price']);

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final savedPath = await LocalStorage.saveImage(File(picked.path));
      setState(() => _photo = File(savedPath));
    }
  }

  void _showQuickItems() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: quickItems.length,
          itemBuilder: (context, index) {
            final item = quickItems[index];
            return ListTile(
              title: Text(item['name'] as String),
              trailing: Text('¥${item['price']}'),
              onTap: () {
                setState(() => _items.add(Map.from(item)));
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _addCustomItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义项目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '价格'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _items.add({
                    'name': nameCtrl.text,
                    'price': double.parse(priceCtrl.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _saveOrder({bool isPaid = false}) async {
    if (_plateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写车牌号')));
      return;
    }

    await LocalDB.saveOrder({
      'plate': _plateCtrl.text.toUpperCase(),
      'customer': _customerCtrl.text,
      'phone': _phoneCtrl.text,
      'mileage': int.tryParse(_mileageCtrl.text),
      'items': jsonEncode(_items),
      'total': _total,
      'paid_amount': isPaid ? _total : 0,
      'is_paid': isPaid ? 1 : 0,
      'photo_path': _photo?.path,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开维修单'),
        actions: [
          TextButton(
            onPressed: () => _saveOrder(isPaid: true),
            child: const Text('现结', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: '车牌号',
                    hintText: '如:京A88888',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customerCtrl,
                        decoration: const InputDecoration(labelText: '客户姓名'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: '电话'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mileageCtrl,
                  decoration: const InputDecoration(
                    labelText: '当前里程(km)',
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),

          if (_photo != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_photo!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _photo = null),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照留证（修车前）'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

          const SizedBox(height: 16),

          Expanded(
            child: _items.isEmpty
              ? const Center(child: Text('点击右下角添加项目'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('¥${item['price'].toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('合计:', style: TextStyle(fontSize: 18)),
                      Text(
                        '¥${_total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveOrder(isPaid: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('赊账（欠着）'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveOrder(isPaid: true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('现结（付清）'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'quick',
            onPressed: _showQuickItems,
            child: const Icon(Icons.flash_on),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'custom',
            onPressed: _addCustomItem,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
