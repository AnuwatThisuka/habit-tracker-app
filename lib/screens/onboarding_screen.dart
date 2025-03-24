import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../services/settings_service.dart';
import '../screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;
  final int _numPages = 3;
  bool _isLastPage = false;

  final List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'ยินดีต้อนรับสู่แอปติดตามกิจวัตร',
      'description': 'สร้างนิสัยใหม่ที่ดีและติดตามความก้าวหน้าได้อย่างง่ายดาย',
      'animation': 'assets/animations/habits.json',
      'color': Color(0xFF4361EE),
      'bgImage': 'assets/images/onboarding_bg_1.jpg',
      'icon': Icons.auto_awesome,
    },
    {
      'title': 'สร้างกิจวัตรประจำวัน',
      'description':
          'ตั้งเป้าหมาย กำหนดการแจ้งเตือน และติดตามความต่อเนื่องได้ทุกวัน',
      'animation': 'assets/animations/welcome.json',
      'color': Color(0xFF3A0CA3),
      'bgImage': 'assets/images/onboarding_bg_2.jpg',
      'icon': Icons.trending_up,
    },
    {
      'title': 'พัฒนาตัวเองทุกวัน',
      'description':
          'สถิติแสดงความสำเร็จจะช่วยให้คุณมีแรงบันดาลใจในการพัฒนาตัวเอง',
      'animation': 'assets/animations/growth.json',
      'color': Color(0xFF7209B7),
      'bgImage': 'assets/images/onboarding_bg_3.jpg',
      'icon': Icons.celebration,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _pageController.addListener(() {
      setState(() {
        _isLastPage = _pageController.page?.round() == _numPages - 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ปรับสถานะบาร์ให้เป็นสีขาว
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true, // ให้เนื้อหาขยายไปใต้ AppBar
      body: Stack(
        children: [
          // Background with image and blur effect
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: Container(
              key: ValueKey<int>(_currentPage),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Stack(
                    children: [
                      // Background design elements
                      Positioned(
                        top: -100,
                        right: -100,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -80,
                        left: -80,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Floating pattern elements
                      ...List.generate(10, (index) {
                        return Positioned(
                          top: 100 + (index * 70),
                          left: (index % 2 == 0) ? 20 + (index * 30) : null,
                          right: (index % 2 != 0) ? 20 + (index * 20) : null,
                          child: Opacity(
                            opacity: 0.1 + (index * 0.02),
                            child: Icon(
                              onboardingData[_currentPage]['icon'],
                              size: 20.0 + (index * 2),
                              color: Colors.white,
                            ),
                          ),
                        );
                      }),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              onboardingData[_currentPage]['color']
                                  .withOpacity(0.3),
                              onboardingData[_currentPage]['color']
                                  .withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button with blur effect
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _goToHomePage();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'ข้าม',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                        _isLastPage = page == _numPages - 1;
                      });
                      _animationController.reset();
                      _animationController.forward();
                    },
                    itemCount: _numPages,
                    itemBuilder: (context, index) {
                      return _buildPage(
                        context,
                        onboardingData[index]['title'],
                        onboardingData[index]['description'],
                        onboardingData[index]['animation'],
                        onboardingData[index]['color'],
                        index,
                      );
                    },
                  ),
                ),

                // Bottom controls
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _numPages,
                          (index) => AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Next/Start button with glass effect
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: _isLastPage ? 170 : 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: Colors.white.withOpacity(0.2),
                                  highlightColor: Colors.transparent,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    if (_currentPage < _numPages - 1) {
                                      _pageController.animateToPage(
                                        _currentPage + 1,
                                        duration: Duration(milliseconds: 600),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _goToHomePage();
                                    }
                                  },
                                  child: Center(
                                    child: _isLastPage
                                        ? FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'เริ่มต้นใช้งาน',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String description,
      String animationPath, Color color, int index) {
    final size = MediaQuery.of(context).size;

    // ปรับขนาดภาพเคลื่อนไหวให้เล็กลงเพื่อแก้ไขปัญหา overflow
    final animationHeight =
        size.height < 700 ? size.height * 0.3 : size.height * 0.35;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),

              // Animation with container effect
              Container(
                height: animationHeight,
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glass effect background for animation
                    Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                    ),

                    // Actual animation
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Lottie.asset(
                        animationPath,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Decorative circles
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 10,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page number indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'หน้า ${index + 1} จาก $_numPages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),

              // Title with shadow effect
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12),

              // Description with backdrop blur
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // เพิ่มพื้นที่ว่างด้านล่างเพื่อให้สามารถเลื่อนได้
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _goToHomePage() {
    // บันทึกว่าผู้ใช้ไม่ได้เป็นผู้ใช้ครั้งแรกอีกต่อไป
    Provider.of<SettingsService>(context, listen: false)
        .setFirstTimeUser(false);

    // นำทางไปยังหน้าหลัก
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }
}
