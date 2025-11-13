import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/remote_name.dart';
import '../value_objects/branch_name.dart';

part 'git_remote.freezed.dart';

/// Represents a Git remote entity
@freezed
class GitRemote with _$GitRemote {
  const GitRemote._();

  const factory GitRemote({
    required RemoteName name,
    required String fetchUrl,
    required String pushUrl,
    @Default([]) List<BranchName> branches,
  }) = _GitRemote;

  /// Domain logic: Is origin?
  bool get isOrigin => name.isOrigin;

  /// Domain logic: Is upstream?
  bool get isUpstream => name.isUpstream;

  /// Domain logic: Has fetch URL?
  bool get hasFetchUrl => fetchUrl.isNotEmpty;

  /// Domain logic: Has push URL?
  bool get hasPushUrl => pushUrl.isNotEmpty;

  /// Domain logic: Has different push/fetch URLs?
  bool get hasSeparateUrls => fetchUrl != pushUrl;

  /// Domain logic: Is SSH remote?
  bool get isSsh {
    return fetchUrl.startsWith('git@') ||
           fetchUrl.startsWith('ssh://');
  }

  /// Domain logic: Is HTTPS remote?
  bool get isHttps => fetchUrl.startsWith('https://');

  /// Domain logic: Is HTTP remote (insecure)?
  bool get isHttp => fetchUrl.startsWith('http://');

  /// Domain logic: Is local path?
  bool get isLocal {
    return !isSsh && !isHttps && !isHttp;
  }

  /// Domain logic: Get protocol display
  String get protocol {
    if (isSsh) return 'SSH';
    if (isHttps) return 'HTTPS';
    if (isHttp) return 'HTTP';
    if (isLocal) return 'Local';
    return 'Unknown';
  }

  /// Domain logic: Has branches?
  bool get hasBranches => branches.isNotEmpty;

  /// Domain logic: Get branch count
  int get branchCount => branches.length;

  /// Domain logic: Extract repository name from URL
  String get repositoryName {
    // Extract from URLs like:
    // - git@github.com:user/repo.git
    // - https://github.com/user/repo.git
    // - /path/to/repo

    final url = fetchUrl;

    if (isSsh) {
      final match = RegExp(r'[:/]([^/]+/[^/]+?)(\.git)?$').firstMatch(url);
      return match?.group(1) ?? url;
    }

    if (isHttps || isHttp) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final path = uri.path.replaceAll('.git', '');
        final parts = path.split('/').where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          return '${parts[parts.length - 2]}/${parts[parts.length - 1]}';
        }
      }
    }

    if (isLocal) {
      final parts = url.split('/');
      return parts.last;
    }

    return url;
  }

  /// Domain logic: Get host from URL
  String get host {
    if (isSsh) {
      final match = RegExp(r'@([^:]+):').firstMatch(fetchUrl);
      return match?.group(1) ?? '';
    }

    if (isHttps || isHttp) {
      final uri = Uri.tryParse(fetchUrl);
      return uri?.host ?? '';
    }

    return '';
  }

  /// Domain logic: Is GitHub remote?
  bool get isGitHub => host.contains('github.com');

  /// Domain logic: Is GitLab remote?
  bool get isGitLab => host.contains('gitlab.com');

  /// Domain logic: Is Bitbucket remote?
  bool get isBitbucket => host.contains('bitbucket.org');
}
