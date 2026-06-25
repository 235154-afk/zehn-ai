import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/chat/chat_screen.dart';
import 'features/study/study_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ZehnAIApp());
}

class ZehnAIApp extends StatelessWidget {
  const ZehnAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZehnAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8C00),
          surface: Color(0xFF0D1B2A),
          background: Color(0xFF0D1B2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ============================================================
//  MAIN NAVIGATION — bottom tabs
// ============================================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const StudyScreen(),
    const CareerPlaceholder(),
    const PlannerPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      BottomNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'AI Chat'),
      BottomNavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Study'),
      BottomNavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Career'),
      BottomNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Planner'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? const Color(0xFFFF8C00)
                            : const Color(0xFF475569),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFFFF8C00)
                              : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ============================================================
//  HOME SCREEN
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Assalam o Alaikum 👋',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ZehnAI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withOpacity(0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Z',
                        style: TextStyle(
                          color: Color(0xFFFF8C00),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick start card
              _quickStartCard(context),
              const SizedBox(height: 24),

              // Feature grid
              const Text(
                'What do you need today?',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _featureGrid(context),
              const SizedBox(height: 24),

              // Capabilities
              const Text(
                'Your AI can solve',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ..._capabilityItems(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStartCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final nav = context.findAncestorStateOfType<_MainNavigationState>();
        nav?.setState(() => nav._currentIndex = 1);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF162032),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF8C00).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ask me anything',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Concepts, career, math, code, planning...',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final features = [
      _Feature('Explain Concepts', Icons.lightbulb_outline, '1'),
      _Feature('Generate MCQs', Icons.quiz_outlined, '2'),
      _Feature('Resume Builder', Icons.description_outlined, '3'),
      _Feature('Mock Interview', Icons.record_voice_over_outlined, '3'),
      _Feature('Solve Math', Icons.calculate_outlined, '1'),
      _Feature('Debug Code', Icons.code, '1'),
      _Feature('Daily Plan', Icons.calendar_today_outlined, '4'),
      _Feature('Summarize PDF', Icons.picture_as_pdf_outlined, '2'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: features.map((f) {
        return GestureDetector(
          onTap: () {
            final nav =
                context.findAncestorStateOfType<_MainNavigationState>();
            nav?.setState(
                () => nav._currentIndex = int.parse(f.navIndex));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF162032),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: Row(
              children: [
                Icon(f.icon, color: const Color(0xFFFF8C00), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.label,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _capabilityItems() {
    final items = [
      'University exams — NTS, PPSC, FPSC style MCQs',
      'All CS subjects — DSA, OS, Networks, DB, SE',
      'Mathematics — Calculus, Linear Algebra, Statistics',
      'Career prep — Resume, LinkedIn, Interviews',
      'Freelancing — Fiverr, Upwork setup and proposals',
      'Time management — Prayer-time aware schedules',
      'Urdu and English — switch anytime',
      'Code review and debugging — all languages',
    ];

    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final String navIndex;
  const _Feature(this.label, this.icon, this.navIndex);
}

// Placeholder screens for Career and Planner
class CareerPlaceholder extends StatelessWidget {
  const CareerPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Career Tools', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Career module coming next!\nResume Builder + Mock Interview',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class PlannerPlaceholder extends StatelessWidget {
  const PlannerPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Daily Planner', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Planner module coming next!\nAI-powered schedule + goals',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
