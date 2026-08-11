// Verify that SDK Swift modules are built from their textual interface
// independently of the importing project's clang context: two scans that
// differ only by a benign -Xcc -D produce the *same* module output path/hash
// for an SDK-resident module, so a single module is shared instead of one
// variant per context. A non-SDK module is unaffected (its hash still varies),
// and -disable-sdk-module-context-free-build restores the per-context variants
// for the SDK module too.

// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: mkdir -p %t/SDK/usr/lib/swift/InSDK.swiftmodule %t/Local/NonSDK.swiftmodule
// RUN: cp %t/InSDK.swiftinterface %t/SDK/usr/lib/swift/InSDK.swiftmodule/%target-swiftinterface-name
// RUN: cp %t/NonSDK.swiftinterface %t/Local/NonSDK.swiftmodule/%target-swiftinterface-name

// Two scans differing only by a benign -Xcc define.
// RUN: %target-swift-frontend -scan-dependencies %t/client.swift -sdk %t/SDK -I %t/Local -target %target-triple -o %t/deps1.json -Xcc -DBENIGN=1
// RUN: %target-swift-frontend -scan-dependencies %t/client.swift -sdk %t/SDK -I %t/Local -target %target-triple -o %t/deps2.json -Xcc -DBENIGN=2

// Both modules must be textual Swift modules, else a silent scan failure makes
// the comparisons below pass trivially.
// RUN: %validate-json %t/deps1.json | %FileCheck %s
// CHECK-DAG: "swift": "InSDK"
// CHECK-DAG: "swift": "NonSDK"

// SDK module: same modulePath (identical context hash) across the two scans.
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps1.json InSDK modulePath > %t/insdk1
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps2.json InSDK modulePath > %t/insdk2
// RUN: %FileCheck %s --check-prefix=HASHED --input-file=%t/insdk1
// HASHED: InSDK-{{[A-Z0-9]+}}.swiftmodule
// RUN: diff %t/insdk1 %t/insdk2

// Non-SDK module: modulePath (context hash) still differs — the gate is scoped
// to SDK interfaces only.
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps1.json NonSDK modulePath > %t/nonsdk1
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps2.json NonSDK modulePath > %t/nonsdk2
// RUN: not diff %t/nonsdk1 %t/nonsdk2

// With the feature disabled, the SDK module's hash varies again too.
// RUN: %target-swift-frontend -scan-dependencies %t/client.swift -sdk %t/SDK -I %t/Local -target %target-triple -disable-sdk-module-context-free-build -o %t/deps3.json -Xcc -DBENIGN=1
// RUN: %target-swift-frontend -scan-dependencies %t/client.swift -sdk %t/SDK -I %t/Local -target %target-triple -disable-sdk-module-context-free-build -o %t/deps4.json -Xcc -DBENIGN=2
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps3.json InSDK modulePath > %t/insdk3
// RUN: %{python} %S/../CAS/Inputs/SwiftDepsExtractor.py %t/deps4.json InSDK modulePath > %t/insdk4
// RUN: not diff %t/insdk3 %t/insdk4

//--- InSDK.swiftinterface
// swift-interface-format-version: 1.0
// swift-module-flags: -module-name InSDK -enable-library-evolution -swift-version 5
public func inSDK()

//--- NonSDK.swiftinterface
// swift-interface-format-version: 1.0
// swift-module-flags: -module-name NonSDK -enable-library-evolution -swift-version 5
public func nonSDK()

//--- client.swift
import InSDK
import NonSDK
