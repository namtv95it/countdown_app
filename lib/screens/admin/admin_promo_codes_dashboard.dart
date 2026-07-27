import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_edit_promo_code_screen.dart';

class AdminPromoCodesDashboard extends StatefulWidget {
  const AdminPromoCodesDashboard({super.key});

  @override
  State<AdminPromoCodesDashboard> createState() => _AdminPromoCodesDashboardState();
}

class _AdminPromoCodesDashboardState extends State<AdminPromoCodesDashboard> {
  String _searchQuery = '';
  String _selectedType = 'all'; // 'all', 'premium', 'giftEffect', 'testMode', 'admin'

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'premium', 'label': 'Premium'},
    {'value': 'giftEffect', 'label': 'Hiệu ứng (Gift)'},
    {'value': 'testMode', 'label': 'Test Mode'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  Future<void> _confirmDelete(String docId, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc muốn xóa promo code "$code"?\nThao tác này không thể hoàn tác.',
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: GoogleFonts.quicksand(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('promo_codes').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa promo code thành công!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Quản lý Promo Codes',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toUpperCase()),
              style: GoogleFonts.quicksand(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã code...',
                hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Type filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _typeOptions.length,
              itemBuilder: (context, idx) {
                final opt = _typeOptions[idx];
                final isSelected = _selectedType == opt['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      opt['label']!,
                      style: GoogleFonts.quicksand(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedType = opt['value']!);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Promo Codes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('promo_codes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Đã xảy ra lỗi: ${snapshot.error}', style: GoogleFonts.quicksand(color: Colors.red)),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                }

                final docs = snapshot.data?.docs ?? [];
                var filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = (data['code'] ?? '').toString().toUpperCase();
                  final type = (data['type'] ?? '').toString();

                  final matchesSearch = code.contains(_searchQuery);
                  final matchesType = _selectedType == 'all' || type == _selectedType;

                  return matchesSearch && matchesType;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy promo code nào.',
                      style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final code = data['code'] ?? '';
                    final type = data['type'] ?? 'premium';
                    final desc = data['description'] ?? 'Quà tặng từ server';
                    final maxUsage = data['maxUsage'];
                    final usedCount = data['usedCount'] ?? 0;
                    final durationDays = data['durationDays'];
                    final expirationDate = data['expirationDate'] != null
                        ? (data['expirationDate'] as Timestamp).toDate()
                        : null;
                    final unlockedEffectId = data['unlockedEffectId'];

                    // Color based on type
                    Color typeColor = const Color(0xFF10B981); // premium
                    if (type == 'giftEffect') {
                      typeColor = const Color(0xFFEC4899);
                    } else if (type == 'testMode') {
                      typeColor = const Color(0xFFF59E0B);
                    } else if (type == 'admin') {
                      typeColor = const Color(0xFFEF4444);
                    }

                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  code,
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
                                    style: GoogleFonts.quicksand(
                                      color: typeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['descriptionEn'] != null && data['descriptionEn'].toString().isNotEmpty
                                  ? '$desc (${data['descriptionEn']})'
                                  : desc,
                              style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 8),
                            // Details: Usages, Expirations, Duration, Effects
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildDetailBadge(
                                  Icons.people,
                                  'Lượt dùng: $usedCount / ${maxUsage ?? '∞'}',
                                ),
                                if (durationDays != null)
                                  _buildDetailBadge(
                                    Icons.timer_outlined,
                                    'Thời hạn: $durationDays ngày',
                                  ),
                                if (expirationDate != null)
                                  _buildDetailBadge(
                                    Icons.event_busy,
                                    'Hạn nhập: ${DateFormat('dd/MM/yyyy HH:mm').format(expirationDate.toLocal())}',
                                  ),
                                if (type == 'giftEffect' && unlockedEffectId != null)
                                  _buildDetailBadge(
                                    Icons.auto_awesome,
                                    'Hiệu ứng: $unlockedEffectId',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminEditPromoCodeScreen(
                                          docId: doc.id,
                                          initialData: data,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                  label: Text('Sửa', style: GoogleFonts.quicksand(color: Colors.blueAccent)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(doc.id, code),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  label: Text('Xóa', style: GoogleFonts.quicksand(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEditPromoCodeScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDetailBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
