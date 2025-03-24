import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import 'package:intl/intl.dart';

class HabitListItem extends StatelessWidget {
  final Habit habit;
  final Function(int) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitListItem({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now().difference(habit.createdAt).inDays;
    final isCompletedToday =
        today < habit.completedDays.length && habit.completedDays[today];

    // สีจากกิจวัตร
    final habitColor = habit.color;

    // คำนวณสถิติ
    final completionRate = _calculateCompletionRate();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: habitColor.withOpacity(isDarkMode ? 0.15 : 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showHabitDetails(context),
            splashColor: habitColor.withOpacity(0.1),
            highlightColor: habitColor.withOpacity(0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main content area
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Icon and completion status
                      _buildIconWithCompletion(
                          context, isCompletedToday, habitColor, isDarkMode),

                      SizedBox(width: 16),

                      // Center: Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and streak
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    habit.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (habit.streak > 0)
                                  _buildStreakBadge(isDarkMode),
                              ],
                            ),

                            // Description
                            if (habit.description.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                habit.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            SizedBox(height: 12),

                            // Frequency days
                            _buildFrequencyDays(
                                context, isDarkMode, habitColor),

                            SizedBox(height: 12),

                            // Progress indicator
                            _buildProgressIndicator(
                                completionRate, habitColor, isDarkMode),
                          ],
                        ),
                      ),

                      // Right: Action buttons
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCompletionToggle(context, isCompletedToday,
                              today, habitColor, isDarkMode),
                          SizedBox(height: 16),
                          _buildMenuButton(context, habitColor, isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),

