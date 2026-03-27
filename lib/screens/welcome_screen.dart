import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              const Icon(
                Icons.accessibility_new,
                size: 80,
                color: Colors.orange,
              ),

              const SizedBox(height: 24),

              const Text(
                "Hành trình Handstand",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Cảm ơn cuộc sống đã tặng cho may mắn được sở hữu cơ thể lành lặn.\n\n"
                "Niềm vui của trẻ con khi lần đầu được đứng thẳng trên đôi chân bé nhỏ.\n\n"
                "Bạn đã sẵn sàng tìm lại niềm vui đó một lần nữa trên đôi tay của mình?\n\n"
                "Chúc bạn thành công với thử thách này, để tìm lại niềm vui thuở nào mà bản thân có thể chưa cảm nhận được rõ nét!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Bắt đầu",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}