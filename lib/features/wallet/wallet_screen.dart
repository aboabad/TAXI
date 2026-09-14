import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'الرصيد الحالي',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1,250 د.أ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Actions
            Row(
              children: [
                Expanded(child: actionButton(Icons.add, 'شحن الرصيد', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: actionButton(Icons.send, 'إرسال', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: actionButton(Icons.call_received, 'سحب', Colors.orange)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'العمليات الأخيرة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Transaction List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    child: Icon(
                      index % 2 == 0 ? Icons.restaurant : Icons.account_balance_wallet,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(index % 2 == 0 ? 'مطعم القصر الكلاسيكي' : 'شحن محفظة'),
                  subtitle: Text('20 أغسطس 2026'),
                  trailing: Text(
                    index % 2 == 0 ? '- 150 د.أ' : '+ 500 د.أ',
                    style: TextStyle(
                      color: index % 2 == 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
