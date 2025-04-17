import 'package:flutter/material.dart';
import 'booking_page.dart'; // Import the booking page
import 'feedback_page.dart'; // Import the feedback page

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _QuickAccessCard(Icons.access_time_outlined, 'จำนวนครั้ง')),
              const SizedBox(width: 8),
              Expanded(child: _QuickAccessCard(Icons.calendar_today_outlined, 'นัดหมาย')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('การให้บริการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  'โทรหาคุณหมอ (MU FRIENDS)',
                  'Book Now',
                  'assets/images/doctor.jpg',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookingPage()), // Navigate to BookingPage
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard(
                  'เข้ารับบริการ',
                  'Schedule',
                  'assets/images/stethoscope.jpg',
                  () {}, // Keep the schedule button as is for now
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('สถิติสุขภาพของฉัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('ก้าว', '8,500', '+10%')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('แคลอรี่', '900', '-5%')),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()), // Navigate to FeedbackPage
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Feedback Survey', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAccessCard(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.grey[700]),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final String imagePath;
  final VoidCallback? onPressed; // Add an optional callback

  const _ServiceCard(this.title, this.buttonText, this.imagePath, [this.onPressed]);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onPressed, // Use the provided callback
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(buttonText, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _StatCard(this.label, this.value, this.change);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: change.contains('+') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}