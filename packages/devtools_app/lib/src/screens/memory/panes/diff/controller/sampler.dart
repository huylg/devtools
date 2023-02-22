// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';

import '../../../../../shared/globals.dart';
import '../../../../../shared/memory/adapted_heap_data.dart';
import '../../../../../shared/memory/class_name.dart';
import '../../../../../shared/vm_utils.dart';
import '../../../shared/heap/heap.dart';
import '../../../shared/primitives/instance_set_button.dart';

class HeapClassSampler extends ClassSampler {
  HeapClassSampler(this.objects, this.heap, this.heapClass);

  final HeapClassName heapClass;
  final ObjectSet objects;
  final AdaptedHeapData heap;

  IsolateRef get _mainIsolateRef =>
      serviceManager.isolateManager.mainIsolate.value!;

  Future<InstanceSet?> _liveInstances() async {
    final isolateId = _mainIsolateRef.id!;

    final theClass = await findClass(isolateId, heapClass);
    if (theClass == null) return null;

    return await serviceManager.service!.getInstances(
      isolateId,
      theClass.id!,
      preferences.memory.refLimit.value,
    );
  }

  @override
  Future<void> oneLiveStaticToConsole() async {
    final instances = (await _liveInstances())?.instances;

    final instanceRef = instances?.firstWhereOrNull(
      (objRef) =>
          objRef is InstanceRef &&
          objects.objectsByCodes.containsKey(objRef.identityHashCode),
    ) as InstanceRef?;

    if (instanceRef == null) {
      serviceManager.consoleService.appendStdio(
          'Unable to select instance that exist in snapshot and still alive in application.\n'
          'You may want to increase "${preferences.memory.refLimitTitle}" in memory settings.');
      return;
    }

    final heapObject = objects.objectsByCodes[instanceRef.identityHashCode!]!;

    final heapSelection = HeapObjectSelection(heap, object: heapObject);

    // drop to console
    serviceManager.consoleService.appendBrowsableInstance(
      instanceRef: instanceRef,
      isolateRef: _mainIsolateRef,
      heapSelection: heapSelection,
    );
  }

  @override
  bool get isEvalEnabled =>
      heapClass.classType(serviceManager.rootInfoNow().package) !=
      ClassType.runtime;

  @override
  Future<void> manyLiveToConsole() async {
    serviceManager.consoleService.appendInstanceSet(
      type: heapClass.shortName,
      instanceSet: (await _liveInstances())!,
      isolateRef: _mainIsolateRef,
    );
  }
}