                // Week view
                _buildWeekView(context, today, habitColor, isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับแสดงไอคอนกิจวัตรและสถานะการทำ
  Widget _buildIconWithCompletion(BuildContext context, bool isCompleted,
      Color habitColor, bool isDarkMode) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: habitColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        habit.icon,
        color: habitColor,
        size: 24,
      ),
    );
  }

  // Widget สำหรับแสดงแถบสถิติต่อเนื่อง
  Widget _buildStreakBadge(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            habit.streak.toString(),
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับแสดงความถี่
  Widget _buildFrequencyDays(
      BuildContext context, bool isDarkMode, Color habitColor) {
    final List<String> weekdays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(7, (index) {
        final bool isDaySelected = habit.frequency.contains(index);

        return Container(
          margin: EdgeInsets.only(right: 6),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDaySelected
                ? habitColor.withOpacity(0.2)
                : isDarkMode
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            border:
                isDaySelected ? Border.all(color: habitColor, width: 1) : null,
          ),
          child: Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isDaySelected ? FontWeight.bold : FontWeight.normal,
                color: isDaySelected
                    ? habitColor
                    : isDarkMode
                        ? Colors.white60
                        : Colors.black45,
              ),
            ),
          ),
        );
      }),
    );
  }

  // Widget สำหรับแสดงความคืบหน้า
  Widget _buildProgressIndicator(
      double progress, Color habitColor, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ความสำเร็จ',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: habitColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: habitColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(habitColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  // Widget สำหรับปุ่มเมนูเพิ่มเติม
  Widget _buildMenuButton(
      BuildContext context, Color habitColor, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        _showActionsMenu(context, habitColor, isDarkMode);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF0F0F0),
        ),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: isDarkMode ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มเปิด/ปิด
  Widget _buildCompletionToggle(BuildContext context, bool isCompleted,
      int today, Color habitColor, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggle(today);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? habitColor : Colors.transparent,
          border: Border.all(
            color: isCompleted
                ? habitColor
                : isDarkMode
                    ? Colors.white38
                    : Colors.black26,
            width: 2,
          ),
        ),
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }

  // Widget สำหรับแสดงภาพรวมรายสัปดาห์
  Widget _buildWeekView(
      BuildContext context, int today, Color habitColor, bool isDarkMode) {
    final weekDays = _getLastSevenDays();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF252525) : habitColor.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final dayIndex = today - (6 - index);
          final isInRange =
              dayIndex >= 0 && dayIndex < habit.completedDays.length;
          final isCompleted = isInRange && habit.completedDays[dayIndex];
          final isToday = index == 6; // วันสุดท้ายคือวันนี้

          return GestureDetector(
            onTap: isInRange
                ? () {
                    HapticFeedback.selectionClick();
                    onToggle(dayIndex);
                  }
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday
                        ? habitColor
                        : isDarkMode
                            ? Colors.white54
                            : Colors.black45,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? habitColor : Colors.transparent,
                    border: isInRange
                        ? Border.all(
                            color: isToday
                                ? habitColor
                                : isCompleted
                                    ? habitColor
                                    : isDarkMode
                                        ? Colors.white38
                                        : Colors.black26,
                            width: isToday ? 2 : 1,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : isInRange
                          ? null
                          : Icon(
                              Icons.remove,
                              color:
                                  isDarkMode ? Colors.white30 : Colors.black26,
                              size: 14,
                            ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // แสดงเมนูการทำงาน
  void _showActionsMenu(
      BuildContext context, Color habitColor, bool isDarkMode) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode ? Color(0xFF252525) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionItem(
                context: context,
                title: 'ดูรายละเอียด',
                icon: Icons.visibility_outlined,
                color: habitColor,
                onTap: () {
                  Navigator.pop(context);
                  _showHabitDetails(context);
                },
                isDarkMode: isDarkMode,
              ),
              Divider(
                  height: 1,
                  color: isDarkMode ? Colors.white12 : Colors.black12),
              _buildActionItem(
                context: context,
                title: 'แก้ไขกิจวัตร',
                icon: Icons.edit_outlined,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
                isDarkMode: isDarkMode,
              ),
              Divider(
                  height: 1,
                  color: isDarkMode ? Colors.white12 : Colors.black12),
              _buildActionItem(
                context: context,
                title: 'ลบกิจวัตร',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // สร้างรายการในเมนู
  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // แสดงหน้าจอยืนยันการลบ
  void _confirmDelete(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF252525) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('ยืนยันการลบ'),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบกิจวัตร "${habit.title}"? การกระทำนี้ไม่สามารถเรียกคืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }

  // แสดงรายละเอียดกิจวัตร
  void _showHabitDetails(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final habitColor = habit.color;

    // เช็คว่าวันที่ทำหรือไม่ (ซึ่งตรงนี้จะเป็นการสร้างแผนที่แสดงวันทั้งหมด)
    final completedDaysCount = habit.completedDays.where((done) => done).length;
    final totalDays = habit.completedDays.length;
    final completionRate = totalDays > 0 ? completedDaysCount / totalDays : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pull handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: habitColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        habit.icon,
                        color: habitColor,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (habit.description.isNotEmpty)
                            Text(
                              habit.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            isDarkMode ? Color(0xFF252525) : Color(0xFFF0F0F0),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(24),
                  children: [
                    // สถิติ
                    _buildDetailItem(
                      title: 'สถิติและความคืบหน้า',
                      icon: Icons.insert_chart_outlined,
                      color: habitColor,
                      isDarkMode: isDarkMode,
                      child: Column(
                        children: [
                          // Stats cards
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'ต่อเนื่อง',
                                value: '${habit.streak} วัน',
                                icon: Icons.local_fire_department,
                                color: Colors.orange,
                                isDarkMode: isDarkMode,
                              ),
                              SizedBox(width: 12),
                              _buildStatCard(
                                title: 'สำเร็จ',
                                value: '$completedDaysCount/$totalDays',
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                                isDarkMode: isDarkMode,
                              ),
                              SizedBox(width: 12),
                              _buildStatCard(
                                title: 'ความสำเร็จ',
                                value: '${(completionRate * 100).toInt()}%',
                                icon: Icons.trending_up,
                                color: habitColor,
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Progress bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ความคืบหน้าโดยรวม',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                '${(completionRate * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: habitColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: completionRate,
                              backgroundColor: habitColor.withOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(habitColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ข้อมูลทั่วไป
                    _buildDetailItem(
                      title: 'รายละเอียดกิจวัตร',
                      icon: Icons.info_outline,
                      color: habitColor,
                      isDarkMode: isDarkMode,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            title: 'เริ่มเมื่อ',
                            value: DateFormat('d MMMM yyyy')
                                .format(habit.createdAt),
                            icon: Icons.calendar_today_outlined,
                            color: Colors.blue,
                            isDarkMode: isDarkMode,
                          ),
                          Divider(
                              height: 24,
                              color:
                                  isDarkMode ? Colors.white12 : Colors.black12),
                          _buildInfoRow(
                            title: 'ความถี่',
                            value: _getFrequencyText(),
                            icon: Icons.repeat,
                            color: Colors.purple,
                            isDarkMode: isDarkMode,
                          ),
                          if (habit.notificationEnabled) ...[
                            Divider(
                                height: 24,
                                color: isDarkMode
                                    ? Colors.white12
                                    : Colors.black12),
                            _buildInfoRow(
                              title: 'แจ้งเตือน',
                              value: habit.notificationTime != null
                                  ? '${habit.notificationTime!.hour.toString().padLeft(2, '0')}:${habit.notificationTime!.minute.toString().padLeft(2, '0')} น.'
                                  : 'เปิดใช้งาน',
                              icon: Icons.notifications_active,
                              color: Colors.green,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // จำลองปฏิทิน (เวอร์ชันอนาคต)
                    _buildDetailItem(
                      title: 'ปฏิทินกิจวัตร',
                      icon: Icons.calendar_month,
                      color: habitColor,
                      isDarkMode: isDarkMode,
                      child: Container(
                        height: 150,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 48,
                              color:
                                  isDarkMode ? Colors.white24 : Colors.black12,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ปฏิทินรายเดือนจะมาในเวอร์ชันถัดไป',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // ปุ่มทำงาน
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            onTap: () {
                              Navigator.pop(context);
                              onEdit();
                            },
                            icon: Icons.edit_outlined,
                            text: 'แก้ไข',
                            color: habitColor,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            onTap: () {
                              Navigator.pop(context);
                              _confirmDelete(context);
                            },
                            icon: Icons.delete_outline,
                            text: 'ลบ',
                            color: Colors.red,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ส่วนประกอบของหน้ารายละเอียด
  Widget _buildDetailItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDarkMode ? 0.05 : 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
              height: 1, color: isDarkMode ? Colors.white12 : Colors.black12),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // สร้างการ์ดสถิติ
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // สร้างแถวข้อมูล
  Widget _buildInfoRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // สร้างปุ่มทำงาน
  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String text,
    required Color color,
    required bool isDarkMode,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      icon: Icon(icon, color: color, semanticLabel: 'เปิดหน้าแก้ไขกิจวัตร'),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        elevation: 0,
      ),
    );
  }

  // แปลงความถี่เป็นข้อความ
  String _getFrequencyText() {
    if (habit.frequency.length == 7) {
      return 'ทุกวัน';
    }

    List<String> days = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์'
    ];
    List<String> selectedDays = [];

    for (int index in habit.frequency) {
      selectedDays.add(days[index]);
    }

    return selectedDays.join(', ');
  }

  // รายชื่อวันย้อนหลัง 7 วัน
  List<String> _getLastSevenDays() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return DateFormat('E').format(day);
    });
  }

  // คำนวณอัตราความสำเร็จ
  double _calculateCompletionRate() {
    if (habit.completedDays.isEmpty) return 0.0;

    int completedCount =
        habit.completedDays.where((completed) => completed).length;
    return completedCount / habit.completedDays.length;
  }
}
