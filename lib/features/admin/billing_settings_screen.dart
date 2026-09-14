import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/models/app_settings_model.dart';

class BillingSettingsScreen extends StatefulWidget {
const BillingSettingsScreen({super.key});

@override
State<BillingSettingsScreen> createState() => _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends State<BillingSettingsScreen> {
final _formKey = GlobalKey<FormState>();

final _restaurantCommController = TextEditingController();
final _driverCommController = TextEditingController();
final _deliveryRateController = TextEditingController();
final _minDistController = TextEditingController();

bool _isLoading = true;
bool _isSaving = false;

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

DocumentReference<Map<String, dynamic>> get _settingsRef {
return _firestore.collection('app_settings').doc('billing');
}

@override
void initState() {
super.initState();
_loadSettings();
}

Future<void> _loadSettings() async {
try {
final snapshot = await _settingsRef.get();

AppSettingsModel settings;

if (snapshot.exists && snapshot.data() != null) {
settings = AppSettingsModel.fromMap(snapshot.data()!);
} else {
settings = AppSettingsModel();

await _settingsRef.set(settings.toMap());
}

if (!mounted) return;

setState(() {
// الموديل يخزن 10% كـ 0.10
// لكن المستخدم يرى 10
_restaurantCommController.text =
(settings.restaurantCommissionRate * 100).toString();

_driverCommController.text =
settings.driverCommissionPerDinar.toString();

_deliveryRateController.text =
settings.deliveryRatePerKm.toString();

_minDistController.text =
settings.minDeliveryDistance.toString();

_isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_isLoading = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'حدث خطأ أثناء تحميل الإعدادات: $e',
),
backgroundColor: Colors.red,
),
);
}
}

Future<void> _saveSettings() async {
if (!_formKey.currentState!.validate()) {
return;
}

final restaurantPercentage =
double.tryParse(_restaurantCommController.text.trim());

final driverCommission =
double.tryParse(_driverCommController.text.trim());

final deliveryRate =
double.tryParse(_deliveryRateController.text.trim());

final minDistance =
double.tryParse(_minDistController.text.trim());

if (restaurantPercentage == null ||
driverCommission == null ||
deliveryRate == null ||
minDistance == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('يرجى إدخال قيم صحيحة'),
backgroundColor: Colors.red,
),
);
return;
}

setState(() {
_isSaving = true;
});

try {
final settings = AppSettingsModel(
// مثال:
// 10% من واجهة المستخدم تصبح 0.10 في قاعدة البيانات
restaurantCommissionRate: restaurantPercentage / 100,
driverCommissionPerDinar: driverCommission,
deliveryRatePerKm: deliveryRate,
minDeliveryDistance: minDistance,
);

await _settingsRef.set(
settings.toMap(),
SetOptions(merge: true),
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تم حفظ الإعدادات بنجاح'),
backgroundColor: AppTheme.primaryColor,
),
);

Navigator.pop(context, settings);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'حدث خطأ أثناء حفظ الإعدادات: $e',
),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
_isSaving = false;
});
}
}
}

@override
void dispose() {
_restaurantCommController.dispose();
_driverCommController.dispose();
_deliveryRateController.dispose();
_minDistController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'إعدادات الحسابات والعمولات',
),
centerTitle: true,
),
body: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : SingleChildScrollView(
padding: const EdgeInsets.all(24.0),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Text(
'إعدادات العمولات والأسعار (دينار أردني)',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: AppTheme.primaryColor,
),
textAlign: TextAlign.center,
),

const SizedBox(height: 24),

_buildSettingField(
controller: _restaurantCommController,
label: 'نسبة الإدارة من المطعم (%)',
suffix: '%',
),

_buildSettingField(
controller: _driverCommController,
label: 'عمولة الإدارة من السائق (لكل 1 دينار)',
suffix: 'د.أ',
),

_buildSettingField(
controller: _deliveryRateController,
label: 'سعر التوصيل لكل 1 كم',
suffix: 'د.أ',
),

_buildSettingField(
controller: _minDistController,
label: 'أقل مسافة توصيل محسوبة',
suffix: 'كم',
),

const SizedBox(height: 20),

ElevatedButton(
onPressed: _isSaving ? null : _saveSettings,
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(
vertical: 14,
),
),
child: _isSaving
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text(
'حفظ التغييرات',
style: TextStyle(
fontSize: 16,
),
),
),

const SizedBox(height: 16),

const Text(
'* سيتم تطبيق هذه النسب على جميع العمليات الجديدة تلقائياً.',
style: TextStyle(
color: Colors.grey,
fontSize: 12,
),
textAlign: TextAlign.center,
),
],
),
),
),
);
}

Widget _buildSettingField({
required TextEditingController controller,
required String label,
required String suffix,
}) {
return Padding(
padding: const EdgeInsets.only(
bottom: 20,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
fontWeight: FontWeight.w500,
),
),

const SizedBox(height: 8),

TextFormField(
controller: controller,
keyboardType: const TextInputType.numberWithOptions(
decimal: true,
),
decoration: InputDecoration(
suffixText: suffix,
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 12,
),
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'هذا الحقل مطلوب';
}

final number = double.tryParse(
value.trim(),
);

if (number == null) {
return 'يرجى إدخال رقم صحيح';
}

if (number < 0) {
return 'لا يمكن أن تكون القيمة سالبة';
}

if (suffix == '%' && number > 100) {
return 'النسبة يجب أن تكون بين 0 و100';
}

return null;
},
),
],
),
);
}
}
