import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LogInfoItem {
  final String boardID;
  final String boardAlias;
  final String logFilePath;
  final double avgSpeed;
  final double maxSpeed;
  final double elevationChange;
  final double maxAmpsBattery;
  final double maxAmpsMotors;
  final double distance;
  final int    durationSeconds;
  final int    faultCount;
  final String rideName;
  final String notes;

  LogInfoItem({
    this.boardID,
    this.boardAlias,
    this.logFilePath,
    this.avgSpeed,
    this.maxSpeed,
    this.elevationChange,
    this.maxAmpsBattery,
    this.maxAmpsMotors,
    this.distance,
    this.durationSeconds,
    this.faultCount,
    this.rideName,
    this.notes
  });

  // Convert a LogInfoItem into a map for the database
  // The keys correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'board_id' : boardID,
      'board_alias' : boardAlias,
      'log_file_path' : logFilePath,
      'avg_speed' : avgSpeed,
      'max_speed' : maxSpeed,
      'elevation_change' : elevationChange,
      'max_amps_battery' : maxAmpsBattery,
      'max_amps_motors' : maxAmpsMotors,
      'distance_km' : distance,
      'duration_seconds' : durationSeconds,
      'fault_count' : faultCount,
      'ride_name' : rideName,
      'notes': notes,
    };
  }
}

class DatabaseAssistant {

  static Future<Database> getDatabase() async {
    //print("DatabaseAssistant: getDatabase: called");
    return openDatabase(
      join(await getDatabasesPath(), 'logDatabase.db'), // Set the path to the database.
      onCreate: (db, version) async {
        final int dbCurrentVersion = await db.getVersion();
        print("DatabaseAssistant: getDatabase: openDatabase: onCreate() called. Version $version DBVersion $dbCurrentVersion");
        // Create a table to store ride log details
        return db.execute(
          "CREATE TABLE IF NOT EXISTS logs("
              "id INTEGER PRIMARY KEY, "
              "date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
              "board_id TEXT, "
              "board_alias TEXT, "
              "log_file_path TEXT UNIQUE, "
              "avg_speed REAL, "
              "max_speed REAL, "
              "elevation_change REAL, "
              "max_amps_battery REAL, "
              "max_amps_motors REAL, "
              "distance_km REAL, "
              "duration_seconds REAL, "
              "fault_count INTEGER, "
              "ride_name TEXT, "
              "notes TEXT)",
        );
      },
      onOpen: (db) async {
        int version = await db.getVersion();
        print("DatabaseAssistant: getDatabase: openDatabase: onOpen(). Version $version");
      },
      // Set the version. This executes the onCreate function and provides a path to perform database upgrades and downgrades.
      version: 3,
    );
  }

  static Future<int> dbInsertLog(LogInfoItem logItem) async {
    final Database db = await getDatabase();

    return db.insert('logs', logItem.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    //TODO: consider closing database// .then((value){db.close();return value;});
  }

  static Future<int> dbRemoveLog(String logFilePath) async {
    final Database db = await getDatabase();

    return db.delete('logs', where: "log_file_path = '$logFilePath'" );
  }

  static Future<List<LogInfoItem>> dbSelectLogs({String orderByClause = "id DESC"}) async {
    final Database db = await getDatabase();
    final List<Map<String, dynamic>> rideLogEntries = await db.query('logs', orderBy: orderByClause);

    return List.generate(rideLogEntries.length, (i) {
      return LogInfoItem(
          boardID:         rideLogEntries[i]['board_id'],
          boardAlias:      rideLogEntries[i]['board_alias'],
          logFilePath:     rideLogEntries[i]['log_file_path'],
          avgSpeed:        rideLogEntries[i]['avg_speed'],
          maxSpeed:        rideLogEntries[i]['max_speed'],
          elevationChange: rideLogEntries[i]['elevation_change'],
          maxAmpsBattery:  rideLogEntries[i]['max_amps_battery'],
          maxAmpsMotors:   rideLogEntries[i]['max_amps_motors'],
          distance:        rideLogEntries[i]['distance_km'],
          durationSeconds: rideLogEntries[i]['duration_seconds'].toInt(),
          faultCount:      rideLogEntries[i]['fault_count'],
          rideName:        rideLogEntries[i]['ride_name'],
          notes:           rideLogEntries[i]['notes']
      );
    });
  }
  
  static Future<int> dbUpdateNote( String file, String note ) async {
    final Database db = await getDatabase();
    return db.update('logs', {'notes': note}, where: 'log_file_path = ?', whereArgs: [file]);
  }
  
  static Future<void> close() async {
    final Database db = await getDatabase();
    await db.close();
  }

  //TODO: remove these
  static Future<void> dbDEBUGDropTable() async {
    final Database db = await getDatabase();
    return db.execute("DROP TABLE 'logs'");
  }
  static Future<void> dbDEBUGCreateTable() async {
    final Database db = await getDatabase();
    return db.execute("CREATE TABLE IF NOT EXISTS logs("
        "id INTEGER PRIMARY KEY, "
        "date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
        "board_id TEXT, "
        "board_alias TEXT, "
        "log_file_path TEXT UNIQUE, "
        "avg_speed REAL, "
        "max_speed REAL, "
        "elevation_change REAL, "
        "max_amps_battery REAL, "
        "max_amps_motors REAL, "
        "distance_km REAL, "
        "duration_seconds REAL, "
        "fault_count INTEGER, "
        "ride_name TEXT, "
        "notes TEXT)",);
  }
}