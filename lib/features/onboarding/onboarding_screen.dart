import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() {
              isLastPage = index == 2;
            });
          },
          children: [
            buildPage(
              color: Colors.white,
              url: Icons.restaurant,
              title: 'احجز طاولتك بسهولة!',
              subtitle: 'استكشف أفضل المطاعم واحجز طاولتك المفضلة بضغطة زر واحدة في أي وقت.',
            ),
            buildPage(
              color: Colors.white,
              url: Icons.menu_book,
              title: 'اختر المنيو الخاص بك',
              subtitle: 'تصفح قائمة الطعام المتنوعة وقم باختيار وجباتك المفضلة قبل الوصول للمطعم.',
            ),
            buildPage(
              color: Colors.white,
              url: Icons.map,
              title: 'توصيل من المنزل إلى المطعم',
              subtitle: 'خدمة توصيل سريعة وآمنة تضمن لك الوصول إلى مطعمك المفضل براحة تامة.',
            ),
          ],
        ),
      ),
      bottomSheet: isLastPage
          ? TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size.fromHeight(80),
              ),
              child: const Text(
                'ابدأ الآن',
                style: TextStyle(fontSize: 24),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text('تخطي'),
                    onPressed: () => _controller.jumpToPage(2),
                  ),
                  Center(
                    child: SmoothPageIndicator(
                      controller: _controller,
                      count: 3,
                      effect: const WormEffect(
                        spacing: 16,
                        dotColor: Colors.black26,
                        activeDotColor: AppTheme.primaryColor,
                      ),
                      onDotClicked: (index) => _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn,
                      ),
                    ),
                  ),
                  TextButton(
                    child: const Text('التالي'),
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildPage({
    required Color color,
    required IconData url,
    required String title,
    required String subtitle,
  }) =>
      Container(
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(url, size: 200, color: AppTheme.primaryColor),
            const SizedBox(height: 64),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.subTextColor,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      );
}
