import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<SettingsService>(
              builder: (context, settings, child) {
                return CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 150,
                      backgroundColor:
                          isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      elevation: 0,
                      stretch: true,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness:
                            isDarkMode ? Brightness.light : Brightness.dark,
                      ),
                      leading: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? Color(0xFF2C2C2C)
                                : Color(0xFFF0F1F2),
                          ),
                          child: Icon(Icons.arrow_back, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      actions: [
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode
                                  ? Color(0xFF2C2C2C)
                                  : Color(0xFFF0F1F2),
                            ),
                            child: Icon(Icons.info_outline, size: 20),
                          ),
                          onPressed: () {
                            _showAboutAppSheet(
                                context, isDarkMode, primaryColor, settings);
                          },
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          "การตั้งค่า",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -50,
                                top: -20,
                                child: CircleAvatar(
                                  radius: 100,
                                  backgroundColor:
                                      primaryColor.withOpacity(0.05),
                                ),
                              ),
                              Positioned(
                                left: -30,
                                bottom: -30,
                                child: CircleAvatar(
                                  radius: 80,
                                  backgroundColor:
                                      primaryColor.withOpacity(0.05),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // User Profile Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDarkMode
                                  ? Color(0xFF2C2C2C)
                                  : Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryColor,
                                        primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ผู้ใช้",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "แอปติดตามกิจวัตร",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Color(0xFF2C2C2C)
                                        : Color(0xFFF0F1F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.refresh_rounded),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('รีเซ็ตการตั้งค่า'),
                                          content: Text(
                                              'คุณแน่ใจหรือไม่ว่าต้องการรีเซ็ตการตั้งค่าทั้งหมดเป็นค่าเริ่มต้น?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('ยกเลิก'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                settings.resetToDefaults();
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'รีเซ็ตการตั้งค่าเรียบร้อยแล้ว'),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text('รีเซ็ต'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'รีเซ็ตการตั้งค่าทั้งหมด',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Settings Sections
                    SliverToBoxAdapter(
                      child: _buildSettingsContent(
                          context, settings, isDarkMode, primaryColor),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsService settings,
      bool isDarkMode, Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Settings
          _buildSectionHeader('การแสดงผล', Icons.palette_outlined, isDarkMode),
          _buildSettingsCard(
            isDarkMode: isDarkMode,
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'โหมดมืด',
                  subtitle: settings.isDarkMode == true
                      ? 'เปิดใช้งานแล้ว'
                      : settings.isDarkMode == false
                          ? 'ปิดใช้งาน'
                          : 'ใช้ค่าตั้งค่าระบบ',
                  icon: settings.isDarkMode == true
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  value: settings.isDarkMode == true,
                  onChanged: (value) {
                    settings.setDarkMode(value ? true : false);
                    HapticFeedback.lightImpact();
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'ใช้ค่าเริ่มต้นของระบบ',
                  subtitle: 'ปรับโหมดตามการตั้งค่าของอุปกรณ์',
                  icon: Icons.phonelink_setup,
                  trailing: Radio<bool?>(
                    value: null,
                    groupValue: settings.isDarkMode,
                    onChanged: (value) {
                      settings.setDarkMode(null);
                      HapticFeedback.lightImpact();
                    },
                    activeColor: primaryColor,
                  ),
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'ธีมสี',
                  subtitle: 'ปรับสีหลักของแอปพลิเคชัน',
                  icon: Icons.color_lens_outlined,
                  trailing: _buildColorSelection(primaryColor),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Show color picker
                    _showColorPickerSheet(
                        context, settings, isDarkMode, primaryColor);
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          // Notifications
          SizedBox(height: 24),
          _buildSectionHeader(
              'การแจ้งเตือน', Icons.notifications_outlined, isDarkMode),
          _buildSettingsCard(
            isDarkMode: isDarkMode,
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'เปิดการแจ้งเตือน',
                  subtitle: 'เปิดหรือปิดการแจ้งเตือนสำหรับแอปทั้งหมด',
                  icon: Icons.notifications_active,
                  value: settings.notificationsEnabled ?? true,
                  onChanged: (value) {
                    settings.setNotificationsEnabled(value);
                    HapticFeedback.lightImpact();
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'เวลาแจ้งเตือนเริ่มต้น',
                  subtitle: settings.defaultReminderTime != null
                      ? 'ตั้งเป็น ${settings.defaultReminderTime!.format(context)}'
                      : 'ไม่ได้ตั้งค่า',
                  icon: Icons.access_time,
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final TimeOfDay? selectedTime = await showTimePicker(
                      context: context,
                      initialTime: settings.defaultReminderTime ??
                          TimeOfDay(hour: 20, minute: 0),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: primaryColor,
                                ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selectedTime != null) {
                      settings.setDefaultReminderTime(selectedTime);
                    }
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'ทดสอบการแจ้งเตือน',
                  subtitle: 'ส่งการแจ้งเตือนทดสอบเพื่อตรวจสอบการทำงาน',
                  icon: Icons.notification_important_outlined,
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ทดสอบ',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    NotificationService().showTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ส่งการแจ้งเตือนทดสอบแล้ว'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          // Other Settings
          SizedBox(height: 24),
          _buildSectionHeader('เพิ่มเติม', Icons.more_horiz, isDarkMode),
          _buildSettingsCard(
            isDarkMode: isDarkMode,
            child: Column(
              children: [
                _buildListTile(
                  title: 'แชร์แอป',
                  subtitle: 'แนะนำแอปให้กับเพื่อน',
                  icon: Icons.share_outlined,
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Share.share(
                      'ลองใช้แอปติดตามกิจวัตรนี้สิ! ช่วยให้ฉันสร้างนิสัยที่ดีได้ง่ายขึ้น',
                    );
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'ติดต่อผู้พัฒนา',
                  subtitle: 'แจ้งปัญหาหรือให้คำแนะนำ',
                  icon: Icons.email_outlined,
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'anuwat.thisuka@gmail.com',
                      query: 'subject=คำติชมแอปติดตามกิจวัตร&body=สวัสดี,',
                    );
                    try {
                      await launchUrl(emailLaunchUri);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ไม่สามารถเปิดแอปอีเมลได้'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
                Divider(height: 1, indent: 56, endIndent: 0),
                _buildListTile(
                  title: 'ให้คะแนนแอป',
                  subtitle: 'ให้คะแนนบน App Store',
                  icon: Icons.star_border_rounded,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < 5
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: index < 5
                            ? Colors.amber
                            : isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('จะเพิ่มฟีเจอร์นี้ในรุ่นถัดไป'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  primaryColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          // Version Info
          SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text(
                  'เวอร์ชัน $_appVersion',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '© 2025 อนุวัฒน์ ทีสุกะ • สงวนลิขสิทธิ์',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      child: child,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required Color primaryColor,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDarkMode ? Colors.grey[400] : primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryColor,
    required bool isDarkMode,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDarkMode ? Colors.grey[400] : primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
    );
  }

  Widget _buildColorSelection(Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorCircle(Colors.blue, isSelected: primaryColor == Colors.blue),
        SizedBox(width: 8),
        _buildColorCircle(Colors.purple,
            isSelected: primaryColor == Colors.purple),
        SizedBox(width: 8),
        _buildColorCircle(Colors.green,
            isSelected: primaryColor == Colors.green),
        SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color, {bool isSelected = false}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }

  void _showColorPickerSheet(
    BuildContext context,
    SettingsService settings,
    bool isDarkMode,
    Color primaryColor,
  ) {
    // สร้างรายการสีที่ใช้ได้
    List<Color> colorOptions = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.deepPurple,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 20),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'เลือกธีมสี',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(thickness: 1),

              // Color Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      Color color = colorOptions[index];
                      bool isSelected = color.value == primaryColor.value;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          // settings.setPrimaryColor(color);
                          Navigator.pop(context);

                          // Show the feature will be added in a future version
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('จะเพิ่มฟีเจอร์นี้ในรุ่นถัดไป'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: isSelected ? 8 : 4,
                                spreadRadius: isSelected ? 2 : 0,
                              ),
                            ],
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: EdgeInsets.all(20),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'เสร็จสิ้น',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutAppSheet(
    BuildContext context,
    bool isDarkMode,
    Color primaryColor,
    SettingsService settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // App Icon
              Container(
                margin: EdgeInsets.only(top: 20),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              // App Name
              SizedBox(height: 16),
              Text(
                'แอปติดตามกิจวัตร',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Version
              SizedBox(height: 6),
              Text(
                'เวอร์ชัน $_appVersion',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              // Description
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'แอปติดตามกิจวัตรช่วยให้คุณสร้างและรักษากิจวัตรประจำวันได้อย่างมีประสิทธิภาพ ช่วยให้สร้างนิสัยที่ดีได้ง่ายขึ้นด้วยการติดตามความก้าวหน้า',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),

              // Features
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureItem(
                    icon: Icons.track_changes_outlined,
                    label: 'ติดตาม',
                    primaryColor: primaryColor,
                  ),
                  SizedBox(width: 36),
                  _buildFeatureItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'แจ้งเตือน',
                    primaryColor: primaryColor,
                  ),
                  SizedBox(width: 36),
                  _buildFeatureItem(
                    icon: Icons.insights_outlined,
                    label: 'วิเคราะห์',
                    primaryColor: primaryColor,
                  ),
                ],
              ),

              Spacer(),

              // Copyright
              Text(
                '© 2025 อนุวัฒน์ ทีสุกะ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                ),
              ),

              // Contact
              SizedBox(height: 8),
              Text(
                'anuwat.thisuka@gmail.com',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),

              // Close Button
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.all(20),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'ปิด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
