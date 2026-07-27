import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/anniversary.dart';
import '../data/preset_holidays.dart';

class PresetHolidaysScreen extends StatefulWidget {
  final List<Anniversary> existingEvents;

  const PresetHolidaysScreen({
    super.key,
    this.existingEvents = const [],
  });

  @override
  State<PresetHolidaysScreen> createState() => _PresetHolidaysScreenState();
}

class _PresetHolidaysScreenState extends State<PresetHolidaysScreen> {
  final Set<PresetHoliday> _selectedHolidays = {};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, currentLang, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              t('popular_holidays'),
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ActionChip(
                      label: Text(t('select_vn')),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.quicksand(color: Colors.white, fontSize: 13),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () {
                        setState(() {
                          for (var h in PresetHolidays.all.where((h) => h.badge == 'vn')) {
                            if (!widget.existingEvents.any((e) => e.title == t(h.title))) {
                              _selectedHolidays.add(h);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(t('select_intl')),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.quicksand(color: Colors.white, fontSize: 13),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () {
                        setState(() {
                          for (var h in PresetHolidays.all.where((h) => h.badge == 'intl')) {
                            if (!widget.existingEvents.any((e) => e.title == t(h.title))) {
                              _selectedHolidays.add(h);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(t('deselect_all')),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: GoogleFonts.quicksand(color: Colors.white70, fontSize: 13),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () {
                        setState(() {
                          _selectedHolidays.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildPresetSection(t('all_holidays'), PresetHolidays.all),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Bottom Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('selected_count', params: {'count': _selectedHolidays.length.toString()}),
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectedHolidays.isEmpty
                          ? null
                          : () {
                              final now = DateTime.now();
                              final List<Anniversary> resultList = [];

                              for (var h in _selectedHolidays) {
                                final DateTime storeDate = DateTime(now.year, h.month, h.day);
                                resultList.add(
                                  Anniversary(
                                    id: '${DateTime.now().microsecondsSinceEpoch}${resultList.length}',
                                    title: t(h.title),
                                    date: storeDate,
                                    emoji: h.emoji,
                                    colorValue: h.colorValue,
                                    isYearly: true,
                                    isLunar: h.isLunar,
                                    note: '',
                                    categoryId: h.categoryId,
                                  ),
                                );
                              }
                              Navigator.pop(context, resultList);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        t('add_count_days', params: {'count': _selectedHolidays.length.toString()}),
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _selectedHolidays.isEmpty ? Colors.white38 : Colors.white,
                        ),
                      ),
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

  Widget _buildPresetSection(String title, List<PresetHoliday> holidays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        ...holidays.map((h) => _buildPresetTile(h)),
      ],
    );
  }

  Widget _buildPresetTile(PresetHoliday h) {
    final isAdded = widget.existingEvents.any((e) => e.title == t(h.title));
    final isSelected = _selectedHolidays.contains(h);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        onTap: isAdded
            ? null
            : () {
                setState(() {
                  if (isSelected) {
                    _selectedHolidays.remove(h);
                  } else {
                    _selectedHolidays.add(h);
                  }
                });
              },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(h.colorValue).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(h.emoji, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          t(h.title),
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isAdded ? Colors.white38 : Colors.white,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${h.day}/${h.month}',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: isAdded ? Colors.white24 : Colors.white54,
              ),
            ),
            if (h.isLunar) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Âm lịch',
                  style: GoogleFonts.quicksand(fontSize: 10, color: Colors.amber),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                h.badge == 'vn' ? 'Việt Nam' : 'Quốc tế',
                style: GoogleFonts.quicksand(fontSize: 10, color: Colors.white60),
              ),
            ),
          ],
        ),
        trailing: isAdded
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t('already_added'),
                  style: GoogleFonts.quicksand(fontSize: 12, color: Colors.white38),
                ),
              )
            : Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white30,
              ),
        ),
      ),
    );
  }
}
