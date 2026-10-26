// REQUIRES: objc_interop
// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t/module-cache)

// RUN: split-file %s %t

// Foo is reached only through the bridging header's include of Sub/foo.h, so a
// lookup of Foo by name does not find it.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_initial.json -module-name Test -I %t/Include -import-objc-header %t/bridge.h -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_initial.json | %FileCheck %s -check-prefix=DEPS

// A scan with no changes does not invalidate Foo.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_noop.json -module-name Test -I %t/Include -import-objc-header %t/bridge.h -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/noop_output.txt
// RUN: cat %t/noop_output.txt | %FileCheck %s -check-prefix=NOOP-OUTPUT
// RUN: %validate-json %t/deps_noop.json | %FileCheck %s -check-prefix=DEPS

// DEPS: "moduleMapPath": "{{.*}}Include{{/|\\\\}}Sub{{/|\\\\}}module.modulemap"

// NOOP-OUTPUT: remark: Incremental module scan: Re-using serialized module scanning dependency cache from: {{.*}}cache.moddepcache
// NOOP-OUTPUT-NOT: invalidated

//--- test.swift

//--- bridge.h
#include "Sub/foo.h"

//--- Include/Sub/foo.h
void foo(void);

//--- Include/Sub/module.modulemap
module Foo {
  header "foo.h"
  export *
}
