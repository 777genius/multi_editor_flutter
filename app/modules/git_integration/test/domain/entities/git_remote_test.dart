import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('GitRemote', () {
    late RemoteName originName;
    late RemoteName upstreamName;

    setUp(() {
      originName = const RemoteName(value: 'origin');
      upstreamName = const RemoteName(value: 'upstream');
    });

    group('creation', () {
      test('should create remote with basic information', () {
        // Act
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        // Assert
        expect(remote.name, equals(originName));
        expect(remote.fetchUrl, isNotEmpty);
        expect(remote.pushUrl, isNotEmpty);
        expect(remote.branches, isEmpty);
      });

      test('should create remote with branches', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
          branches: const [
            BranchName(value: 'main'),
            BranchName(value: 'develop'),
          ],
        );

        expect(remote.branches.length, equals(2));
        expect(remote.hasBranches, isTrue);
      });

      test('should create remote with different fetch/push URLs', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(remote.hasSeparateUrls, isTrue);
      });
    });

    group('remote name detection', () {
      test('should detect origin remote', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.isOrigin, isTrue);
        expect(remote.isUpstream, isFalse);
      });

      test('should detect upstream remote', () {
        final remote = GitRemote(
          name: upstreamName,
          fetchUrl: 'https://github.com/original/repo.git',
          pushUrl: 'https://github.com/original/repo.git',
        );

        expect(remote.isUpstream, isTrue);
        expect(remote.isOrigin, isFalse);
      });
    });

    group('URL validation', () {
      test('should detect when has fetch URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: '',
        );

        expect(remote.hasFetchUrl, isTrue);
      });

      test('should detect when has push URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: '',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.hasPushUrl, isTrue);
      });

      test('should detect when URLs are the same', () {
        final url = 'https://github.com/user/repo.git';
        final remote = GitRemote(
          name: originName,
          fetchUrl: url,
          pushUrl: url,
        );

        expect(remote.hasSeparateUrls, isFalse);
      });
    });

    group('protocol detection - SSH', () {
      test('should detect SSH with git@ prefix', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@github.com:user/repo.git',
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(remote.isSsh, isTrue);
        expect(remote.isHttps, isFalse);
        expect(remote.isHttp, isFalse);
        expect(remote.isLocal, isFalse);
        expect(remote.protocol, equals('SSH'));
      });

      test('should detect SSH with ssh:// prefix', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'ssh://git@github.com/user/repo.git',
          pushUrl: 'ssh://git@github.com/user/repo.git',
        );

        expect(remote.isSsh, isTrue);
        expect(remote.protocol, equals('SSH'));
      });
    });

    group('protocol detection - HTTPS', () {
      test('should detect HTTPS protocol', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.isHttps, isTrue);
        expect(remote.isSsh, isFalse);
        expect(remote.isHttp, isFalse);
        expect(remote.isLocal, isFalse);
        expect(remote.protocol, equals('HTTPS'));
      });
    });

    group('protocol detection - HTTP', () {
      test('should detect HTTP protocol (insecure)', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'http://example.com/repo.git',
          pushUrl: 'http://example.com/repo.git',
        );

        expect(remote.isHttp, isTrue);
        expect(remote.isHttps, isFalse);
        expect(remote.isSsh, isFalse);
        expect(remote.isLocal, isFalse);
        expect(remote.protocol, equals('HTTP'));
      });
    });

    group('protocol detection - Local', () {
      test('should detect local path', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: '/path/to/repo',
          pushUrl: '/path/to/repo',
        );

        expect(remote.isLocal, isTrue);
        expect(remote.isSsh, isFalse);
        expect(remote.isHttps, isFalse);
        expect(remote.isHttp, isFalse);
        expect(remote.protocol, equals('Local'));
      });
    });

    group('branches', () {
      test('should detect when has branches', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
          branches: const [BranchName(value: 'main')],
        );

        expect(remote.hasBranches, isTrue);
        expect(remote.branchCount, equals(1));
      });

      test('should detect when has no branches', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.hasBranches, isFalse);
        expect(remote.branchCount, equals(0));
      });

      test('should count multiple branches', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
          branches: const [
            BranchName(value: 'main'),
            BranchName(value: 'develop'),
            BranchName(value: 'feature/auth'),
          ],
        );

        expect(remote.branchCount, equals(3));
      });
    });

    group('repository name extraction - SSH', () {
      test('should extract repository name from SSH URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@github.com:user/repo.git',
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(remote.repositoryName, equals('user/repo'));
      });

      test('should extract repository name from SSH URL without .git', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@github.com:user/my-project',
          pushUrl: 'git@github.com:user/my-project',
        );

        expect(remote.repositoryName, equals('user/my-project'));
      });
    });

    group('repository name extraction - HTTPS', () {
      test('should extract repository name from HTTPS URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.repositoryName, equals('user/repo'));
      });

      test('should extract repository name from HTTP URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'http://gitlab.com/organization/project.git',
          pushUrl: 'http://gitlab.com/organization/project.git',
        );

        expect(remote.repositoryName, equals('organization/project'));
      });
    });

    group('repository name extraction - Local', () {
      test('should extract repository name from local path', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: '/path/to/my-repo',
          pushUrl: '/path/to/my-repo',
        );

        expect(remote.repositoryName, equals('my-repo'));
      });
    });

    group('host extraction', () {
      test('should extract host from SSH URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@github.com:user/repo.git',
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(remote.host, equals('github.com'));
      });

      test('should extract host from HTTPS URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://gitlab.com/user/repo.git',
          pushUrl: 'https://gitlab.com/user/repo.git',
        );

        expect(remote.host, equals('gitlab.com'));
      });

      test('should return empty host for local path', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: '/path/to/repo',
          pushUrl: '/path/to/repo',
        );

        expect(remote.host, isEmpty);
      });
    });

    group('hosting service detection', () {
      test('should detect GitHub remote', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote.isGitHub, isTrue);
        expect(remote.isGitLab, isFalse);
        expect(remote.isBitbucket, isFalse);
      });

      test('should detect GitLab remote', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@gitlab.com:user/repo.git',
          pushUrl: 'git@gitlab.com:user/repo.git',
        );

        expect(remote.isGitLab, isTrue);
        expect(remote.isGitHub, isFalse);
        expect(remote.isBitbucket, isFalse);
      });

      test('should detect Bitbucket remote', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://bitbucket.org/user/repo.git',
          pushUrl: 'https://bitbucket.org/user/repo.git',
        );

        expect(remote.isBitbucket, isTrue);
        expect(remote.isGitHub, isFalse);
        expect(remote.isGitLab, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final remote1 = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        final remote2 = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        expect(remote1, equals(remote2));
      });

      test('should not be equal with different URLs', () {
        final remote1 = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo1.git',
          pushUrl: 'https://github.com/user/repo1.git',
        );

        final remote2 = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo2.git',
          pushUrl: 'https://github.com/user/repo2.git',
        );

        expect(remote1, isNot(equals(remote2)));
      });
    });

    group('copyWith', () {
      test('should copy with new branches', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        final updated = remote.copyWith(
          branches: const [BranchName(value: 'main')],
        );

        expect(updated.branches.length, equals(1));
        expect(remote.branches, isEmpty);
      });

      test('should copy with new push URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'https://github.com/user/repo.git',
        );

        final updated = remote.copyWith(
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(updated.hasSeparateUrls, isTrue);
        expect(remote.hasSeparateUrls, isFalse);
      });
    });

    group('use cases', () {
      test('should represent typical GitHub origin', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'git@github.com:user/my-project.git',
          pushUrl: 'git@github.com:user/my-project.git',
          branches: const [
            BranchName(value: 'main'),
            BranchName(value: 'develop'),
          ],
        );

        expect(remote.isOrigin, isTrue);
        expect(remote.isGitHub, isTrue);
        expect(remote.isSsh, isTrue);
        expect(remote.repositoryName, equals('user/my-project'));
        expect(remote.branchCount, equals(2));
      });

      test('should represent forked repository with separate remotes', () {
        final upstreamRemote = GitRemote(
          name: upstreamName,
          fetchUrl: 'https://github.com/original/repo.git',
          pushUrl: 'https://github.com/original/repo.git',
        );

        expect(upstreamRemote.isUpstream, isTrue);
        expect(upstreamRemote.isHttps, isTrue);
        expect(upstreamRemote.repositoryName, equals('original/repo'));
      });

      test('should represent local development remote', () {
        final remote = GitRemote(
          name: const RemoteName(value: 'local'),
          fetchUrl: '/home/user/projects/backup',
          pushUrl: '/home/user/projects/backup',
        );

        expect(remote.isLocal, isTrue);
        expect(remote.repositoryName, equals('backup'));
      });

      test('should represent CI/CD remote with different push URL', () {
        final remote = GitRemote(
          name: originName,
          fetchUrl: 'https://github.com/user/repo.git',
          pushUrl: 'git@github.com:user/repo.git',
        );

        expect(remote.hasSeparateUrls, isTrue);
        expect(remote.isHttps, isTrue); // Fetch is HTTPS
      });
    });
  });
}
