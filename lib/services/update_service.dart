import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dont_drink/core/models/app_release.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// A failure the user should be told about, phrased for display.
class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to GitHub Releases and hands a downloaded APK to the system
/// installer.
///
/// Uses `dart:io`'s [HttpClient] rather than adding a networking package: it
/// streams responses, which is what a determinate progress bar needs, and it
/// keeps the dependency count flat.
class UpdateService {
  UpdateService({
    this.owner = '13',
    this.repo = 'dontdrink',
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory;

  final String owner;
  final String repo;
  final HttpClient Function()? _httpClientFactory;

  /// GitHub rejects API requests without a User-Agent.
  static const _userAgent = 'dont-drink-app';

  HttpClient _newClient() {
    final client = (_httpClientFactory ?? HttpClient.new)();
    client.connectionTimeout = const Duration(seconds: 15);
    return client;
  }

  Uri get _latestReleaseUri =>
      Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest');

  /// The latest published release, or null when it carries no APK asset.
  ///
  /// Throws [UpdateException] for anything the user should see: no network,
  /// a non-200 response, or a body that is not the JSON object we expect.
  Future<AppRelease?> fetchLatest() async {
    final client = _newClient();
    try {
      return await _fetchLatestWithTimeout(client);
    } on SocketException {
      throw const UpdateException(
          'Could not reach GitHub. Check your connection.');
    } on HandshakeException {
      throw const UpdateException('Could not establish a secure connection.');
    } on HttpException {
      throw const UpdateException(
          'The connection to GitHub was interrupted. Please try again.');
    } on TimeoutException {
      client.close(force: true);
      throw const UpdateException(
          'The update check timed out. Please try again.');
    } finally {
      client.close();
    }
  }

  Future<AppRelease?> _fetchLatestWithTimeout(HttpClient client) async {
    return await _makeApiCall(client).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Update check timeout', null),
    );
  }

  Future<AppRelease?> _makeApiCall(HttpClient client) async {
    final request = await client.getUrl(_latestReleaseUri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    final response = await request.close();

    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 404) {
      throw const UpdateException('No releases have been published yet.');
    }
    if (response.statusCode == 403) {
      // Unauthenticated API access is rate-limited to 60/hour per IP.
      throw const UpdateException(
          'GitHub is rate-limiting update checks. Try again later.');
    }
    if (response.statusCode != 200) {
      throw UpdateException(
          'GitHub returned ${response.statusCode} when checking for updates.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const UpdateException(
          'GitHub returned something that was not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateException(
          'GitHub returned an unexpected response shape.');
    }

    return AppRelease.fromGitHubJson(decoded);
  }

  /// Download [release]'s APK into the app's cache directory.
  ///
  /// [onProgress] receives bytes so far and the total. The total is the
  /// asset size GitHub reported, falling back to `content-length`; it is 0
  /// when neither is known, which the UI renders as indeterminate.
  ///
  /// Throws [UpdateException] if the download fails, is truncated, or the
  /// file does not appear to be a valid APK.
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    final client = _newClient();
    try {
      final request = await client.getUrl(Uri.parse(release.apkUrl));
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw UpdateException(
            'Download failed with status ${response.statusCode}.');
      }

      final total = release.apkSizeBytes > 0
          ? release.apkSizeBytes
          : (response.contentLength > 0 ? response.contentLength : 0);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dont-drink-${release.tagName}.apk');
      // A half-written file from an interrupted attempt must not be installed.
      if (file.existsSync()) await file.delete();

      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // A short read means the connection dropped mid-download; the file is a
      // fragment, not an APK.
      if (total > 0 && received != total) {
        await file.delete();
        throw const UpdateException(
            'The download ended early and the file is incomplete. Please try again.');
      }

      // An APK is a ZIP. A captive portal or CDN error page served with status 200
      // would otherwise reach the installer as "problem parsing the package".
      // A zero-byte body reads as an empty stream, and openRead(...).first throws
      // on that before any length guard can run — so check the size first.
      final length = await file.length();
      var looksLikeZip = false;
      if (length >= 4) {
        final header = await file.openRead(0, 4).first;
        looksLikeZip = header.length >= 4 &&
            header[0] == 0x50 && header[1] == 0x4B &&
            header[2] == 0x03 && header[3] == 0x04;
      }
      if (!looksLikeZip) {
        await file.delete();
        throw const UpdateException(
            "That download wasn't a valid app file. You may be on a network that "
            'intercepts downloads — try a different connection.');
      }

      return file;
    } on SocketException {
      throw const UpdateException(
          'The download was interrupted. Check your connection.');
    } on HandshakeException {
      throw const UpdateException('Could not establish a secure connection.');
    } on HttpException {
      throw const UpdateException(
          'The connection to GitHub was interrupted. Please try again.');
    } finally {
      client.close();
    }
  }

  /// Hand [apk] to Android's package installer.
  ///
  /// Returns true when the installer was launched. On Android 8+ the
  /// "install unknown apps" permission is granted per-app at runtime; when it
  /// has not been granted the system opens that settings screen instead of
  /// installing, which is the correct behaviour and still counts as launched.
  ///
  /// Throws [UpdateException] if the installer could not be opened.
  Future<bool> installApk(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type == ResultType.done) return true;
    throw UpdateException('Could not open the installer: ${result.message}');
  }
}
