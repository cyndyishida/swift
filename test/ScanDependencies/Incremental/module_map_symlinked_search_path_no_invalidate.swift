// REQUIRES: objc_interop
// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t/module-cache)

// RUN: split-file %s %t
// RUN: ln -s %t/Frameworks %t/Link

// The framework search path is a symlink, so the module map path the scan
// records is spelled differently from the one the search path gives.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_initial.json -module-name Test -F %t/Link -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_initial.json | %FileCheck %s -check-prefix=DEPS

// A scan with no changes does not invalidate ModB.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_noop.json -module-name Test -F %t/Link -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/noop_output.txt
// RUN: cat %t/noop_output.txt | %FileCheck %s -check-prefix=NOOP-OUTPUT
// RUN: %validate-json %t/deps_noop.json | %FileCheck %s -check-prefix=DEPS

// The source files keep the symlinked spelling; the module map path does not.
// DEPS: "{{.*}}Link{{/|\\\\}}ModB.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"
// DEPS: "moduleMapPath": "{{.*}}Frameworks{{/|\\\\}}ModB.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"

// NOOP-OUTPUT: remark: Incremental module scan: Re-using serialized module scanning dependency cache from: {{.*}}cache.moddepcache
// NOOP-OUTPUT-NOT: invalidated

//--- test.swift
import ModB

//--- Frameworks/ModB.framework/Headers/ModB.h
void modb(void);

//--- Frameworks/ModB.framework/Modules/module.modulemap
framework module ModB {
  header "ModB.h"
  export *
}
