// import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SpkPhotoPicker extends StatefulWidget {
  final List<String> existingUrls;       // already saved on server
  final void Function(List<PickedPhoto>) onChanged; // sends bytes to parent
  final int maxPhotos;
  final String label;
  final bool required;

  const SpkPhotoPicker({
    super.key,
    required this.existingUrls,
    required this.onChanged,
    this.maxPhotos = 10,
    this.label = 'Photos',
    this.required = false,
  });

  @override State<SpkPhotoPicker> createState() => _SpkPhotoPickerState();
}

class _SpkPhotoPickerState extends State<SpkPhotoPicker> {
  final _picker  = ImagePicker();
  final _picked  = <PickedPhoto>[];   // newly picked, with bytes
  final _previews = <Uint8List>[];    // for display

  int get _total => widget.existingUrls.length + _picked.length;

  Future<void> _pick(ImageSource source) async {
    if (_total >= widget.maxPhotos) {
      AppFeedback.showInfo(context, 'Max ${widget.maxPhotos} photos allowed');
      return;
    }

    final remaining = widget.maxPhotos - _total;

    if (source == ImageSource.gallery) {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;
      for (final f in files.take(remaining)) {
        final bytes = await f.readAsBytes();
        _picked.add(PickedPhoto(bytes: bytes, filename: f.name));
        _previews.add(bytes);
      }
    } else {
      final f = await _picker.pickImage(source: source, imageQuality: 80);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      _picked.add(PickedPhoto(bytes: bytes, filename: f.name));
      _previews.add(bytes);
    }

    setState(() {});
    widget.onChanged(List.unmodifiable(_picked));
  }

  void _remove(int index) {
    setState(() {
      _picked.removeAt(index);
      _previews.removeAt(index);
    });
    widget.onChanged(List.unmodifiable(_picked));
  }

  void _showSource() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.borderPrimary, borderRadius: BorderRadius.circular(4))),
          if (!kIsWeb) ListTile(
            leading: const AppSvgIcon(AppSvgAssets.camera, color: LeadTheme.secondary),
            title: const Text('Take Photo', style: TextStyle(fontSize: 14)),
            onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
          ListTile(
            leading: const AppSvgIcon(AppSvgAssets.images, color: LeadTheme.secondary),
            title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14)),
            onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
        ]),
      )));
  }

  @override
  Widget build(BuildContext context) {
    final showRequired = widget.required && _total == 0;
    final canAdd = _total < widget.maxPhotos;

    return Container(
      decoration: BoxDecoration(
        color: showRequired ? Colors.red.shade50 : LeadTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: showRequired ? Colors.red.shade300 : AppColors.borderLight,
          width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(children: [
            AppSvgIcon(AppSvgAssets.camera, size: 16,
              color: showRequired ? Colors.red : LeadTheme.secondary),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.required ? '${widget.label} *' : widget.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: showRequired ? Colors.red : LeadTheme.textPrimary))),
            Text('$_total/${widget.maxPhotos}',
              style: TextStyle(fontSize: 11,
                color: _total >= widget.maxPhotos ? Colors.orange : LeadTheme.textMuted)),
          ])),

        if (_total > 0) Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            ...widget.existingUrls.map((url) => _ServerThumb(url: url)),
            ..._previews.asMap().entries.map((e) =>
              _ByteThumb(bytes: e.value, onRemove: () => _remove(e.key))),
          ])),

        if (canAdd) Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: GestureDetector(
            onTap: _showSource,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: LeadTheme.secondary.withValues(alpha: 0.06),
                border: Border.all(color: LeadTheme.secondary.withValues(alpha: 0.3), width: 1.5),
                borderRadius: BorderRadius.circular(8)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppSvgIcon(AppSvgAssets.imagePlus,
                  size: 24, color: LeadTheme.secondary.withValues(alpha: 0.7)),
                const SizedBox(height: 2),
                Text('Add', style: TextStyle(fontSize: 10,
                  color: LeadTheme.secondary.withValues(alpha: 0.7))),
              ])))),

        if (showRequired)
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text('⚠️ At least 1 photo required',
              style: TextStyle(fontSize: 11, color: Colors.red.shade400))),
      ]),
    );
  }
}

class _ServerThumb extends StatelessWidget {
  final String url;
  const _ServerThumb({required this.url});
  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiConstants.imageUrl(url);
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(fullUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.textSecondary,
            child: const AppSvgIcon(AppSvgAssets.imageOff, size: 24, color: AppColors.textSecondary)))));
  }
}

class _ByteThumb extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;
  const _ByteThumb({required this.bytes, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LeadTheme.secondary.withValues(alpha: 0.4))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // Image.memory works on ALL platforms (web + mobile)
          child: Image.memory(bytes, fit: BoxFit.cover))),
      Positioned(top: 2, right: 2,
        child: GestureDetector(onTap: onRemove,
          child: Container(width: 18, height: 18,
            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            child: const AppSvgIcon(AppSvgAssets.x, size: 12, color: Colors.white)))),
    ]);
  }
}



