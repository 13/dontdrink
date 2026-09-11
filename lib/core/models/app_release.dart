import 'package:flutter/foundation.dart';

/// A published GitHub release that carries an installable APK.
@immutable
class AppRelease {
  const AppRelease({
    required this.version,
    required this.tagName,
    required this.notes,
    required this.apkUrl,
    required this.apkSizeBytes,
    this.publishedAt,
  });

  /// Semver string with no leading `v`, e.g. `1.2.0`.
  final String version;

  /// The git tag as published, e.g. `v1.2.0`.
  final String tagName;

  /// Release notes body. Empty when the release has none.
  final String notes;

  final String apkUrl;

  /// Size in bytes, or 0 when GitHub did not report one.
  final int apkSizeBytes;

  final DateTime? publishedAt;

  /// Build a release from the `releases/latest` payload.
  ///
  /// Returns null — rather than throwing — when the payload has no tag or no
  /// APK asset. Both are legitimate states (a release published with no
  /// artifact yet), not errors worth surfacing to the user.
  static AppRelease? fromGitHubJson(Map<String, dynamic> json) {
    final tag = json['tag_name'];
    if (tag is! String || tag.isEmpty) return null;

    final assets = json['assets'];
    if (assets is! List) return null;

    Map<String, dynamic>? apk;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      if (name is String && name.toLowerCase().endsWith('.apk')) {
        apk = Map<String, dynamic>.from(asset);
        break;
      }
    }
    if (apk == null) return null;

    final url = apk['browser_download_url'];
    if (url is! String || url.isEmpty) return null;

    final size = apk['size'];
    final body = json['body'];
    final published = json['published_at'];

    return AppRelease(
      version: normalizeVersion(tag),
      tagName: tag,
      notes: body is String ? body : '',
      apkUrl: url,
      apkSizeBytes: size is int ? size : 0,
      publishedAt: published is String ? DateTime.tryParse(published) : null,
    );
  }
}

/// Strip a leading `v` and surrounding whitespace from a tag or version.
String normalizeVersion(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
    return trimmed.substring(1);
  }
  return trimmed;
}

/// Compare two version strings numerically, component by component.
///
/// Negative when [a] is older, zero when equal, positive when [a] is newer.
/// Missing components count as zero, so `1.2` equals `1.2.0`. A component that
/// is not a number counts as zero rather than throwing — a malformed tag
/// should never crash the updater, it should simply not look newer.
///
/// String comparison is deliberately NOT used: it sorts `1.10.0` below
/// `1.9.0`.
int compareVersions(String a, String b) {
  final left = normalizeVersion(a).split('.');
  final right = normalizeVersion(b).split('.');
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final l = i < left.length ? (int.tryParse(left[i]) ?? 0) : 0;
    final r = i < right.length ? (int.tryParse(right[i]) ?? 0) : 0;
    if (l != r) return l - r;
  }
  return 0;
}

/// True when [candidate] is strictly newer than [current].
bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;
