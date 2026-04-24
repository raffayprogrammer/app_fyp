import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/sos_service.dart';

class ManageContactsScreen extends StatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  State<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends State<ManageContactsScreen> {
  final SosService _sosService = SosService();
  List<Map<String, String>> _contacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  
  Future<void> _loadContacts() async {
    await _sosService.loadContacts();
    setState(() {
      _contacts = List.from(_sosService.trustedContacts);
    });
  }
  
  Future<void> _addContact() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Trusted Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Iconsax.user),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Iconsax.call),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await _sosService.addContact(nameController.text, phoneController.text);
                await _loadContacts();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteContact(int index) async {
    await _sosService.removeContact(index);
    await _loadContacts();
  }
  
  void _reorderContacts(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _contacts.removeAt(oldIndex);
      _contacts.insert(newIndex, item);
    });
    _sosService.reorderContacts(oldIndex, newIndex);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage SOS Contacts'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: _addContact,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        onReorder: _reorderContacts,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return Card(
            key: ValueKey(index),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  contact['name']![0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                contact['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(contact['phone']!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_handle, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}