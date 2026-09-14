import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _targetGroup = 'الكل';
  bool _isLoading = false;

  final List<String> _groups = ['الكل', 'المستخدمين', 'السائقين', 'المطاعم'];

  void _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API call to Firebase Cloud Messaging via Backend/Cloud Function
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الإشعار بنجاح إلى $_targetGroup'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعار جماعي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر الفئة المستهدفة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetGroup,
                  isExpanded: true,
                  items: _groups.map((String group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _targetGroup = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الإشعار',
                hintText: 'مثلاً: عرض خاص اليوم!',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                hintText: 'اكتب تفاصيل الإشعار هنا...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendNotification,
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
              label: const Text('إرسال الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
