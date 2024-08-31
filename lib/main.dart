import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';  // Import Syncfusion chart package
import 'dart:async';

void main() {
  runApp(SleepTrackerApp());
}

class SleepTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SleepTrackerPage(),
    );
  }
}

class SleepTrackerPage extends StatefulWidget {
  @override
  _SleepTrackerPageState createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  List<String> _openTimes = [];
  String _lastOpenTime = "";

  @override
  void initState() {
    super.initState();
    _loadOpenTimes().then((_) {
      _addCurrentTime();  // Automatically add the current time when the app opens.
    });
  }

  Future<void> _loadOpenTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedTimes = prefs.getStringList('openTimes');
    if (storedTimes != null) {
      setState(() {
        _openTimes = storedTimes;
        if (_openTimes.isNotEmpty) {
          _lastOpenTime = _openTimes.first;  // Update the last open time to be the most recent
        }
      });
    }
  }

  Future<void> _addCurrentTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentTime = DateTime.now().toString();
    setState(() {
      _openTimes.insert(0, currentTime);  // Insert at the beginning to show most recent first
      _lastOpenTime = currentTime;
    });
    await prefs.setStringList('openTimes', _openTimes);
  }

  Future<void> _clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('openTimes');
    setState(() {
      _openTimes.clear();
      _lastOpenTime = "";
    });
  }

  String _calculateSleepDuration(String previousTime, String currentTime) {
    DateTime prev = DateTime.parse(previousTime);
    DateTime curr = DateTime.parse(currentTime);
    Duration duration = curr.difference(prev);
    return "${duration.inHours} hours, ${duration.inMinutes % 60} minutes, ${duration.inSeconds % 60} seconds";
  }

  List<ChartData> _prepareChartData() {
    List<ChartData> data = [];
    for (int i = 1; i < _openTimes.length; i++) {
      DateTime prev = DateTime.parse(_openTimes[i]);
      DateTime curr = DateTime.parse(_openTimes[i - 1]);
      Duration sleepDuration = curr.difference(prev);

      data.add(ChartData(
        x: prev,
        y: sleepDuration.inMinutes.toDouble(),  // Store duration in minutes
      ));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sleep Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              bool confirm = await _showConfirmationDialog();
              if (confirm) {
                _clearData();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Opened: $_lastOpenTime',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Container(
              height: 200, // Adjust the height of the chart as needed
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),  // Use DateTimeAxis for the x-axis
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Sleep Duration (minutes)'),  // Label the y-axis
                ),
                series: <CartesianSeries>[
                  LineSeries<ChartData, DateTime>(
                    dataSource: _prepareChartData(),
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Colors.blue,
                    markerSettings: MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _openTimes.length,
                itemBuilder: (context, index) {
                  if (index == 0) return SizedBox.shrink();
                  String sleepDuration = _calculateSleepDuration(
                    _openTimes[index],
                    _openTimes[index - 1],
                  );
                  return ListTile(
                    title: Text(_openTimes[index]),
                    subtitle: Text('Sleep Duration: $sleepDuration'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCurrentTime,
        child: Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Data'),
        content: Text('Are you sure you want to clear all the data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear'),
          ),
        ],
      ),
    ) ?? false;
  }
}

class ChartData {
  final DateTime x;
  final double y;

  ChartData({required this.x, required this.y});
}
