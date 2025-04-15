import 'package:flutter/material.dart';
 import 'package:flutter_map/flutter_map.dart';
 import 'package:latlong2/latlong.dart';
 import 'package:geocoding/geocoding.dart'; // Import geocoding package

 class BookingPage extends StatefulWidget {
   const BookingPage({super.key});

   @override
   State<BookingPage> createState() => _BookingPageState();
 }

 class _BookingPageState extends State<BookingPage> {
   // พิกัดของอาคารศูนย์การเรียนรู้ มหาวิทยาลัยมหิดล (ศาลายา) โดยประมาณ
   final LatLng _mahidolLearningCenter = const LatLng(13.794008768827078, 100.32122162623837);
   final double _zoomLevel = 15.0;
   final MapController _mapController = MapController();
   final TextEditingController _searchController = TextEditingController();
   List<Marker> _markers = []; // เก็บรายการ Markers

   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
       _mapController.move(_mahidolLearningCenter, _zoomLevel);
       // You might want to add the initial marker here as well, after the map is moved
       setState(() {
         _markers.add(
           Marker(
             width: 80.0,
             height: 80.0,
             point: _mahidolLearningCenter,
             child: const Icon(
               Icons.location_pin,
               color: Colors.blue,
               size: 40.0,
             ),
           ),
         );
       });
     });
   }

   Future<void> _searchLocation(String searchText) async {
     // ... (rest of your _searchLocation method) ...
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Booking'),
       ),
       body: SingleChildScrollView(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // Row( // ส่วนของ Header ที่ถูกเอาออก
               //   children: [
               //     const CircleAvatar(
               //       backgroundImage: AssetImage('assets/images/profile.png'), // เปลี่ยน path ตามจริง
               //     ),
               //     const SizedBox(width: 16),
               //     const Column(
               //       crossAxisAlignment: CrossAxisAlignment.start,
               //       children: [
               //         Text(
               //           'คุณ วินีธา, 6687001',
               //           style: TextStyle(
               //               fontSize: 18, fontWeight: FontWeight.bold),
               //         ),
               //         Text('สถานที่ใกล้คุณ, MU HEALTH'),
               //       ],
               //     ),
               //   ],
               // ), // ส่วนของ Header ที่ถูกเอาออก
               // const SizedBox(height: 16), // ส่วนของ SizedBox ที่อาจต้องการเอาออกด้วย
               const Text(
                 'เลือกประเภทการเข้ารับบริการ',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               // ... (ส่วนอื่นๆ ของ UI ของคุณ) ...
               TextField(
                 controller: _searchController,
                 decoration: InputDecoration(
                   hintText: 'MU HEALTH',
                   suffixIcon: IconButton(
                     icon: const Icon(Icons.search),
                     onPressed: () {
                       _searchLocation(_searchController.text);
                     },
                   ),
                 ),
                 onSubmitted: (value) {
                   _searchLocation(value);
                 },
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () {},
                       child: const Text('ประวัติการเข้ารับบริการ'),
                     ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () {},
                       child: const Text('สแกน'),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               SizedBox(
                 height: 200,
                 child: FlutterMap(
                   mapController: _mapController,
                   options: MapOptions(
                     initialCenter: _mahidolLearningCenter,
                     initialZoom: _zoomLevel,
                   ),
                   children: [
                     TileLayer(
                       urlTemplate:
                           'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                       subdomains: const ['a', 'b', 'c'],
                     ),
                     MarkerLayer(
                       markers: _markers,
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 16),
               const Text(
                 'สถิติของสถานที่ให้บริการ',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   Expanded(
                     child: Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.grey[200],
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: const Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             '125',
                             style: TextStyle(
                                 fontSize: 24, fontWeight: FontWeight.bold),
                           ),
                           Text('+10%'),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.grey[200],
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: const Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             '5 นาที',
                             style: TextStyle(
                                 fontSize: 24, fontWeight: FontWeight.bold),
                           ),
                           Text('-5%'),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ],
           ),
         ),
       ),
     );
   }
 }