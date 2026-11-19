import 'dart:io';

final _versionLine = RegExp(
  r'^version: (0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\+([1-9]\d*)[ \t]*$',
  multiLine: true,
);

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final prepare = args.contains('--prepare');
  final parts = args
      .where((argument) => argument != '--dry-run' && argument != '--prepare')
      .toList();
  if (parts.length != 1 ||
      !{'patch', 'minor', 'major'}.contains(parts.single)) {
    stderr.writeln(
      'Usage: dart run tool/release.dart patch|minor|major [--prepare] [--dry-run]',
    );
    exitCode = 64;
    return;
  }
  final manifest = File('pubspec.yaml');
  final releases = Directory('build/releases');
  RandomAccessFile? lock;
  try {
    if (!dryRun) {
      releases.createSync(recursive: true);
      lock = File('${releases.path}/.lock').openSync(mode: FileMode.append);
      lock.lockSync();
    }
    final source = manifest.readAsStringSync();
    final version = _versionLine.firstMatch(source);
    if (version == null) {
      throw const FormatException(
        'Expected version: MAJOR.MINOR.PATCH+BUILD in pubspec.yaml.',
      );
    }
    final major = int.parse(version[1]!);
    final minor = int.parse(version[2]!);
    final patch = int.parse(version[3]!);
    final nextBuild = int.parse(version[4]!) + 1;
    final next = switch (parts.single) {
      'major' => '${major + 1}.0.0',
      'minor' => '$major.${minor + 1}.0',
      _ => '$major.$minor.${patch + 1}',
    };
    final nextVersion = '$next+$nextBuild';
    final artifact = File('${releases.path}/hear-clock-$nextVersion.apk');
    stdout.writeln('${version[0]} → $nextVersion');
    if (dryRun) return;
    if (artifact.existsSync()) {
      throw StateError('Release already exists at ${artifact.path}.');
    }
    if (!prepare) {
      final process = await Process.start(
        'flutter',
        [
          'build',
          'apk',
          '--release',
          '--build-name=$next',
          '--build-number=$nextBuild',
        ],
        runInShell: Platform.isWindows,
        mode: ProcessStartMode.inheritStdio,
      );
      exitCode = await process.exitCode;
      if (exitCode != 0) return;
    }
    if (manifest.readAsStringSync() != source) {
      throw StateError(
        'pubspec.yaml changed during the build. Run the release again.',
      );
    }
    final staging = releases.createTempSync('.staging-');
    try {
      final stagedManifest = File('${staging.path}/pubspec.yaml')
        ..writeAsStringSync(
          source.replaceRange(
            version.start,
            version.end,
            'version: $nextVersion',
          ),
          flush: true,
        );
      File? savedApk;
      if (!prepare) {
        final apk = File('build/app/outputs/flutter-apk/app-release.apk');
        savedApk = apk
            .copySync('${staging.path}/app.apk')
            .renameSync(artifact.path);
      }
      try {
        stagedManifest.renameSync(manifest.path);
      } catch (_) {
        savedApk?.deleteSync();
        rethrow;
      }
    } finally {
      staging.deleteSync(recursive: true);
    }
    stdout.writeln(
      prepare ? 'Prepared $nextVersion for tagging.' : artifact.path,
    );
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    lock?.closeSync();
  }
}
