/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';

class UploadFileOptions extends StorageOptions {
  StorageAccessLevel accessLevel;
  String? contentType;
  Map<String, String>? metadata;

  UploadFileOptions(
      {this.accessLevel = StorageAccessLevel.guest,
      this.contentType,
      this.metadata})
      : super();

  @override
  Map<String, Object?> serializeAsMap() => {
        'accessLevel': describeEnum(accessLevel),
        if (contentType != null) 'contentType': contentType,
        if (metadata != null) 'metadata': metadata,
      };
}
