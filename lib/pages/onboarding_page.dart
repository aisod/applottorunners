import 'package:flutter/material.dart';
import 'package:lotto_runners/services/onboarding_service.dart';
import 'package:lotto_runners/theme.dart';

/// First-launch tutorial introducing Lotto Runners features.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.directions_run,
      title: 'Welcome to Lotto Runners',
      body:
          'Request errands, book transport, and get things done with trusted runners across Namibia.',
      color: LottoRunnersColors.primaryBlue,
    ),
    _OnboardingSlide(
      icon: Icons.shopping_bag_outlined,
      title: 'Post errands easily',
      body:
          'Shopping, deliveries, document services, and more — pick a service, set locations, and track progress in real time.',
      color: LottoRunnersColors.primaryPurple,
    ),
    _OnboardingSlide(
      icon: Icons.local_taxi,
      title: 'Rides & transport',
      body:
          'Book shuttles, buses, and contract transport. Runners can accept jobs and navigate with built-in maps.',
      color: LottoRunnersColors.teal,
    ),
    _OnboardingSlide(
      icon: Icons.verified_user_outlined,
      title: 'Safe & transparent',
      body:
          'Verified runners, secure payments, and clear policies. Review our Terms and Privacy Policy anytime from your profile.',
      color: LottoRunnersColors.accent,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingService.markComplete();
    if (mounted) widget.onComplete();
  }

  void _next() {
    if (_pageIndex < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _pageIndex == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 56, color: slide.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _pageIndex == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _pageIndex == i
                        ? LottoRunnersColors.primaryBlue
                        : LottoRunnersColors.gray300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryBlue,
                  ),
                  child: Text(isLast ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}
