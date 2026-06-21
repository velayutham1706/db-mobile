import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

/// Point this at your hosted version.json
/// e.g. a GitHub raw URL or release asset:
/// https://raw.githubusercontent.com/you/repo/main/version.json
const String _versionUrl = 'https://YOUR_HOST/version.json';

class UpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String notes;

  UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.notes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        versionCode: j['versionCode'] as int,
        versionName: j['versionName'] as String? ?? '',
        apkUrl: j['apkUrl'] as String,
        notes: j['notes'] as String? ?? '',
      );
}

class UpdateService {
  /// Call this from somewhere like main_shell.dart's initState.
  /// [silent] = true means: don't show anything if check fails or no update.
  static Future<void> checkForUpdate(BuildContext context,
      {bool silent = true}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      final res = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        if (!silent) _toast(context, 'Could not check for updates');
        return;
      }

      final update = UpdateInfo.fromJson(jsonDecode(res.body));
      if (update.versionCode <= currentCode) {
        if (!silent) _toast(context, 'You\'re on the latest version');
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(update: update),
      );
    } catch (_) {
      if (!silent) _toast(context, 'Could not check for updates');
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Downloads the APK to a temp file, reporting progress via [onProgress]
  /// (0.0 - 1.0), then returns the local file path.
  static Future<String> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    final total = response.contentLength ?? 0;
    var received = 0;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/update.apk');
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      received += chunk.length;
      sink.add(chunk);
      if (total > 0) onProgress(received / total);
    }).asFuture();

    await sink.flush();
    await sink.close();

    return file.path;
  }
}

// ── UPDATE DIALOG ──────────────────────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  final UpdateInfo update;
  const _UpdateDialog({required this.update});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final path = await UpdateService.downloadApk(
        widget.update.apkUrl,
        (p) => setState(() => _progress = p),
      );
      if (!mounted) return;
      await OpenFilex.open(path);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _downloading = false;
        _error = 'Download failed. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Available',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink)),
            const SizedBox(height: 4),
            Text('Version ${widget.update.versionName}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.muted,
                    fontFamily: 'JetBrains Mono',
                    letterSpacing: 1)),
            if (widget.update.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(widget.update.notes,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppTheme.ink, height: 1.4)),
              ),
            ],
            const SizedBox(height: 18),
            if (_downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 6,
                  backgroundColor: AppTheme.bg2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.ink),
                ),
              ),
              const SizedBox(height: 8),
              Text('${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.muted,
                      fontFamily: 'JetBrains Mono')),
            ] else ...[
              if (_error != null) ...[
                Text(_error!,
                    style: const TextStyle(fontSize: 11, color: Colors.red)),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkBtn(
                      label: 'LATER', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  InkBtn(label: 'UPDATE', active: true, onTap: _startUpdate),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}