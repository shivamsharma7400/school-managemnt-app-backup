import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatMessage {
  final int? id;
  final int sessionId;
  final String role;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'role': role,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['sessionId'],
      role: map['role'],
      text: map['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class ChatSessionData {
  final int? id;
  final String title;
  final DateTime updatedAt;

  ChatSessionData({
    this.id,
    required this.title,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ChatSessionData.fromMap(Map<String, dynamic> map) {
    return ChatSessionData(
      id: map['id'],
      title: map['title'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}

class ChatDatabaseService {
  static final ChatDatabaseService _instance = ChatDatabaseService._internal();
  factory ChatDatabaseService() => _instance;
  ChatDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'student_ai_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            updatedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER,
            role TEXT,
            text TEXT,
            timestamp INTEGER,
            FOREIGN KEY (sessionId) REFERENCES chat_sessions (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Session Operations
  Future<int> createSession(String title) async {
    final db = await database;
    return await db.insert('chat_sessions', ChatSessionData(
      title: title,
      updatedAt: DateTime.now(),
    ).toMap());
  }

  Future<List<ChatSessionData>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('chat_sessions', orderBy: 'updatedAt DESC');
    return List.generate(maps.length, (i) => ChatSessionData.fromMap(maps[i]));
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // Message Operations
  Future<int> addMessage(ChatMessage message) async {
    final db = await database;
    
    // Update session timestamp
    await db.update(
      'chat_sessions', 
      {'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [message.sessionId]
    );

    return await db.insert('messages', message.toMap());
  }

  Future<List<ChatMessage>> getMessages(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC'
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }
}
