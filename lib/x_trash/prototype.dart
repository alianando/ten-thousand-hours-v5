import 'dart:io';
import 'dart:convert';

// Represents a single study session.
class StudySession {
  DateTime startTime;
  DateTime? endTime; // Use nullable DateTime
  Duration? get duration =>
      endTime?.difference(startTime); // Use getter for null safety

  StudySession({required this.startTime, this.endTime});

  // Named constructor for creating a session with only start time.
  StudySession.start(this.startTime);

  // Method to end the study session.
  void end(DateTime endTime) {
    this.endTime = endTime;
  }

  // Convert the StudySession object to a JSON serializable map.  Handles null endTime.
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(), // Store null if endTime is null
    };
  }

  // Factory constructor to create a StudySession object from a JSON map.  Handles null endTime.
  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime']), // Parse as null if missing
    );
  }

  @override
  String toString() {
    return 'Session started at: $startTime, ended at: ${endTime ?? "Not Ended Yet"}, duration: ${duration?.inMinutes ?? "Not Ended Yet"} minutes';
  }
}

// Manages multiple study sessions.
class StudySessionManager {
  List<StudySession> _sessions = [];
  // Use late to initialize in constructor, helpful for file operations.
  late File _dataFile;
  final String _filename = 'study_sessions.json';

  // Constructor:
  StudySessionManager() {
    _initialize(); //  Call async initialization method.
  }

  // Asynchronous initialization method.  Use async void for constructors.
  Future<void> _initialize() async {
    _dataFile = File(_filename);
    await loadSessions(); // Load sessions from file.
  }

  // Getter for the sessions list.  Returns a copy to prevent external modification.
  List<StudySession> get sessions => List.unmodifiable(_sessions);

  // Method to start a new study session.
  void startSession() {
    // Check if there's an existing session that hasn't been ended.
    if (_sessions.isNotEmpty && _sessions.last.endTime == null) {
      print(
          "Error: A session is already in progress. Please end it before starting a new one.");
      return; // Early return to prevent starting a new session.
    }
    final session = StudySession.start(DateTime.now());
    _sessions.add(session);
    print('Started new session at ${session.startTime}');
    saveSessions(); // Save the updated sessions to the file.
  }

  // Method to end the current study session.
  void endSession() {
    if (_sessions.isEmpty || _sessions.last.endTime != null) {
      print('Error: No session to end.');
      return;
    }
    _sessions.last.end(DateTime.now()); // End the last session.
    print('Ended session at ${_sessions.last.endTime}');
    saveSessions(); // Save to file.
  }

  // Method to get the current study session
  StudySession? get currentSession {
    if (_sessions.isEmpty || _sessions.last.endTime != null) {
      return null;
    }
    return _sessions.last;
  }

  // Method to load study sessions from a JSON file.
  Future<void> loadSessions() async {
    try {
      if (await _dataFile.exists()) {
        final contents = await _dataFile.readAsString();
        if (contents.isNotEmpty) {
          final List<dynamic> decodedList = jsonDecode(contents);
          _sessions =
              decodedList.map((item) => StudySession.fromJson(item)).toList();
        } else {
          _sessions = []; // Initialize to empty list if file is empty
        }
      } else {
        print('File does not exist, creating a new one.');
        await _dataFile.create(); // create the file if it does not exist
        _sessions = [];
      }
    } catch (e) {
      print('Error loading sessions: $e');
      // Consider more robust error handling here, such as showing a message to the user.
      _sessions = []; // Initialize to empty list on error to avoid null issues
    }
  }

  // Method to save study sessions to a JSON file.
  Future<void> saveSessions() async {
    try {
      final encodedList = _sessions.map((session) => session.toJson()).toList();
      final contents = jsonEncode(encodedList);
      await _dataFile.writeAsString(contents);
      print('Sessions saved successfully.');
    } catch (e) {
      print('Error saving sessions: $e');
      // Consider more robust error handling (e.g., retrying, showing an error message).
    }
  }

