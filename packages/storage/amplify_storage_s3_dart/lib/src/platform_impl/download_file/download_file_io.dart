// Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:amplify_core/amplify_core.dart';
import 'package:amplify_storage_s3_dart/amplify_storage_s3_dart.dart';
import 'package:amplify_storage_s3_dart/src/storage_s3_service/storage_s3_service.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// The io implementation of `downloadFile` API.
@internal
S3DownloadFileOperation downloadFile({
  required StorageDownloadFileRequest request,
  required S3PluginConfig s3pluginConfig,
  required StorageS3Service storageS3Service,
  required AppPathProvider appPathProvider,
  void Function(S3TransferProgress)? onProgress,
}) {
  final s3Options = request.options as S3DownloadFileOptions? ??
      S3DownloadFileOptions(
        accessLevel: s3pluginConfig.defaultAccessLevel,
      );
  final targetIdentityId = s3Options.targetIdentityId;
  final downloadDataOptions = targetIdentityId == null
      ? S3DownloadDataOptions(
          accessLevel: s3Options.accessLevel,
          getProperties: s3Options.getProperties,
        )
      : S3DownloadDataOptions.forIdentity(
          targetIdentityId,
          getProperties: s3Options.getProperties,
        );

  late final String destinationPath;
  late final IOSink sink;
  late final File tempFile;

  final downloadDataTask = storageS3Service.downloadData(
    key: request.key,
    options: downloadDataOptions,
    // Ensure destination file is writable. Exception thrown in the check
    // will be forwarded to the Future, downloadDataTask.result below
    preStart: () async {
      destinationPath = await _ensureDestinationWritable(request.localFile);
      tempFile = File(
        path.join(
          await appPathProvider.getTemporaryPath(),
          'amplify_storage_s3_temp_${uuid()}',
        ),
      );
      sink = tempFile.openWrite(mode: FileMode.append);
    },
    onProgress: onProgress,
    // ignore: unnecessary_lambdas
    onData: (bytes) {
      sink.add(bytes);
    },
    // Exception thrown in this callback will be forwarded to the Future,
    // downloadDataTask.result below
    onDone: () async {
      // ensure all bytes are written into the temporary file and then close
      await sink.flush();
      await sink.close();
      // then copy the temporary file to the destination
      await tempFile.copy(destinationPath);
    },
    onError: () async {
      await sink.close();
    },
  );

  return S3DownloadFileOperation(
    request: StorageDownloadFileRequest(
      key: request.key,
      localFile: request.localFile,
      options: s3Options,
    ),
    // This future throws exceptions that may occurred in the entire
    // download process, all exceptions are remapped to a S3Exception
    result: downloadDataTask.result.then(
      (downloadedItem) async => S3DownloadFileResult(
        localFile: request.localFile,
        downloadedItem: downloadedItem,
      ),
    ),
    resume: downloadDataTask.resume,
    pause: downloadDataTask.pause,
    cancel: downloadDataTask.cancel,
  );
}

Future<String> _ensureDestinationWritable(AWSFile file) async {
  final destinationPath = file.path;

  if (destinationPath == null) {
    throw S3Exception.invalidDownloadFilePath();
  }

  // path should not be a directory
  if (await FileSystemEntity.isDirectory(destinationPath)) {
    throw S3Exception.invalidDownloadFilePath();
  }

  final destination = File(destinationPath);
  try {
    // override existing file
    if (await destination.exists()) {
      await destination.delete();
    }
  } on FileSystemException catch (error) {
    throw S3Exception.fromFileSystemException(error);
  }

  return destinationPath;
}
