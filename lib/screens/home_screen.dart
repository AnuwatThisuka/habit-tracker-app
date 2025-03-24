import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/habit_service.dart';
import '../screens/settings_screen.dart';
import '../screens/habit_form_screen.dart';
import '../widgets/habit_list_item.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggeredController;

  // State variables
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0-6 (จันทร์-อาทิตย์)
  bool _isLoading = false;
  String _greeting = "";
  String _searchQuery = "";
  bool _showScrollToTopButton = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setGreeting();
    _loadHabits();

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _staggeredController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Listen to scroll for floating button
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTopButton = _scrollController.offset > 300;
      });
    });

    _fadeController.forward();
    _staggeredController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    _staggeredController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = "สวัสดีตอนเช้า";
    } else if (hour < 17) {
      _greeting = "สวัสดีตอนบ่าย";
    } else {
      _greeting = "สวัสดีตอนเย็น";
    }
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final habitService = Provider.of<HabitService>(context, listen: false);
      await habitService.refreshHabits();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.reset();
        _fadeController.forward();
        _staggeredController.reset();
        _staggeredController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF5F5F7);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        body: Consumer<HabitService>(
          builder: (context, habitService, child) {
            final allHabits = habitService.habits;

            // กรองตามการค้นหา
            final filteredHabits = _searchQuery.isEmpty
                ? allHabits
                : allHabits
                    .where((h) =>
                        h.title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        h.description
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

            // กรองตามวันที่เลือก
            final todayHabits = filteredHabits
                .where((h) => h.frequency.contains(_selectedDayIndex))
                .toList();

            // จำนวนกิจวัตรที่ทำสำเร็จวันนี้
            final todayIndex = DateTime.now().weekday - 1;
            final completedTodayCount = allHabits
                .where((h) => h.frequency.contains(todayIndex))
                .where((h) {
              final dayIndex = DateTime.now().difference(h.createdAt).inDays;
              return dayIndex < h.completedDays.length &&
                  h.completedDays[dayIndex] == true;
            }).length;

            // หาสถิติความต่อเนื่องสูงสุด
            final highestStreak = allHabits.isEmpty
                ? 0
                : allHabits
                    .map((h) => h.streak)
                    .reduce((a, b) => a > b ? a : b);

            // กิจวัตรที่ต้องทำวันนี้
            final todayTotalCount =
                allHabits.where((h) => h.frequency.contains(todayIndex)).length;

            // คำนวณเปอร์เซ็นต์ความสำเร็จ
            final todayProgress = todayTotalCount > 0
                ? (completedTodayCount / todayTotalCount)
                : 0.0;

            if (_isLoading) {
              return _buildLoadingScreen(
                  primaryColor, isDarkMode, backgroundColor);
            }

            return SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: backgroundColor,
                    elevation: 0,
                    pinned: true,
                    toolbarHeight: 72,
                    title: _buildGreetingHeader(isDarkMode),
                    actions:
                        _buildAppBarActions(context, isDarkMode, primaryColor),
                  ),

                  // Progress Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildProgressCard(
                        completedToday: completedTodayCount,
                        todayTotal: todayTotalCount,
                        todayProgress: todayProgress,
                        highestStreak: highestStreak,
                        primaryColor: primaryColor,
                        isDarkMode: isDarkMode,
                        cardColor: cardColor,
                      ),
                    ),
                  ),

                  // Day Selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildDaySelector(
                          isDarkMode, primaryColor, cardColor),
                    ),
                  ),

                  // Tabs
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      minHeight: 48.0,
                      maxHeight: 48.0,
                      child: _buildTabBar(isDarkMode, primaryColor, cardColor),
                    ),
                    pinned: true,
                  ),

                  // Tab Content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // แท็บแรก: กิจวัตรของวันที่เลือก
                        _buildHabitListTab(
                          context,
                          todayHabits,
                          habitService,
                          primaryColor,
                          isDarkMode,
                          "ไม่มีกิจวัตรในวันที่เลือก",
                          backgroundColor,
                          cardColor,
                        ),

                        // แท็บสอง: กิจวัตรทั้งหมด
                        _buildHabitListTab(
                          context,
                          filteredHabits,
                          habitService,
                          primaryColor,
                          isDarkMode,
                          "ยังไม่มีกิจวัตร",
                          backgroundColor,
                          cardColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _buildFABs(context, primaryColor),
      ),
    );
  }

  Widget _buildLoadingScreen(
      Color primaryColor, bool isDarkMode, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(bool isDarkMode) {
    return Row(
      children: [
        Text(
          _greeting,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(width: 8),
        Text(
          _getGreetingEmoji(),
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 6) return "🌙"; // ดึก
    if (hour < 12) return "🌅"; // เช้า
    if (hour < 17) return "☀️"; // บ่าย
    if (hour < 20) return "🌆"; // เย็น
    return "🌙"; // กลางคืน
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, bool isDarkMode, Color primaryColor) {
    return [
      IconButton(
        icon: Icon(Icons.search,
            color: isDarkMode ? Colors.white70 : Colors.black54),
        tooltip: 'ค้นหา',
        onPressed: () => _showSearch(context, isDarkMode),
      ),
      IconButton(
        icon: Icon(Icons.sort,
            color: isDarkMode ? Colors.white70 : Colors.black54),
        tooltip: 'จัดเรียง',
        onPressed: () => _showSortOptions(context, isDarkMode, primaryColor),
      ),
      IconButton(
        icon: Icon(Icons.settings_outlined,
            color: isDarkMode ? Colors.white70 : Colors.black54),
        tooltip: 'ตั้งค่า',
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
        },
      ),
    ];
  }

  Widget _buildProgressCard({
    required int completedToday,
    required int todayTotal,
    required double todayProgress,
    required int highestStreak,
    required Color primaryColor,
    required bool isDarkMode,
    required Color cardColor,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Progress Circle
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress Background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Progress Indicator
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: todayProgress,
                        strokeWidth: 8,
                        backgroundColor:
                            isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE8E8E8),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Progress Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(todayProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          '$completedToday/${todayTotal > 0 ? todayTotal : '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะวันนี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.task_alt_outlined,
                          label: 'สำเร็จ',
                          value: '$completedToday',
                          color: Colors.green,
                          isDarkMode: isDarkMode,
                        ),
                        SizedBox(width: 16),
                        _buildStatItem(
                          icon: Icons.local_fire_department_outlined,
                          label: 'สูงสุด',
                          value: '$highestStreak',
                          color: Colors.orange,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ทำดีแล้ว ไปต่อ!',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector(
      bool isDarkMode, Color primaryColor, Color cardColor) {
    final now = DateTime.now();
    final today = now.weekday - 1; // 0-6 for Monday-Sunday
    final startOfWeek = now.subtract(Duration(days: today));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = startOfWeek.add(Duration(days: index));
            final dayName = DateFormat.E().format(date);
            final dayNumber = date.day.toString();
            final isSelected = index == _selectedDayIndex;
            final isToday = index == today;

            return AnimatedBuilder(
              animation: _staggeredController,
              builder: (context, child) {
                // Calculate delayed animation
                final delay = index * 0.1;
                final Animation<double> animation = CurvedAnimation(
                  parent: _staggeredController,
                  curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                    if (_tabController.index != 0) {
                      _tabController.animateTo(0);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 40,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? primaryColor
                                  : isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.3)
                              : isToday
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: primaryColor, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dayNumber,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? primaryColor
                                      : isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode, Color primaryColor, Color cardColor) {
    return Container(
      color: isDarkMode ? Color(0xFF121212) : Color(0xFFF5F5F7),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          dividerHeight: 0,
          unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: GoogleFonts.prompt().fontFamily),
          unselectedLabelStyle: TextStyle(
              fontSize: 12, fontFamily: GoogleFonts.prompt().fontFamily),
          padding: EdgeInsets.all(4),
          tabs: [
            Tab(text: 'วันที่เลือก'),
            Tab(text: 'ทั้งหมด'),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitListTab(
    BuildContext context,
    List habits,
    HabitService habitService,
    Color primaryColor,
    bool isDarkMode,
    String emptyMessage,
    Color backgroundColor,
    Color cardColor,
  ) {
    if (habits.isEmpty) {
      return _buildEmptyState(context, primaryColor, isDarkMode, emptyMessage);
    }

    return RefreshIndicator(
      color: primaryColor,
      backgroundColor: cardColor,
      strokeWidth: 2,
      onRefresh: _loadHabits,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: habits.length,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          // Calculate staggered animation delay
          final Animation<double> animation = CurvedAnimation(
            parent: _staggeredController,
            curve:
                Interval(0.1 * index, 0.1 * index + 0.5, curve: Curves.easeOut),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: HabitListItem(
                habit: habits[index],
                onToggle: (dayIndex) {
                  habitService.toggleHabitCompletion(
                    habits[index].id,
                    dayIndex,
                  );
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitFormScreen(
                        habit: habits[index],
                      ),
                    ),
                  ).then((_) => _loadHabits());
                },
                onDelete: () {
                  habitService.deleteHabit(habits[index].id);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color primaryColor,
    bool isDarkMode,
    String message,
  ) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      },
      child: Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'สร้างนิสัยที่ดีเพื่อพัฒนาตัวเองอย่างต่อเนื่อง',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32),
                _buildAddButton(context, primaryColor, isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
      BuildContext context, Color primaryColor, bool isDarkMode) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HabitFormScreen()),
        ).then((_) => _loadHabits());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'สร้างกิจวัตรใหม่',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFABs(BuildContext context, Color primaryColor) {
    final habitService = Provider.of<HabitService>(context, listen: false);
    if (habitService.habits.isEmpty) {
      return null;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scroll to top FAB (conditional)
        if (_showScrollToTopButton) ...[
          FloatingActionButton.small(
            heroTag: 'scrollTop',
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            backgroundColor: Colors.white.withOpacity(0.8),
            foregroundColor: primaryColor,
            elevation: 2,
            tooltip: 'ขึ้นด้านบน',
            child: Icon(Icons.arrow_upward, size: 20),
          ),
          SizedBox(height: 12),
        ],

        // Add habit FAB
        FloatingActionButton(
          heroTag: 'addHabit',
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HabitFormScreen()),
            ).then((_) => _loadHabits());
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          tooltip: 'เพิ่มกิจวัตรใหม่',
          child: Icon(Icons.add),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context, bool isDarkMode) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ค้นหากิจวัตร',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF252525) : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'พิมพ์เพื่อค้นหากิจวัตร...',
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Search results
                  Expanded(
                    child: Consumer<HabitService>(
                      builder: (context, habitService, _) {
                        final query =
                            _searchController.text.toLowerCase().trim();
                        if (query.isEmpty) {
                          return _buildSearchPlaceholder(isDarkMode);
                        }

                        final results = habitService.habits
                            .where((h) =>
                                h.title.toLowerCase().contains(query) ||
                                h.description.toLowerCase().contains(query))
                            .toList();

                        if (results.isEmpty) {
                          return _buildNoResultsMessage(query, isDarkMode);
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final habit = results[index];
                            return Card(
                              elevation: 0,
                              color: cardColor,
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: habit.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    habit.icon,
                                    color: habit.color,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: habit.description.isNotEmpty
                                    ? Text(
                                        habit.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black54,
                                        ),
                                      )
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _searchQuery = query;
                                    _tabController
                                        .animateTo(1); // Switch to "All" tab
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      setState(() {
        _searchController.clear();
        _searchQuery = "";
      });
    });
  }

  Widget _buildSearchPlaceholder(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: isDarkMode ? Colors.white12 : Colors.black12,
          ),
          SizedBox(height: 16),
          Text(
            'พิมพ์เพื่อค้นหากิจวัตร',
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black45,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsMessage(String query, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: isDarkMode ? Colors.white12 : Colors.black12,
          ),
          SizedBox(height: 16),
          Text(
            'ไม่พบกิจวัตรที่ตรงกับ',
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black45,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '"$query"',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(
      BuildContext context, bool isDarkMode, Color primaryColor) {
    final habitService = Provider.of<HabitService>(context, listen: false);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: EdgeInsets.only(top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'จัดเรียงกิจวัตร',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Options
              Card(
                elevation: 0,
                color: cardColor,
                margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSortOption(
                      context,
                      title: 'เรียงตามชื่อ',
                      subtitle: 'กิจวัตรเรียงตามตัวอักษร',
                      icon: Icons.sort_by_alpha,
                      onTap: () {
                        habitService.sortHabitsByName();
                        Navigator.pop(context);
                      },
                      primaryColor: primaryColor,
                      isDarkMode: isDarkMode,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 16),
                    _buildSortOption(
                      context,
                      title: 'เรียงตามสถิติต่อเนื่อง',
                      subtitle: 'กิจวัตรที่มีสถิติสูงแสดงก่อน',
                      icon: Icons.local_fire_department,
                      onTap: () {
                        habitService.sortHabitsByStreak();
                        Navigator.pop(context);
                      },
                      primaryColor: primaryColor,
                      isDarkMode: isDarkMode,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 16),
                    _buildSortOption(
                      context,
                      title: 'เรียงตามวันที่สร้าง',
                      subtitle: 'กิจวัตรล่าสุดแสดงก่อน',
                      icon: Icons.calendar_today,
                      onTap: () {
                        habitService.sortHabitsByCreationDate();
                        Navigator.pop(context);
                      },
                      primaryColor: primaryColor,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),

              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 0),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Function onTap,
    required Color primaryColor,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
