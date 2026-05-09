import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8000');
  
  // Database Setup
  final dbPath = p.join(Directory.current.path, 'results.db');
  final db = sqlite3.open(dbPath);
  
  db.execute('''
    CREATE TABLE IF NOT EXISTS results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_name TEXT,
      mode TEXT,
      difficulty TEXT,
      score INTEGER,
      total_rounds INTEGER,
      timestamp TEXT,
      metadata TEXT
    )
  ''');

  final app = Router();

  // API Endpoints
  app.post('/api/results', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      db.execute('''
        INSERT INTO results (player_name, mode, difficulty, score, total_rounds, timestamp, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        data['player_name'],
        data['mode'],
        data['difficulty'],
        data['score'],
        data['total_rounds'],
        data['timestamp'],
        jsonEncode(data['metadata']),
      ]);
      
      return Response.ok(jsonEncode({'status': 'success'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  app.get('/api/stats', (Request request) {
    final ResultSet results = db.select('SELECT * FROM results ORDER BY id DESC LIMIT 100');
    final rows = results.map((row) => Map<String, dynamic>.from(row)).toList();
    return Response.ok(jsonEncode(rows), headers: {'Content-Type': 'application/json'});
  });

  // Static File Serving (Flutter Web Build)
  final webBuildDir = p.join(Directory.current.path, 'web');
  if (!Directory(webBuildDir).existsSync()) {
    print('WARNING: Web build directory not found at $webBuildDir');
    print('Run "flutter build web -t lib/playtest_main.dart" and copy "build/web" to "playtest_server/web"');
  }

  final staticHandler = createStaticHandler(webBuildDir, defaultDocument: 'index.html');

  // Cascade to handle API first, then static files
  final handler = Cascade()
      .add(app.call)
      .add(staticHandler)
      .handler;

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('KALKRA Playtest Server running on http://${server.address.address}:${server.port}');
  print('Database: $dbPath');
}