  // Method to calculate average study duration per hour.
  Map<int, Duration> calculateAverageDurationPerHour() {
    Map<int, Duration> hourlyDurations = {};
    Map<int, int> hourlyCounts = {};

    // Initialize maps for all 24 hours.
    for (int hour = 0; hour < 24; hour++) {
      hourlyDurations[hour] = Duration.zero;
      hourlyCounts[hour] = 0;
    }

    // Iterate through each study session.
    for (var session in _sessions) {
      // Ensure the session has an end time.
      if (session.endTime != null && session.duration != null) {
        // Get the starting hour of the session.
        int startHour = session.startTime.hour;
        int endHour = session.endTime!.hour; // Use non-null assertion here

        if (startHour == endHour) {
          hourlyDurations[startHour] =
              (hourlyDurations[startHour] ?? Duration.zero) +
                  session.duration!; // Use non-null assertion here
          hourlyCounts[startHour] = (hourlyCounts[startHour] ?? 0) + 1;
        } else {
          //if session spans multiple hours.
          Duration timeFromStartHour = Duration(hours: 1) -
              Duration(
                  minutes: session.startTime.minute,
                  seconds: session.startTime.second);
          Duration timeTillEndHour = Duration(
              minutes: session.endTime!.minute,
              seconds: session.endTime!.second);

          hourlyDurations[startHour] =
              (hourlyDurations[startHour] ?? Duration.zero) + timeFromStartHour;
          hourlyCounts[startHour] = (hourlyCounts[startHour] ?? 0) + 1;

          int currentHour = startHour + 1;
          while (currentHour < endHour) {
            hourlyDurations[currentHour] =
                (hourlyDurations[currentHour] ?? Duration.zero) +
                    const Duration(hours: 1);
            hourlyCounts[currentHour] = (hourlyCounts[currentHour] ?? 0) + 1;
            currentHour++;
          }
          hourlyDurations[endHour] =
              (hourlyDurations[endHour] ?? Duration.zero) + timeTillEndHour;
          hourlyCounts[endHour] = (hourlyCounts[endHour] ?? 0) + 1;
        }
      }
    }

    // Calculate the average duration for each hour.
    for (int hour = 0; hour < 24; hour++) {
      if (hourlyCounts[hour]! > 0) {
        // Use non-null assertion here
        hourlyDurations[hour] = Duration(
            minutes: (hourlyDurations[hour]!.inMinutes / hourlyCounts[hour]!)
                .round()); // Use non-null assertion here
      }
    }
    return hourlyDurations;
  }

  // Method to display the heatmap data.
  void displayHeatmap() {
    final averageDurations = calculateAverageDurationPerHour();
    print('\nAverage Study Duration per Hour:');
    for (int hour = 0; hour < 24; hour++) {
      String displayHour = hour.toString().padLeft(2, '0');
      String durationString = averageDurations[hour] == Duration.zero
          ? "No data"
          : "${averageDurations[hour]!.inMinutes} min"; // Use non-null assertion here.
      print('$displayHour:00 - ${displayHour}:59: $durationString');
    }
    print('\n');
  }

  // Method to display all study sessions.
  void displayAllSessions() {
    if (_sessions.isEmpty) {
      print('No study sessions recorded yet.');
      return;
    }
    print('\n--- Study Sessions ---');
    for (var session in _sessions) {
      print(session);
    }
    print('----------------------\n');
  }
}

// Main function (entry point of the program).
Future<void> main() async {
  // Make main async to use await
  final manager =
      StudySessionManager(); // Create an instance of the StudySessionManager.

  // Add a small delay to allow the _initialize method to complete.
  await Future.delayed(Duration(milliseconds: 100));

  // Interactive command-line interface.
  while (true) {
    print('\nStudy Session Tracker Menu:');
    print('1. Start Study Session');
    print('2. End Study Session');
    print('3. Display All Sessions');
    print('4. Display Average Duration Heatmap');
    print('5. Exit');
    print('Enter your choice:');

    final input = stdin.readLineSync();
    final choice = int.tryParse(input ?? ''); // Handle null input.

    switch (choice) {
      case 1:
        manager.startSession();
        break;
      case 2:
        manager.endSession();
        break;
      case 3:
        manager.displayAllSessions();
        break;
      case 4:
        manager.displayHeatmap();
        break;
      case 5:
        print('Exiting...');
        return;
      default:
        print('Invalid choice. Please try again.');
    }
  }
}
