import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final List<String> _categories = ['مطاعم', 'كافيهات', 'سريع', 'بيتزا', 'حلويات'];
  final TextEditingController _categoryController = TextEditingController();

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _categories.add(_categoryController.text);
        _categoryController.clear();
      });
      Navigator.pop(context);
    }
  }

  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفئات'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.category, color: Colors.white, size: 20),
              ),
              title: Text(_categories[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteCategory(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(hintText: 'اسم الفئة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addCategory,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
