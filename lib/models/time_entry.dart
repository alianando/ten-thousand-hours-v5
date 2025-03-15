// Import the sqflite package for SQLite database functionality
import 'package:sqflite/sqflite.dart';
// Import path_provider and path for file system operations (recommended to add)
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';

/// TimeEntry represents a single time tracking event
///
/// This class models the core data structure of the 10,000 hours application.
/// Each TimeEntry instance represents a moment when the user either started (resume=true)
/// or stopped (resume=false) tracking their time towards the 10,000 hour goal.
class TimeEntry {
  /// Database row ID (null for new entries)
  ///
  /// This is the primary key in the SQLite database.
  /// It's null for newly created entries that haven't been saved yet.
  final int? id;

  /// Timestamp when this entry was created
  ///
  /// Stores the exact moment when this tracking event occurred.
  /// Used for chronological ordering and day-based calculations.
  final DateTime dt;

  /// Total accumulated duration up to this point
  ///
  /// Represents the cumulative time tracked across all days.
  /// This is the key metric for progress toward the 10,000 hour goal.
  final Duration globalDur;

  /// Duration for the current day
  ///
  /// Tracks how much time has been accumulated on the specific day
  /// of this entry. Resets to zero at midnight.
  final Duration dayDur;

  /// Whether this entry is a resume or pause event
  ///
  /// - true: User started tracking time (resume/start button pressed)
  /// - false: User stopped tracking time (pause/stop button pressed)
  final bool resume;

  /// Optional description for this time entry
  ///
  /// Allows the user to add notes or context about what they were working on.
  final String? description;

  /// Optional category for grouping time entries
  ///
  /// Enables categorization of time entries (e.g., "Coding", "Practice", "Learning")
  /// which can be used for filtering and analytics.
  final String? category;

  /// Constructor with named parameters for all fields
  ///
  /// All fields except id, description, and category are required.
  const TimeEntry({
    this.id,
    required this.dt,
    required this.globalDur,
    required this.dayDur,
    required this.resume,
    this.description,
    this.category,
  });

  /// Create a new TimeEntry (without ID)
  ///
  /// Factory constructor that provides a more readable way to create TimeEntry instances
  /// without database IDs. Used primarily when creating new events from user actions.
  ///
  /// Example:
  /// ```dart
  /// final newEntry = TimeEntry.create(
  ///   dt: DateTime.now(),
  ///   globalDur: totalDuration,
  ///   dayDur: todayDuration,
  ///   resume: true,
  ///   category: 'Coding',
  /// );
  /// ```
  factory TimeEntry.create({
    required DateTime dt,
    required Duration globalDur,
    required Duration dayDur,
    required bool resume,
    String? description,
    String? category,
  }) {
    return TimeEntry(
      dt: dt,
      globalDur: globalDur,
      dayDur: dayDur,
      resume: resume,
      description: description,
      category: category,
    );
  }

