import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(ParkingApp());
}

class ParkingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum UserType { Seeker, Vacater, Seller }

class _HomePageState extends State<HomePage> {
  UserType? userType;
  String points = '0';

  String backendUrl = 'http://YOUR_BACKEND_IP:4000';

  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io(
      backendUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    socket?.onConnect((_) {
      print('Connected to backend via Socket.io');
    });
    socket?.on('pointsUpdate', (data) {
      setState(() {
        points = data.toString();
      });
    });
  }

  Future<void> vacateSpot() async {
    final res = await http.post(Uri.parse('$backendUrl/vacate'));
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Spot vacated')));
    }
  }

  Future<void> claimSpot() async {
    final res = await http.post(Uri.parse('$backendUrl/claim'));
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Spot claimed')));
    }
  }

  Future<void> getPoints() async {
    final res = await http.get(Uri.parse('$backendUrl/points'));
    if (res.statusCode == 200) {
      setState(() {
        points = jsonDecode(res.body)['points'].toString();
      });
    }
  }

  Widget userSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Select your user type:'),
        SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => setState(() => userType = UserType.Seeker),
            child: Text('Seeker')),
        ElevatedButton(
            onPressed: () => setState(() => userType = UserType.Vacater),
            child: Text('Vacater')),
        ElevatedButton(
            onPressed: () => setState(()
