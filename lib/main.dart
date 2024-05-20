import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InstalledAppsScreen(),
    );
  }
}

class InstalledAppsScreen extends StatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  _InstalledAppsScreenState createState() => _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends State<InstalledAppsScreen> {
  late Future<List<Application>> _appsFuture;
  bool isYouTubeInstalled = false;
  late Timer _timer;
  bool isDialogShown = false;

  @override
  void initState() {
    super.initState();
    _appsFuture = getInstalledApps();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<List<Application>> getInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true);
    return apps;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
      await checkYouTubeInstalled();
    });
  }

  Future<void> checkYouTubeInstalled() async {
    List<Application> apps = await getInstalledApps();
    bool isInstalled = false;
    for (var app in apps) {
      if (app.packageName == 'com.onecard.bd.daffodil') {
        isInstalled = true;
        break;
      }
    }
    if (isInstalled && !isDialogShown) {
      showDialogIfNeeded();
    }
  }

  Future<void> uninstallApp(String packageName) async {
    bool success = await DeviceApps.uninstallApp(packageName);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('App uninstalled successfully'),
      ));
      setState(() {
        _appsFuture = getInstalledApps(); // Refresh the list of installed apps
        isDialogShown = false; // Reset dialog status
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to uninstall the app'),
      ));
    }
  }

  void showDialogIfNeeded() {
    isDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog dismissal on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text('YouTube app is installed. Do you want to uninstall it to proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                isDialogShown = false; // Reset dialog status
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                uninstallApp('com.onecard.bd.daffodil');
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps'),
      ),
      body: FutureBuilder<List<Application>>(
        future: _appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            List<Application> apps = snapshot.data!;
            return ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                Application app = apps[index];
                return ListTile(
                  leading: app is ApplicationWithIcon
                      ? CircleAvatar(
                    backgroundImage: MemoryImage(app.icon),
                  )
                      : null,
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                );
              },
            );
          }
        },
      ),
    );
  }
}
