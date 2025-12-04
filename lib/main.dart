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

  TextEditingController sellSpotController = TextEditingController();
  TextEditingController redeemCouponController = TextEditingController();

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

  Future<void> sellSpot() async {
    final spotId = sellSpotController.text;
    if (spotId.isEmpty) return;
    final res = await http.post(
      Uri.parse('$backendUrl/sell'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'spotId': spotId}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Spot listed for sale')));
      sellSpotController.clear();
    }
  }

  Future<void> redeemCoupon() async {
    final couponId = redeemCouponController.text;
    if (couponId.isEmpty) return;
    final res = await http.post(
      Uri.parse('$backendUrl/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'couponId': couponId}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Coupon redeemed')));
      redeemCouponController.clear();
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
            onPressed: () => setState(() => userType = UserType.Seller),
            child: Text('Seller')),
      ],
    );
  }

  Widget userActions() {
    switch (userType) {
      case UserType.Seeker:
        return Column(
          children: [
            ElevatedButton(onPressed: claimSpot, child: Text('Claim Spot')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: getPoints, child: Text('Get Points')),
            Text('Points: $points'),
          ],
        );
      case UserType.Vacater:
        return Column(
          children: [
            ElevatedButton(onPressed: vacateSpot, child: Text('Vacate Spot')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: getPoints, child: Text('Get Points')),
            Text('Points: $points'),
          ],
        );
      case UserType.Seller:
        return Column(
          children: [
            Text('Points: $points'),
            SizedBox(height: 20),
            TextField(
              controller: sellSpotController,
              decoration: InputDecoration(
                labelText: 'Enter Spot ID to sell',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: sellSpot, child: Text('Sell Spot')),
            SizedBox(height: 20),
            TextField(
              controller: redeemCouponController,
              decoration: InputDecoration(
                labelText: 'Enter Coupon ID to redeem',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: redeemCoupon, child: Text('Redeem Coupon')),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: userType == null ? userSelection() : userActions(),
        ),
      ),
    );
  }
}