  /// Create a TimeEntry from a database map
  ///
  /// Factory constructor that converts a raw database row (Map) into a TimeEntry object.
  /// Handles data type conversions, such as:
  /// - Integer timestamps to DateTime objects
  /// - Integer milliseconds to Duration objects
  /// - Integer 0/1 to boolean values
  ///
  /// This is used when reading entries from the database.
  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'] as int?,
      dt: DateTime.fromMillisecondsSinceEpoch(map['dt'] as int),
      globalDur: Duration(milliseconds: map['global_dur'] as int),
      dayDur: Duration(milliseconds: map['day_dur'] as int),
      resume: (map['resume'] as int) == 1,
      description: map['description'] as String?,
      category: map['category'] as String?,
    );
  }

  /// Convert TimeEntry to a map for database storage
  ///
  /// Transforms this TimeEntry object into a Map that can be stored in SQLite.
  /// Handles type conversions such as:
  /// - DateTime to integer milliseconds
  /// - Duration to integer milliseconds
  /// - Boolean to integer 0/1
  ///
  /// The 'id' field is only included if it's not null, which allows the same
  /// method to be used for both inserts (no ID) and updates (with ID).
  Map<String, dynamic> toMap() {
    final map = {
      'dt': dt.millisecondsSinceEpoch,
      'global_dur': globalDur.inMilliseconds,
      'day_dur': dayDur.inMilliseconds,
      'resume': resume ? 1 : 0,
      'description': description,
      'category': category,
    };

    // Only include ID if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Create a copy of this TimeEntry with modified fields
  ///
  /// Implements the immutability pattern by creating a new instance with
  /// optionally modified fields instead of changing existing instance state.
  ///
  /// This is useful for updating specific properties while preserving the rest.
  ///
  /// Example:
  /// ```dart
  /// final updatedEntry = existingEntry.copyWith(
  ///   globalDur: Duration(hours: 100),
  ///   category: 'New Category',
  /// );
  /// ```
  TimeEntry copyWith({
    int? id,
    DateTime? dt,
    Duration? globalDur,
    Duration? dayDur,
    bool? resume,
    String? description,
    String? category,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      dt: dt ?? this.dt,
      globalDur: globalDur ?? this.globalDur,
      dayDur: dayDur ?? this.dayDur,
      resume: resume ?? this.resume,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  /// Equality operator override
  ///
  /// Determines when two TimeEntry instances should be considered equal.
  /// This implementation compares all fields, with special handling for DateTime
  /// to check if they represent the same moment rather than the same instance.
  ///
  /// This is useful for comparing database entities and testing.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimeEntry &&
        other.id == id &&
        other.dt.isAtSameMomentAs(dt) &&
        other.globalDur == globalDur &&
        other.dayDur == dayDur &&
        other.resume == resume &&
        other.description == description &&
        other.category == category;
  }

  /// Hash code override
  ///
  /// Generates a consistent hash code for this TimeEntry based on all its fields.
  /// Required to pair with the equality operator to ensure proper behavior in collections
  /// like Sets and Maps that use hash codes for lookups.
  @override
  int get hashCode {
    return Object.hash(
      id,
      dt,
      globalDur,
      dayDur,
      resume,
      description,
      category,
    );
  }

  /// String representation
  ///
  /// Provides a human-readable string representation of the TimeEntry.
  /// Useful for debugging and logging.
  ///
  /// Note that it doesn't include description and category to keep the output concise.
  @override
  String toString() {
    return 'TimeEntry(id: $id, dt: $dt, globalDur: $globalDur, dayDur: $dayDur, resume: $resume)';
  }
}

/// Database helper for TimeEntry operations with optimized querying
///
/// This class implements the Repository pattern for TimeEntry objects,
/// providing methods to store, retrieve, update and delete entries from a SQLite database.
/// It's implemented as a singleton to ensure proper database connection management.
class TimeEntryDatabase {
  /// Singleton instance of the database helper
  ///
  /// Using the singleton pattern ensures that only one instance of the database
  /// connection exists throughout the app, preventing resource leaks.
  static final TimeEntryDatabase _instance = TimeEntryDatabase._internal();

  /// The actual database connection
  ///
  /// It's static to ensure the same connection is shared across all instances.
  /// It's initialized lazily via the database getter.
  static Database? _database;

  // Constants for table and columns to avoid string repetition
  // Using constants reduces the chance of typos and makes refactoring easier

  /// Name of the time entries table in the database
  static const String tableEntries = 'time_entries';

  /// Column name for the primary key ID
  static const String colId = 'id';

  /// Column name for the timestamp
  static const String colDt = 'dt';

  /// Column name for the global duration
  static const String colGlobalDur = 'global_dur';

  /// Column name for the day duration
  static const String colDayDur = 'day_dur';

  /// Column name for the resume/pause flag
  static const String colResume = 'resume';

  /// Column name for the optional description
  static const String colDescription = 'description';

  /// Column name for the optional category
  static const String colCategory = 'category';

  /// Factory constructor for [TimeEntryDatabase] that returns the singleton instance.
  ///
  /// This ensures that only one instance of [TimeEntryDatabase] exists throughout the app.
  /// Usage:
  /// ```dart
  /// final database = TimeEntryDatabase();
  /// ```
  factory TimeEntryDatabase() => _instance;

  /// Private constructor for creating a singleton instance of [TimeEntryDatabase].
  ///
  /// This prevents direct instantiation of the class from outside, ensuring that
  /// only one instance of the database is used throughout the application.
  TimeEntryDatabase._internal();

  /// Get the database instance
  ///
  /// This is a lazy-loading getter that initializes the database connection
  /// if it doesn't exist yet. It ensures the database is properly set up
  /// before any operations are performed.
  ///
  /// Usage:
  /// ```dart
  /// final db = await database.database;
  /// ```
  Future<Database> get database async {
    // Return existing database if already initialized
    if (_database != null) return _database!;

    // Otherwise, initialize database and return it
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database with optimized schema
  ///
  /// This method:
  /// 1. Determines the database file path
  /// 2. Creates the database if it doesn't exist
  /// 3. Sets up the table schema with appropriate columns and types
  /// 4. Creates indexes for optimized querying
  ///
  /// The database is versioned, allowing for schema migrations in the future.
  Future<Database> _initDatabase() async {
    // Get the path to the database file
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/time_entries.db';

    // Open or create the database
    return await openDatabase(
      path,
      version: 1, // Increment this when schema changes
      onCreate: (db, version) async {
        // Create table with optimized schema
        await db.execute('''
        CREATE TABLE $tableEntries(
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colDt INTEGER NOT NULL,
          $colGlobalDur INTEGER NOT NULL,
          $colDayDur INTEGER NOT NULL,
          $colResume INTEGER NOT NULL,
          $colDescription TEXT,
          $colCategory TEXT
        )
        ''');

        // Create indexes for faster querying
        // These indexes significantly speed up the most common queries

        // Index for date-based queries, which are very common
        await db.execute(
          'CREATE INDEX idx_time_entries_dt ON $tableEntries ($colDt)',
        );

        // Index for filtering by resume/pause state
        await db.execute(
          'CREATE INDEX idx_time_entries_resume ON $tableEntries ($colResume)',
        );

        // Index for filtering by category
        await db.execute(
          'CREATE INDEX idx_time_entries_category ON $tableEntries ($colCategory)',
        );
      },
      // If database schema changes, we would implement onUpgrade here:
      // onUpgrade: (db, oldVersion, newVersion) async { ... }
    );
  }

  /// Insert a new TimeEntry and return the inserted entry with ID
  ///
  /// Adds a new TimeEntry to the database and returns an updated version of the entry
  /// that includes the auto-generated ID assigned by SQLite.
  ///
  /// Usage:
  /// ```dart
  /// final savedEntry = await database.insertTimeEntry(newEntry);
  /// print('Saved with ID: ${savedEntry.id}');
  /// ```
  Future<TimeEntry> insertTimeEntry(TimeEntry entry) async {
    final db = await database;
    final id = await db.insert(tableEntries, entry.toMap());
    return entry.copyWith(id: id);
  }

  /// Update an existing TimeEntry
  ///
  /// Modifies an existing TimeEntry in the database based on its ID.
  /// Returns the number of rows affected (should be 1 if successful, 0 if not found).
  ///
  /// Usage:
  /// ```dart
  /// final updatedEntry = existingEntry.copyWith(category: 'New Category');
  /// final rowsAffected = await database.updateTimeEntry(updatedEntry);
  /// ```
  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.update(
      tableEntries,
      entry.toMap(),
      where: '$colId = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete a TimeEntry
  ///
  /// Removes a TimeEntry from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful, 0 if not found).
  ///
  /// Usage:
  /// ```dart
  /// final rowsAffected = await database.deleteTimeEntry(123);
  /// ```
  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      tableEntries,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Get a TimeEntry by ID (with optimized select)
  ///
  /// Retrieves a single TimeEntry from the database by its ID.
  /// Returns null if no entry with the given ID exists.
  ///
  /// Usage:
  /// ```dart
  /// final entry = await database.getTimeEntry(123);
  /// if (entry != null) {
  ///   print('Found: ${entry.dt}');
  /// }
  /// ```
  Future<TimeEntry?> getTimeEntry(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableEntries,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1, // Optimization: only need one result
    );

    if (maps.isEmpty) return null;
    return TimeEntry.fromMap(maps.first);
  }

  /// Get all TimeEntries (with pagination support for performance)
  ///
  /// Retrieves a list of TimeEntry objects from the database.
  /// Supports pagination (limit/offset) and custom ordering to handle large datasets efficiently.
  ///
  /// Usage:
  /// ```dart
  /// // Get the 20 most recent entries
  /// final recentEntries = await database.getAllTimeEntries(limit: 20);
  ///
  /// // Get entries 21-40 for the second page
  /// final page2 = await database.getAllTimeEntries(limit: 20, offset: 20);
  ///
  /// // Get entries ordered by category
  /// final byCategory = await database.getAllTimeEntries(orderBy: 'category ASC');
  /// ```
  Future<List<TimeEntry>> getAllTimeEntries({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableEntries,
      limit: limit, // Maximum number of results to return
      offset: offset, // Number of results to skip (for pagination)
      orderBy: orderBy ?? '$colDt DESC', // Default: most recent first
    );

    return List.generate(maps.length, (i) {
      return TimeEntry.fromMap(maps[i]);
    });
  }

  /// Get TimeEntries for a specific day (optimized)
  ///
  /// Retrieves all TimeEntry objects that occurred on the specified date.
  /// Uses an optimized query with parameters and date range for better performance.
  ///
  /// Usage:
  /// ```dart
  /// final todayEntries = await database.getTimeEntriesForDay(DateTime.now());
  /// ```
  Future<List<TimeEntry>> getTimeEntriesForDay(DateTime date) async {
    final db = await database;

    // Get start and end of the day
    // This ensures we capture all entries for the entire day, regardless of time
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    // Use a prepared statement with parameters for better performance and security
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM $tableEntries WHERE $colDt BETWEEN ? AND ? ORDER BY $colDt ASC',
      [startOfDay, endOfDay],
    );

    return List.generate(maps.length, (i) {
      return TimeEntry.fromMap(maps[i]);
    });
  }

  /// Get latest TimeEntry (optimized query)
  ///
  /// Retrieves the most recent TimeEntry from the database.
  /// Uses an optimized query with direct ordering and limit for better performance.
  /// Returns null if no entries exist.
  ///
  /// This is commonly used to determine the current tracking state and accumulated durations.
  ///
  /// Usage:
  /// ```dart
  /// final latest = await database.getLatestTimeEntry();
  /// final isCurrentlyTracking = latest?.resume == true;
  /// ```
  Future<TimeEntry?> getLatestTimeEntry() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM $tableEntries ORDER BY $colDt DESC LIMIT 1',
    );

    if (maps.isEmpty) return null;
    return TimeEntry.fromMap(maps.first);
  }

  /// Get TimeEntries within a date range (optimized)
  ///
  /// Retrieves all TimeEntry objects between the specified start and end dates.
  /// Uses an optimized query with parameters for better performance and security.
  ///
  /// Usage:
  /// ```dart
  /// final lastWeekEntries = await database.getTimeEntriesBetween(
  ///   DateTime.now().subtract(Duration(days: 7)),
  ///   DateTime.now(),
  /// );
  /// ```
  Future<List<TimeEntry>> getTimeEntriesBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM $tableEntries WHERE $colDt BETWEEN ? AND ? ORDER BY $colDt ASC',
      [startMs, endMs],
    );

    return List.generate(maps.length, (i) {
      return TimeEntry.fromMap(maps[i]);
    });
  }

  /// Clear all TimeEntries
  ///
  /// Deletes all entries from the database.
  /// Returns the number of rows deleted.
  ///
  /// This is a destructive operation and should be used with confirmation.
  ///
  /// Usage:
  /// ```dart
  /// final deletedCount = await database.clearAllTimeEntries();
  /// print('Deleted $deletedCount entries');
  /// ```
  Future<int> clearAllTimeEntries() async {
    final db = await database;
    return await db.delete(tableEntries);
  }

  /// Get summary statistics (optimized)
  ///
  /// Retrieves aggregated statistics about all TimeEntries in a single efficient query.
  /// This is much faster than loading all entries and calculating stats in Dart.
  ///
  /// Returns a map containing:
  /// - totalEntries: The total number of tracking events
  /// - resumeCount: How many times tracking was started
  /// - pauseCount: How many times tracking was stopped
  /// - latestGlobalDuration: The total accumulated time
  /// - activeDaysCount: The number of unique days with tracking activity
  ///
  /// Usage:
  /// ```dart
  /// final stats = await database.getStatistics();
  /// print('Total tracked time: ${stats['latestGlobalDuration']}');
  /// ```
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    // Use a single query to get counts for better performance
    // This is more efficient than multiple separate queries
    final countResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN $colResume = 1 THEN 1 ELSE 0 END) as resume_count,
        SUM(CASE WHEN $colResume = 0 THEN 1 ELSE 0 END) as pause_count
      FROM $tableEntries
    ''');

    final totalEntries = Sqflite.firstIntValue(countResult) ?? 0;
    final resumeCount = Sqflite.firstIntValue(countResult) ?? 0;
    final pauseCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get latest global duration
    Duration latestGlobalDuration = Duration.zero;
    final latestEntry = await getLatestTimeEntry();
    if (latestEntry != null) {
      latestGlobalDuration = latestEntry.globalDur;
    }

    // Count active days with efficient query
    // Uses SQLite's date function to extract just the date component for counting
    final activeDaysResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT date($colDt/1000, 'unixepoch', 'localtime')) as active_days
      FROM $tableEntries
    ''');

    final activeDaysCount = Sqflite.firstIntValue(activeDaysResult) ?? 0;

    return {
      'totalEntries': totalEntries,
      'resumeCount': resumeCount,
      'pauseCount': pauseCount,
      'latestGlobalDuration': latestGlobalDuration,
      'activeDaysCount': activeDaysCount,
    };
  }

  /// Export data to JSON (with pagination for large datasets)
  ///
  /// Retrieves all TimeEntries in a format suitable for export (as raw maps).
  /// Uses pagination to handle large datasets without memory issues.
  ///
  /// The returned list can be directly converted to JSON for export or backup.
  ///
  /// Usage:
  /// ```dart
  /// final data = await database.exportToJson();
  /// final jsonString = jsonEncode(data);
  /// await File('backup.json').writeAsString(jsonString);
  /// ```
  Future<List<Map<String, dynamic>>> exportToJson({int batchSize = 500}) async {
    final db = await database;
    final result = <Map<String, dynamic>>[];

    int offset = 0;
    bool hasMore = true;

    // Use pagination to avoid loading everything into memory at once
    // This is important for users with thousands of entries
    while (hasMore) {
      final batch = await db.query(
        tableEntries,
        limit: batchSize,
        offset: offset,
        orderBy: '$colDt ASC', // Chronological order for logical exports
      );

      if (batch.isEmpty) {
        hasMore = false;
      } else {
        result.addAll(batch);
        offset += batchSize;
      }
    }

    return result;
  }

  /// Import data from JSON (optimized with transactions and batch operations)
  ///
  /// Adds multiple TimeEntries to the database from raw maps (typically from a JSON import).
  /// Uses transactions and batch operations for significant performance gains.
  ///
  /// Usage:
  /// ```dart
  /// final jsonString = await File('backup.json').readAsString();
  /// final data = jsonDecode(jsonString) as List<dynamic>;
  /// final maps = data.cast<Map<String, dynamic>>();
  /// await database.importFromJson(maps);
  /// ```
  Future<void> importFromJson(List<Map<String, dynamic>> data) async {
    final db = await database;

    // Use a transaction for better performance and atomicity
    // Either all entries are imported or none are (on error)
    await db.transaction((txn) async {
      // Process in batches for better performance
      // This is much faster than individual inserts
      const batchSize = 100;
      for (int i = 0; i < data.length; i += batchSize) {
        final end = (i + batchSize < data.length) ? i + batchSize : data.length;
        final batch = txn.batch();

        for (int j = i; j < end; j++) {
          final map = data[j];
          // Remove ID to let SQLite auto-generate it
          // This avoids ID conflicts on import
          map.remove('id');
          batch.insert(tableEntries, map);
        }

        // Commit this batch without returning results (for better performance)
        await batch.commit(noResult: true);
      }
    });
  }

  /// Get day summary - efficiently get summary statistics for each day
  ///
  /// Retrieves daily summary statistics within an optional date range.
  /// Uses efficient SQL aggregation to calculate statistics for each day.
  ///
  /// Results are ordered with most recent days first.
  ///
  /// Usage:
  /// ```dart
  /// // Get summary for all days
  /// final allDays = await database.getDailySummary();
  ///
  /// // Get summary for last 30 days
  /// final recentDays = await database.getDailySummary(
  ///   startDate: DateTime.now().subtract(Duration(days: 30)),
  ///   endDate: DateTime.now(),
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getDailySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    // Build dynamic WHERE clause based on provided date range
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE $colDt BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch
      ];
    } else if (startDate != null) {
      whereClause = 'WHERE $colDt >= ?';
      whereArgs = [startDate.millisecondsSinceEpoch];
    } else if (endDate != null) {
      whereClause = 'WHERE $colDt <= ?';
      whereArgs = [endDate.millisecondsSinceEpoch];
    }

    // Use SQLite functions to group by day and calculate statistics
    // This is much more efficient than loading all entries and processing in Dart
    final query = '''
      SELECT 
        date($colDt/1000, 'unixepoch', 'localtime') as day,
        COUNT(*) as total_entries,
        SUM(CASE WHEN $colResume = 1 THEN 1 ELSE 0 END) as resume_count,
        SUM(CASE WHEN $colResume = 0 THEN 1 ELSE 0 END) as pause_count,
        MAX($colGlobalDur) as max_global_dur,
        MAX($colDayDur) as day_total_dur
      FROM $tableEntries
      $whereClause
      GROUP BY day
      ORDER BY day DESC
    ''';

    final result = await db.rawQuery(query, whereArgs);

    // Process results into a more usable format with proper types
    return result.map((row) {
      return {
        'date': row['day'],
        'totalEntries': row['total_entries'],
        'resumeCount': row['resume_count'],
        'pauseCount': row['pause_count'],
        'globalDuration': Duration(milliseconds: row['max_global_dur'] as int),
        'dayDuration': Duration(milliseconds: row['day_total_dur'] as int),
      };
    }).toList();
  }

  // Additional methods that could be added in the future:
  // - getTimeEntriesByCategory(String category)
  // - getAverageDailyDuration()
  // - getTimeEntriesWithDescription(String searchTerm)
  // - getDurationStatsByWeek() or getDurationStatsByMonth()
}
