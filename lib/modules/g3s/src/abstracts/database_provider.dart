import 'package:sqflite/sqflite.dart';

abstract class DatabaseProvider {

  Future<Database> get database {
    throw "database getter is not implemented";
  }

  Future<Database> initDB() {
    throw "initDB method is not implemented";
  }
}