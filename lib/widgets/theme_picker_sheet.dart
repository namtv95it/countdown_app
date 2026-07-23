import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import '../services/font_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../widgets/premium_dialog.dart';

class ThemePickerSheet extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<String>? onEffectChanged;

  const ThemePickerSheet({
    super.key,
    this.initialTabIndex = 0,
    this.onEffectChanged,
  });

  @override
  State<ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<ThemePickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedEffect = 'none';
  String _selectedMusic = 'none';
  String? _customMusicName;
  bool _isLoading = true;
  bool _isPremium = false;
  final Map<String, bool> _effectUnlocked = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    final effect = await StorageService().getSelectedEffect();
    final effectIds = [
      'hearts', 'bubbles', 'snow', 'stars', 'meteor', 'rain',
      'rain_ripple', 'rainbow', 'waves', 'leaves', 'sunset_birds',
      'aurora', 'fireflies', 'fireworks', 'cherry_blossom', 'galaxy',
    ];
    final storage = StorageService();
    final unlockResults = await Future.wait(
      effectIds.map((id) => storage.isFeatureUnlocked('${id}_effect_unlocked')),
    );
    
    final music = await storage.getSelectedMusicId();
    final customPath = await storage.getCustomMusicPath();
    
    if (mounted) {
      setState(() {
        _selectedEffect = effect;
        _selectedMusic = music;
        if (customPath != null) {
          _customMusicName = customPath.split('/').last.split('\\').last;
        }
        _isPremium = AdService.isPremium;
        for (int i = 0; i < effectIds.length; i++) {
          _effectUnlocked[effectIds[i]] = unlockResults[i];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _selectEffect(String effectId, String effectName) async {
    if (effectId == 'none' || effectId == 'hearts') {
      setState(() => _selectedEffect = effectId);
      await StorageService().setSelectedEffect(effectId);
      widget.onEffectChanged?.call(effectId);
      return;
    }

    final isUnlocked = await StorageService().isFeatureUnlocked('${effectId}_effect_unlocked');
    if (isUnlocked || _isPremium) {
      if (mounted) {
        setState(() => _selectedEffect = effectId);
      }
      await StorageService().setSelectedEffect(effectId);
      widget.onEffectChanged?.call(effectId);
      return;
    }

    // Yêu cầu xem quảng cáo
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t('effect_prefix', params: {'effect': effectName}),
                  style: GoogleFonts.quicksand(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('unlock_effect_msg', params: {'effect': effectName}),
              style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                label: Text(
                  'Nâng cấp Premium (\$2.00)',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14142B),
                  elevation: 0,
                  side: const BorderSide(color: Colors.amber, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  PremiumDialog.show(
                    context,
                    onPremiumUnlocked: () async {
                      setState(() => _isPremium = true);
                      await StorageService().setPremium(true);
                      AdService.isPremium = true;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                label: Text(
                  'Xem Quảng Cáo (Miễn phí)',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  AdService.showRewardedAd(
                    onEarnedReward: () async {
                      await StorageService().unlockFeature('${effectId}_effect_unlocked');
                      await StorageService().setSelectedEffect(effectId);
                      if (mounted) {
                        setState(() {
                          _selectedEffect = effectId;
                          _effectUnlocked[effectId] = true;
                        });
                        widget.onEffectChanged?.call(effectId);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(t('premium_effect_unlocked', params: {'effect': effectName}), style: GoogleFonts.quicksand()),
                          backgroundColor: const Color(0xFF10B981),
                        ));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _changeFont(String fontName) async {
    setState(() {
      FontService.currentFont = fontName;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font', fontName);
    // Gửi lại effect hiện hành để kích hoạt setState ở màn hình chính, giúp cập nhật font
    widget.onEffectChanged?.call(_selectedEffect);
  }

  Future<void> _clearMusic() async {
    setState(() {
      _selectedMusic = 'none';
      _customMusicName = null;
    });
    await StorageService().setSelectedMusicId('none');
    AudioService().updateMusicSource();
  }

  Future<void> _pickCustomMusic() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        setState(() {
          _selectedMusic = 'custom';
          _customMusicName = path.split('/').last.split('\\').last;
        });
        await StorageService().setCustomMusicPath(path);
        await StorageService().setSelectedMusicId('custom');
        AudioService().updateMusicSource();
      }
    } catch (e) {
      debugPrint("Error picking audio: $e");
    }
  }

  Widget _buildEffectChip(String id, String name, IconData icon) {
    final isSelected = _selectedEffect == id;
    final isUnlocked = id == 'none' || id == 'hearts' || (_effectUnlocked[id] ?? false) || _isPremium;
    
    return InkWell(
      onTap: () => _selectEffect(id, name),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.white12,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white60,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isUnlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.amber,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontChip(String fontName) {
    final isSelected = FontService.currentFont == fontName;
    return InkWell(
      onTap: () => _changeFont(fontName),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          fontName,
          style: FontService.getStyleForFont(
            fontName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFA78BFA),
            labelColor: const Color(0xFFA78BFA),
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: t('background_effect')),
              Tab(text: t('font_style')),
              Tab(text: t('tab_music') == 'tab_music' ? 'Nhạc nền' : t('tab_music')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Hiệu ứng
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.start,
                    children: [
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('none', t('none'), Icons.block)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('hearts', t('effect_hearts'), Icons.favorite)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('bubbles', t('effect_bubbles'), Icons.bubble_chart)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('snow', t('effect_snow'), Icons.ac_unit)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('stars', t('effect_stars'), Icons.star)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('meteor', t('effect_meteor'), Icons.auto_awesome)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('rain', t('effect_rain'), Icons.water_drop_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('rain_ripple', t('effect_rain_ripple'), Icons.track_changes_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('rainbow', t('effect_rainbow'), Icons.palette_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('waves', t('effect_waves'), Icons.waves_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('leaves', t('effect_leaves'), Icons.eco_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('sunset_birds', t('effect_sunset_birds'), Icons.wb_twilight_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('aurora', t('effect_aurora'), Icons.lens_blur_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('fireflies', t('effect_fireflies'), Icons.lightbulb_outline_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('fireworks', t('effect_fireworks'), Icons.celebration_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('cherry_blossom', t('effect_cherry_blossom'), Icons.filter_vintage_rounded)),
                      SizedBox(width: (MediaQuery.of(context).size.width - 40 - 20) / 3, child: _buildEffectChip('galaxy', t('effect_galaxy'), Icons.dark_mode_rounded)),
                    ],
                  ),
                ),
                // Tab Font chữ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      'Quicksand',
                      'Roboto',
                      'Nunito',
                      'Montserrat',
                      'Pacifico',
                      'Dancing Script',
                    ].map((fontName) => _buildFontChip(fontName)).toList(),
                  ),
                ),
                // Tab Nhạc nền
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_selectedMusic == 'custom' && _customMusicName != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note_rounded, color: Color(0xFFEC4899), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đang phát',
                                      style: GoogleFonts.quicksand(
                                        color: const Color(0xFFEC4899),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _customMusicName!,
                                      style: GoogleFonts.quicksand(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickCustomMusic,
                          icon: const Icon(Icons.folder_open_rounded, size: 24),
                          label: Text(
                            t('music_custom') == 'music_custom' ? 'Chọn từ thiết bị' : t('music_custom'),
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedMusic != 'none')
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _clearMusic,
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            label: Text(
                              'Xóa nhạc nền',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white60,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
