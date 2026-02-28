import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../data/local_db.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('数据备份', [
            _buildButton(
              icon: Icons.backup,
              color: Colors.green,
              title: '备份数据',
              subtitle: '生成备份文件，可发微信保存',
              onTap: () => _backup(context),
            ),
            _buildButton(
              icon: Icons.restore,
              color: Colors.orange,
              title: '恢复数据',
              subtitle: '从备份文件恢复（会覆盖现有数据）',
              onTap: () => _restore(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('报表导出', [
            _buildButton(
              icon: Icons.table_chart,
              color: Colors.blue,
              title: '导出月报表',
              subtitle: '生成CSV文件，用Excel打开',
              onTap: () => _exportReport(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('危险操作', [
            _buildButton(
              icon: Icons.delete_forever,
              color: Colors.red,
              title: '清空所有数据',
              subtitle: '删除后无法恢复，请确保已备份',
              onTap: () => _clearAll(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _backup(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final path = await LocalDB.exportDatabase();
      Navigator.pop(context);
      await Share.shareXFiles([XFile(path)], text: '汽修店数据备份');
    } catch (e) {
      Navigator.pop(context);
      _showError(context, '备份失败: $e');
    }
  }

  void _restore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复？'),
        content: const Text('恢复后会覆盖现有数据，请先确保已备份当前数据！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final result = await FilePicker.platform.pickFiles();
              if (result == null) return;
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              
              final success = await LocalDB.importDatabase(result.files.single.path!);
              Navigator.pop(context);
              
              if (success) {
                _showSuccess(context, '恢复成功，请重启App');
              } else {
                _showError(context, '恢复失败');
              }
            },
            child: const Text('选择备份文件'),
          ),
        ],
      ),
    );
  }

  void _exportReport(BuildContext context) async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择月份'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Row(
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: [now.year, now.year - 1].map((y) => 
                    DropdownMenuItem(value: y, child: Text('$y年'))).toList(),
                  onChanged: (v) => setState(() => selectedYear = v!),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => i + 1).map((m) => 
                    DropdownMenuItem(value: m, child: Text('$m月'))).toList(),
                  onChanged: (v) => setState(() => selectedMonth = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                final path = await LocalDB.exportMonthlyReport(selectedYear, selectedMonth);
                Navigator.pop(context);
                await Share.shareXFiles([XFile(path)], text: '$selectedYear年$selectedMonth月经营报表');
              } catch (e) {
                Navigator.pop(context);
                _showError(context, '导出失败');
              }
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  void _clearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('危险操作！'),
        content: const Text('确定要清空所有数据吗？此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('最后确认'),
                  content: const Text('真的确定吗？建议先备份数据！'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('手滑了')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('确定清空')),
                  ],
                ),
              );
              
              if (confirm == true) {
                await LocalDB.clearCache();
                _showSuccess(context, '已清空，请重启App');
              }
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
