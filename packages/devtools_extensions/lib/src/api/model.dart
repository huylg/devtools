// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'api.dart';

/// Data model for a devtools extension event that will be sent and received
/// over 'postMessage' between DevTools and an embedded extension iFrame.
///
/// See [DevToolsExtensionEventType] for different types of events that are
/// supported over this communication channel.
class DevToolsExtensionEvent {
  DevToolsExtensionEvent(
    this.type, {
    this.data,
    this.source,
  });

  factory DevToolsExtensionEvent.parse(Map<String, Object?> json) {
    final eventType =
        DevToolsExtensionEventType.from(json[_typeKey]! as String);
    final data = (json[_dataKey] as Map?)?.cast<String, Object?>();
    final source = json[sourceKey] as String?;
    return DevToolsExtensionEvent(eventType, data: data, source: source);
  }

  static DevToolsExtensionEvent? tryParse(Object data) {
    try {
      final dataAsMap = (data as Map).cast<String, Object?>();
      return DevToolsExtensionEvent.parse(dataAsMap);
    } catch (_) {
      return null;
    }
  }

  static const _typeKey = 'type';
  static const _dataKey = 'data';
  static const sourceKey = 'source';

  final DevToolsExtensionEventType type;
  final Map<String, Object?>? data;

  /// Optional field to describe the source that created and sent this event.
  final String? source;

  Map<String, Object?> toJson() {
    return {
      _typeKey: type.name,
      if (data != null) _dataKey: data!,
    };
  }
}

/// A void callback that handles a [DevToolsExtensionEvent].
typedef ExtensionEventHandler = void Function(DevToolsExtensionEvent event);
