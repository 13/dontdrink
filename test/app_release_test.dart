import 'package:dont_drink/core/models/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeVersion', () {
    test('strips a leading v and whitespace', () {
      expect(normalizeVersion('v1.2.3'), '1.2.3');
      expect(normalizeVersion('  v1.2.3 '), '1.2.3');
      expect(normalizeVersion('1.2.3'), '1.2.3');
    });
  });

  group('compareVersions', () {
    test('compares numerically, not lexically', () {
      // The whole reason this function exists: string comparison puts
      // '1.10.0' below '1.9.0'.
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('treats missing components as zero', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('returns zero for equal versions', () {
      expect(compareVersions('2.0.0', '2.0.0'), 0);
    });

    test('ignores a v prefix on either side', () {
      expect(compareVersions('v1.3.0', '1.2.0'), greaterThan(0));
      expect(compareVersions('1.3.0', 'v1.3.0'), 0);
    });

    test('treats non-numeric components as zero rather than throwing', () {
      expect(compareVersions('1.2.beta', '1.2.0'), 0);
      expect(compareVersions('garbage', '0.0.0'), 0);
    });

    test('compares major before minor before patch', () {
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.3.0', '1.2.99'), greaterThan(0));
    });
  });

  group('isNewerVersion', () {
    test('is true only when strictly greater', () {
      expect(isNewerVersion('1.2.0', '1.1.1'), isTrue);
      expect(isNewerVersion('1.1.1', '1.1.1'), isFalse);
      expect(isNewerVersion('1.1.0', '1.1.1'), isFalse);
    });
  });

  group('AppRelease.fromGitHubJson', () {
    Map<String, dynamic> payload({
      String tag = 'v1.2.0',
      List<Map<String, dynamic>>? assets,
    }) =>
        {
          'tag_name': tag,
          'body': 'Release notes here.',
          'published_at': '2026-06-09T11:17:54Z',
          'assets': assets ??
              [
                {
                  'name': 'dont-drink-v1.2.0.apk',
                  'browser_download_url':
                      'https://example.invalid/dont-drink-v1.2.0.apk',
                  'size': 12345678,
                },
              ],
        };

    test('parses tag, notes, asset url and size', () {
      final release = AppRelease.fromGitHubJson(payload())!;
      expect(release.tagName, 'v1.2.0');
      expect(release.version, '1.2.0');
      expect(release.notes, 'Release notes here.');
      expect(release.apkUrl, 'https://example.invalid/dont-drink-v1.2.0.apk');
      expect(release.apkSizeBytes, 12345678);
      expect(release.publishedAt?.year, 2026);
    });

    test('returns null when the release carries no apk asset', () {
      final json = payload(assets: [
        {
          'name': 'source.zip',
          'browser_download_url': 'https://example.invalid/source.zip',
          'size': 42,
        },
      ]);
      expect(AppRelease.fromGitHubJson(json), isNull);
    });

    test('returns null when assets is empty or missing', () {
      expect(AppRelease.fromGitHubJson(payload(assets: [])), isNull);
      expect(AppRelease.fromGitHubJson({'tag_name': 'v1.0.0'}), isNull);
    });

    test('returns null when tag_name is missing or not a string', () {
      final json = payload();
      json.remove('tag_name');
      expect(AppRelease.fromGitHubJson(json), isNull);

      final numericTag = payload();
      numericTag['tag_name'] = 12;
      expect(AppRelease.fromGitHubJson(numericTag), isNull);
    });

    test('tolerates a missing body, size or published_at', () {
      final json = payload();
      json.remove('body');
      json.remove('published_at');
      ((json['assets'] as List).first as Map<String, dynamic>).remove('size');

      final release = AppRelease.fromGitHubJson(json)!;
      expect(release.notes, isEmpty);
      expect(release.apkSizeBytes, 0);
      expect(release.publishedAt, isNull);
    });

    test('picks the apk when several assets are present', () {
      final json = payload(assets: [
        {
          'name': 'checksums.txt',
          'browser_download_url': 'https://example.invalid/checksums.txt',
          'size': 100,
        },
        {
          'name': 'dont-drink-v1.2.0.apk',
          'browser_download_url': 'https://example.invalid/app.apk',
          'size': 200,
        },
      ]);
      expect(AppRelease.fromGitHubJson(json)!.apkUrl,
          'https://example.invalid/app.apk');
    });
  });
}
