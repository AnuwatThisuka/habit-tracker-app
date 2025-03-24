import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit});

  @override
  _HabitFormScreenState createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _enableNotification = false;
  TimeOfDay? _notificationTime;
  bool _isProcessing = false;
  List<int> _selectedDays = [0, 1, 2, 3, 4, 5, 6]; // ค่าเริ่มต้นเลือกทุกวัน
  int _currentStep = 0;

  // ข้อมูลไอคอน
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'directions_run', 'icon': Icons.directions_run, 'label': 'วิ่ง'},
    {
      'name': 'fitness_center',
      'icon': Icons.fitness_center,
      'label': 'ออกกำลังกาย'
    },
    {'name': 'book', 'icon': Icons.book, 'label': 'อ่านหนังสือ'},
    {'name': 'code', 'icon': Icons.code, 'label': 'เขียนโค้ด'},
    {'name': 'water_drop', 'icon': Icons.water_drop, 'label': 'ดื่มน้ำ'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'อาหาร'},
    {'name': 'bed', 'icon': Icons.bed, 'label': 'นอน'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'ช้อปปิ้ง'},
    {'name': 'brush', 'icon': Icons.brush, 'label': 'ศิลปะ'},
    {'name': 'music_note', 'icon': Icons.music_note, 'label': 'ดนตรี'},
    {'name': 'schedule', 'icon': Icons.schedule, 'label': 'กำหนดการ'},
    {
      'name': 'self_improvement',
      'icon': Icons.self_improvement,
      'label': 'สมาธิ'
    },
    {'name': 'medication', 'icon': Icons.medication, 'label': 'ยา'},
    {'name': 'savings', 'icon': Icons.savings, 'label': 'ออมเงิน'},
    {'name': 'spa', 'icon': Icons.spa, 'label': 'พักผ่อน'},
  ];

  // ข้อมูลปัจจุบัน
  String _selectedIconName = 'directions_run';
  IconData _selectedIcon = Icons.directions_run;
  // int _selectedColorValue = Colors.blue.value;
  Color _selectedColor = Colors.blue;

  // สีที่มีให้เลือก
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepOrange,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _titleController = TextEditingController(text: widget.habit!.title);
      _descriptionController =
          TextEditingController(text: widget.habit!.description);
      _enableNotification = widget.habit!.notificationEnabled;
      _notificationTime = widget.habit!.notificationTime;
      // _selectedColorValue = widget.habit!.color.value;
      _selectedColor = Color(widget.habit!.color.value);

      // แก้ไขตรงนี้ - แยกระหว่าง String กับ IconData
      if (widget.habit!.icon is String) {
        _selectedIconName = widget.habit!.icon as String;
        // หา IconData ที่สอดคล้องกับชื่อ
        final iconData = _getIconDataFromName(_selectedIconName);
        _selectedIcon = iconData;
      } else {
        _selectedIcon = widget.habit!.icon;
        // หาชื่อที่สอดคล้องกับ IconData
        final iconItem = _availableIcons.firstWhere(
          (item) => item['icon'] == _selectedIcon,
          orElse: () => _availableIcons.first,
        );
        _selectedIconName = iconItem['name'];
      }

      _selectedDays = widget.habit!.frequency;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  IconData _getIconDataFromName(String name) {
    final iconItem = _availableIcons.firstWhere(
      (item) => item['name'] == name,
      orElse: () => _availableIcons.first,
    );
    return iconItem['icon'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _selectedColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
        _enableNotification = true;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final habitService = Provider.of<HabitService>(context, listen: false);
        final notificationService = NotificationService();

        // สร้างหรืออัปเดตกิจวัตร
        if (widget.habit == null) {
          // สร้างกิจวัตรใหม่
          final newHabit = Habit(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text,
            description: _descriptionController.text,
            createdAt: DateTime.now(),
            color: _selectedColor,
            icon: _selectedIcon,
            completedDays: [],
            streak: 0,
            notificationEnabled: _enableNotification,
            notificationTime: _enableNotification ? _notificationTime : null,
            frequency: _selectedDays,
          );

          await habitService.addHabit(newHabit);

          // ตั้งค่าการแจ้งเตือน
          if (_enableNotification && _notificationTime != null) {
            await notificationService.scheduleHabitNotification(
              newHabit.id,
              newHabit.title,
              newHabit.description,
              _notificationTime!,
            );
          }
        } else {
          // อัปเดตกิจวัตรที่มีอยู่
          final updatedHabit = Habit(
            id: widget.habit!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            createdAt: widget.habit!.createdAt,
            color: _selectedColor,
            icon: _selectedIcon,
            completedDays: widget.habit!.completedDays,
            streak: widget.habit!.streak,
            notificationEnabled: _enableNotification,
            notificationTime: _enableNotification ? _notificationTime : null,
            frequency: _selectedDays,
          );

          await habitService.updateHabit(updatedHabit);

          // อัปเดตการแจ้งเตือน
          await notificationService.cancelNotification(widget.habit!.id);
          if (_enableNotification && _notificationTime != null) {
            await notificationService.scheduleHabitNotification(
              updatedHabit.id,
              updatedHabit.title,
              updatedHabit.description,
              _notificationTime!,
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.habit == null
                  ? 'สร้างกิจวัตรสำเร็จ'
                  : 'อัปเดตกิจวัตรสำเร็จ'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: _selectedColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.habit != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขกิจวัตร' : 'สร้างกิจวัตรใหม่'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_titleController.text.isNotEmpty ||
                _descriptionController.text.isNotEmpty) {
              _showExitDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: colorScheme.copyWith(
                      primary: _selectedColor,
                      secondary: _selectedColor,
                    ),
                  ),
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _currentStep,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    physics: BouncingScrollPhysics(),
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        setState(() {
                          _currentStep += 1;
                        });
                      } else {
                        _saveHabit();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep -= 1;
                        });
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 18,
                          children: [
                            if (_currentStep > 0)
                              ElevatedButton.icon(
                                onPressed: details.onStepCancel,
                                icon: Icon(Icons.arrow_back, size: 18),
                                label: Text('ย้อนกลับ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Color(0xFF2A2A2A)
                                      : Colors.grey[200],
                                  foregroundColor: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              )
                            else
                              SizedBox.shrink(),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing
                                    ? null
                                    : details.onStepContinue,
                                icon: _currentStep < 2
                                    ? Icon(Icons.arrow_forward,
                                        size: 18,
                                        color: _isProcessing
                                            ? Colors.grey
                                            : Colors.white)
                                    : Icon(Icons.check,
                                        size: 18,
                                        color: _isProcessing
                                            ? Colors.grey
                                            : Colors.white),
                                label: Text(
                                    _currentStep < 2
                                        ? 'ถัดไป'
                                        : (isEditing
                                            ? 'บันทึกการเปลี่ยนแปลง'
                                            : 'สร้างกิจวัตร'),
                                    style: TextStyle(
                                        color: _isProcessing
                                            ? Colors.grey
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedColor,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // ขั้นที่ 1: ข้อมูลพื้นฐาน
                      Step(
                        title: Text('ข้อมูล'),
                        content: _buildBasicInfoStep(isDarkMode, colorScheme),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                      ),

                      // ขั้นที่ 2: ความถี่และรูปแบบ
                      Step(
                        title: Text('รูปแบบ'),
                        content: _buildStyleStep(isDarkMode, colorScheme),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                      ),

                      // ขั้นที่ 3: การแจ้งเตือน
                      Step(
                        title: Text('แจ้งเตือน'),
                        content:
                            _buildNotificationStep(isDarkMode, colorScheme),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                    ],
                  ),
                ),

                // แสดง indicator เมื่อกำลังประมวลผล
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: _selectedColor),
                            SizedBox(height: 16),
                            Text(
                              isEditing
                                  ? 'กำลังบันทึกกิจวัตร...'
                                  : 'กำลังสร้างกิจวัตรใหม่...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ขั้นที่ 1: ข้อมูลพื้นฐาน
  Widget _buildBasicInfoStep(bool isDarkMode, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ไอคอนใหญ่ที่ด้านบน
        Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedIcon,
              color: _selectedColor,
              size: 60,
            ),
          ),
        ),
        SizedBox(height: 24),

        // ชื่อกิจวัตร
        _buildSectionTitle('ชื่อกิจวัตร', isRequired: true),
        SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'เช่น วิ่งทุกเช้า, อ่านหนังสือ',
            prefixIcon: Icon(_selectedIcon, color: _selectedColor),
            filled: true,
            fillColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _selectedColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาใส่ชื่อกิจวัตร';
            }
            return null;
          },
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20),

        // รายละเอียด
        _buildSectionTitle('รายละเอียด (ไม่บังคับ)'),
        SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'รายละเอียดเพิ่มเติมเกี่ยวกับกิจวัตรนี้',
            filled: true,
            fillColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _selectedColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          maxLines: 3,
          style: TextStyle(
            fontSize: 15,
          ),
        ),
        SizedBox(height: 20),

        // ความถี่
        _buildFrequencySection(isDarkMode),
      ],
    );
  }

  // ขั้นที่ 2: ความถี่และรูปแบบ
  Widget _buildStyleStep(bool isDarkMode, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // เลือกไอคอน
        _buildSectionTitle('เลือกไอคอน'),
        SizedBox(height: 8),
        _buildIconSelector(isDarkMode),
        SizedBox(height: 24),

        // เลือกสี
        _buildSectionTitle('เลือกสีกิจวัตร'),
        SizedBox(height: 8),
        _buildColorSelector(isDarkMode),
        SizedBox(height: 20),

        // ตัวอย่างที่จะแสดงในรายการ
        _buildSectionTitle('ตัวอย่างที่จะแสดงในรายการ'),
        SizedBox(height: 12),
        _buildHabitPreview(isDarkMode),
      ],
    );
  }

  // ขั้นที่ 3: การแจ้งเตือน
  Widget _buildNotificationStep(bool isDarkMode, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ตั้งค่าการแจ้งเตือน
        _buildSectionTitle('ตั้งค่าการแจ้งเตือน'),
        SizedBox(height: 16),

        // สวิตช์เปิด/ปิดการแจ้งเตือน
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: Text(
              'เปิดการแจ้งเตือน',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'รับการแจ้งเตือนเมื่อถึงเวลาทำกิจวัตร',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            value: _enableNotification,
            activeColor: _selectedColor,
            inactiveTrackColor:
                isDarkMode ? Colors.grey[700] : Colors.grey[300],
            onChanged: (bool value) {
              setState(() {
                _enableNotification = value;
              });
              HapticFeedback.lightImpact();
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _enableNotification
                    ? _selectedColor.withOpacity(0.2)
                    : isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: _enableNotification
                    ? _selectedColor
                    : isDarkMode
                        ? Colors.grey[500]
                        : Colors.grey[500],
                size: 22,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        if (_enableNotification) ...[
          SizedBox(height: 20),

          // เลือกเวลาแจ้งเตือน
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              onTap: () => _selectTime(context),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: _selectedColor,
                  size: 22,
                ),
              ),
              title: Text(
                'เวลาแจ้งเตือน',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _notificationTime != null
                    ? '${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}'
                    : 'เลือกเวลา',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],

        SizedBox(height: 24),

        // ข้อความสรุป
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: _selectedColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'การทำกิจวัตรอย่างสม่ำเสมอจะช่วยสร้างนิสัยที่ดีและเพิ่มสถิติความสำเร็จของคุณ',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(bool isDarkMode) {
    final List<String> days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ความถี่', isRequired: true),
        SizedBox(height: 8),
        Text(
          'เลือกวันที่ต้องการทำกิจวัตรนี้',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        SizedBox(height: 16),

        // วันในสัปดาห์
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final bool isSelected = _selectedDays.contains(index);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      // ไม่ให้เลือกวันสุดท้ายออก (ต้องมีอย่างน้อย 1 วัน)
                      if (_selectedDays.length > 1) {
                        _selectedDays.remove(index);
                      }
                    } else {
                      _selectedDays.add(index);
                      _selectedDays.sort(); // เรียงลำดับใหม่
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? _selectedColor
                          : isDarkMode
                              ? Colors.white38
                              : Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white
                                : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        SizedBox(height: 16),

        // ปุ่มลัด
        Row(
          children: [
            Expanded(
              child: _buildQuickFrequencyButton(
                  'ทุกวัน', [0, 1, 2, 3, 4, 5, 6], isDarkMode),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildQuickFrequencyButton(
                  'วันธรรมดา', [0, 1, 2, 3, 4], isDarkMode),
            ),
            SizedBox(width: 8),
            Expanded(
              child:
                  _buildQuickFrequencyButton('สุดสัปดาห์', [5, 6], isDarkMode),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFrequencyButton(
      String label, List<int> days, bool isDarkMode) {
    final bool isActive = _selectedDays.length == days.length &&
        days.every((day) => _selectedDays.contains(day));

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedDays = List.from(days);
        });
        HapticFeedback.mediumImpact();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? _selectedColor.withOpacity(0.2)
            : isDarkMode
                ? Color(0xFF2A2A2A)
                : Colors.grey[200],
        foregroundColor: isActive
            ? _selectedColor
            : isDarkMode
                ? Colors.white70
                : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildIconSelector(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = _availableIcons[index]['icon'] as IconData;
              final iconName = _availableIcons[index]['name'] as String;
              final isSelected = _selectedIconName == iconName;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = iconData;
                    _selectedIconName = iconName;
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withOpacity(0.2)
                        : isDarkMode
                            ? Color(0xFF252525)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: isSelected
                          ? _selectedColor
                          : isDarkMode
                              ? Colors.white60
                              : Colors.black54,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _availableColors.map((color) {
              final isSelected = _selectedColor.value == color.value;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                    // _selectedColorValue = color.value;
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPreview(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ไอคอนกิจวัตร
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedIcon,
              color: _selectedColor,
              size: 22,
            ),
          ),
          SizedBox(width: 16),

          // ข้อมูลกิจวัตร
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'ชื่อกิจวัตรของคุณ'
                      : _titleController.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_descriptionController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      _descriptionController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // สถานะเสร็จสิ้น
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor,
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  void _showExitDialog() {
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
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('ต้องการออกโดยไม่บันทึก?'),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการออกโดยไม่บันทึกการเปลี่ยนแปลง?',
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
              Navigator.pop(context); // ปิด dialog
              Navigator.pop(context); // กลับไปหน้าก่อนหน้า
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('ออกโดยไม่บันทึก'),
          ),
        ],
      ),
    );
  }
}
