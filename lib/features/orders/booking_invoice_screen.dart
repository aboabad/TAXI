import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class BookingInvoiceScreen extends StatelessWidget {
  final String restaurantName;
  final String bookingId;
  final int peopleCount;
  final DateTime bookingDate;
  final String status;
  final double totalPrice;

  const BookingInvoiceScreen({
    super.key,
    required this.restaurantName,
    required this.bookingId,
    required this.peopleCount,
    required this.bookingDate,
    required this.status,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة الحجز'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.receipt_long,
              size: 80,
              color: AppTheme.primaryColor,
            ),

            const SizedBox(height: 16),

            const Text(
              'تم إرسال الحجز بنجاح',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'تفاصيل الحجز',
              style: TextStyle(
                color: AppTheme.subTextColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _invoiceRow('اسم المطعم', restaurantName),
                    const Divider(height: 30),

                    _invoiceRow(
                      'رقم الحجز',
                      bookingId.isEmpty ? 'سيتم تحديده' : bookingId,
                    ),
                    const Divider(height: 30),

                    _invoiceRow(
                      'عدد الأشخاص',
                      '$peopleCount أشخاص',
                    ),
                    const Divider(height: 30),

                    _invoiceRow(
                      'تاريخ الحجز',
                      _formatDate(bookingDate),
                    ),
                    const Divider(height: 30),

                    _invoiceRow('حالة الحجز', status),
                    const Divider(height: 30),

                    _invoiceRow(
                      'الإجمالي',
                      '${totalPrice.toStringAsFixed(2)} د.أ',
                      valueColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة إلى المطعم'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _invoiceRow(
      String title,
      String value, {
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.subTextColor,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year - $hour:$minute';
  }
}