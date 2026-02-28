import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';

class LocalDB {
  static Database? _db;
  
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'repair.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE parts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL DEFAULT 0,
            stock INTEGER DEFAULT 0,
            min_stock INTEGER DEFAULT 5
          )
        ''');
        
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plate TEXT NOT NULL,
            customer TEXT,
            phone TEXT,
            mileage INTEGER,
            items TEXT,
            total REAL DEFAULT 0,
            paid_amount REAL DEFAULT 0,
            is_paid INTEGER DEFAULT 0,
            photo_path TEXT,
            next_oil_change INTEGER,
            create_time TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE orders ADD COLUMN paid_amount REAL DEFAULT 0');
          await db.execute('ALTER TABLE orders ADD COLUMN is_paid INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE orders ADD COLUMN mileage INTEGER');
          await db.execute('ALTER TABLE orders ADD COLUMN photo_path TEXT');
          await db.execute('ALTER TABLE orders ADD COLUMN next_oil_change INTEGER');
        }
      },
    );
  }

  static Future<List<Map>> getParts() async {
    final db = await database;
    return db.query('parts', orderBy: 'name');
  }

  static Future<void> addPart(String name, double price, int stock) async {
    final db = await database;
    await db.insert('parts', {
      'name': name,
      'price': price,
      'stock': stock,
    });
  }

  static Future<void> updateStock(int id, int newStock) async {
    final db = await database;
    await db.update('parts', {'stock': newStock}, 
      where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map>> getTodayOrders() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    return db.query(
      'orders',
      where: "create_time LIKE ?",
      whereArgs: ['$today%'],
      orderBy: 'create_time DESC',
    );
  }

  static Future<double> getTodayRevenue() async {
    final orders = await getTodayOrders();
    return orders.fold(0.0, (sum, o) => sum + (o['total'] as double));
  }

  static Future<List<Map>> getUnpaidOrders() async {
    final db = await database;
    return db.query(
      'orders',
      where: 'is_paid = 0 OR total > paid_amount',
      orderBy: 'create_time DESC',
    );
  }

  static Future<void> payDebt(int orderId, double amount) async {
    final db = await database;
    final order = (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).first;
    final newPaid = (order['paid_amount'] as double) + amount;
    final total = order['total'] as double;
    
    await db.update('orders', {
      'paid_amount': newPaid,
      'is_paid': newPaid >= total ? 1 : 0,
    }, where: 'id = ?', whereArgs: [orderId]);
  }

  static Future<List<Map>> getOverdueMaintenance() async {
    final db = await database;
    return db.rawQuery('''
      SELECT * FROM orders 
      WHERE next_oil_change IS NOT NULL
      AND (next_oil_change <= (
        SELECT MAX(mileage) FROM orders 
        WHERE plate = orders.plate
      ) + 500 OR julianday('now') - julianday(create_time) > 90)
      AND is_paid = 1
      GROUP BY plate
      ORDER BY next_oil_change ASC
    ''');
  }

  static Future<void> saveOrder(Map order) async {
    final db = await database;
    
    int? nextOilChange;
    if (order['mileage'] != null) {
      nextOilChange = (order['mileage'] as int) + 5000;
    }
    
    await db.insert('orders', {
      'plate': order['plate'],
      'customer': order['customer'],
      'phone': order['phone'],
      'mileage': order['mileage'],
      'items': order['items'],
      'total': order['total'],
      'paid_amount': order['paid_amount'] ?? 0,
      'is_paid': order['is_paid'] ?? 0,
      'photo_path': order['photo_path'],
      'next_oil_change': nextOilChange,
      'create_time': DateTime.now().toIso8601String(),
    });
  }

  static Future<String> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'repair.db'));
    
    final tempDir = await getTemporaryDirectory();
    final backupFile = File(join(tempDir.path, 
      '汽修数据备份_${DateTime.now().toString().substring(0,10)}.db'));
    
    await dbFile.copy(backupFile.path);
    return backupFile.path;
  }

  static Future<bool> importDatabase(String sourcePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'repair.db'));
      
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
      
      final sourceFile = File(sourcePath);
      await sourceFile.copy(dbFile.path);
      
      await database;
      return true;
    } catch (e) {
      print('恢复失败: $e');
      return false;
    }
  }

  static Future<String> exportMonthlyReport(int year, int month) async {
    final db = await database;
    
    final startDate = '$year-${month.toString().padLeft(2,'0')}-01';
    final endDate = '$year-${month.toString().padLeft(2,'0')}-31';
    
    final orders = await db.query(
      'orders',
      where: "create_time BETWEEN ? AND ?",
      whereArgs: [startDate, endDate],
    );

    final StringBuffer csv = StringBuffer();
    csv.writeln('日期,车牌,客户,项目,金额,状态');
    
    for (var order in orders) {
      final items = order['items'].toString().replaceAll(',', ' ');
      final status = (order['is_paid'] as int) == 1 ? '已结清' : '欠账';
      
      csv.writeln('${order['create_time']},'
          '${order['plate']},'
          '${order['customer'] ?? '散客'},'
          '$items,'
          '${order['total']},'
          '$status');
    }
    
    final total = orders.fold<double>(0, (sum, o) => sum + (o['total'] as double));
    final paid = orders.where((o) => o['is_paid'] == 1).fold<double>(
      0, (sum, o) => sum + (o['total'] as double));
    final debt = total - paid;
    
    csv.writeln('');
    csv.writeln('汇总,,,,,');
    csv.writeln('总收入,$total,,,,');
    csv.writeln('已收款,$paid,,,,');
    csv.writeln('未收款,$debt,,,,');
    csv.writeln('订单数,${orders.length},,,,');

    final tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, 
      '${year}年${month}月报表.csv'));
    await file.writeString(csv.toString());
    
    return file.path;
  }

  static Future<bool> clearCache() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'repair.db'));
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    _db = null;
    return true;
  }
}
