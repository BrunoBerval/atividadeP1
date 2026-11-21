import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), 'combustivel.db');
    return openDatabase(
      caminho,
      version: 1,
      // Sem isso o ON DELETE CASCADE NÃO funciona no SQLite.
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE veiculo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marca TEXT NOT NULL,
            modelo TEXT NOT NULL,
            ano INTEGER NOT NULL,
            cilindrada TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE abastecimento (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo_id INTEGER NOT NULL,
            tipo_combustivel TEXT NOT NULL,
            preco_litro REAL NOT NULL,
            quilometragem REAL NOT NULL,
            litros REAL NOT NULL,
            data_hora TEXT NOT NULL,
            FOREIGN KEY (veiculo_id) REFERENCES veiculo(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ---------------- Veículo ----------------

  /// Retorna o único veículo cadastrado, ou null se não houver.
  Future<Veiculo?> buscarVeiculo() async {
    final db = await database;
    final linhas = await db.query('veiculo', limit: 1);
    return linhas.isEmpty ? null : Veiculo.fromMap(linhas.first);
  }

  /// Insere o veículo. Lança [StateError] se já existir um cadastrado.
  Future<int> inserirVeiculo(Veiculo veiculo) async {
    final db = await database;
    if (await buscarVeiculo() != null) {
      throw StateError('Já existe um veículo cadastrado. Exclua-o antes.');
    }
    return db.insert('veiculo', veiculo.toMap());
  }

  /// Exclui o veículo; os abastecimentos somem por ON DELETE CASCADE.
  Future<void> excluirVeiculo(int id) async {
    final db = await database;
    await db.delete('veiculo', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Abastecimentos ----------------

  Future<int> inserirAbastecimento(Abastecimento abastecimento) async {
    final db = await database;
    return db.insert('abastecimento', abastecimento.toMap());
  }

  /// Lista em ordem cronológica (mais antigo primeiro).
  Future<List<Abastecimento>> listarAbastecimentos(int veiculoId) async {
    final db = await database;
    final linhas = await db.query(
      'abastecimento',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data_hora ASC, quilometragem ASC',
    );
    return linhas.map(Abastecimento.fromMap).toList();
  }

  Future<void> excluirAbastecimento(int id) async {
    final db = await database;
    await db.delete('abastecimento', where: 'id = ?', whereArgs: [id]);
  }
}
