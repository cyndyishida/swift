// REQUIRES: objc_interop
// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t/module-cache)

// RUN: split-file %s %t

// Initial scan: ModB is defined by the module map in the subdirectory named
// after it.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_initial.json -module-name Test -I %t/Include -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_initial.json | %FileCheck %s -check-prefix=INITIAL

// The search directory's own module map now defines ModB. It is read first, in
// the same search directory, so it defines ModB from now on.
// RUN: cp %t/Variants/module.modulemap %t/Include/module.modulemap
// RUN: cp %t/Variants/ModBNew.h %t/Include/ModBNew.h
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_rescan.json -module-name Test -I %t/Include -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/rescan_output.txt
// RUN: cat %t/rescan_output.txt | %FileCheck %s -check-prefix=RESCAN-OUTPUT
// RUN: %validate-json %t/deps_rescan.json | %FileCheck %s -check-prefix=RESCAN

// The re-scan reproduces what a scan with no cache finds.
// RUN: %empty-directory(%t/clean-module-cache)
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -module-cache-path %t/clean-module-cache %t/test.swift -o %t/deps_clean.json -module-name Test -I %t/Include -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_clean.json | %FileCheck %s -check-prefix=RESCAN

// INITIAL: "moduleMapPath": "{{.*}}Include{{/|\\\\}}ModB{{/|\\\\}}module.modulemap"

// RESCAN-OUTPUT: remark: Incremental module scan: Re-using serialized module scanning dependency cache from: {{.*}}cache.moddepcache
// RESCAN-OUTPUT: remark: Incremental module scan: Dependency info for module 'ModB' invalidated because the module was previously defined in '{{.*}}Include{{[/\\]}}ModB{{[/\\]}}module.modulemap' but is now found in '{{.*}}Include{{[/\\]}}module.modulemap'.

// RESCAN: "moduleMapPath": "{{.*}}Include{{/|\\\\}}module.modulemap"

//--- test.swift
import ModB

//--- Include/ModB/module.modulemap
module ModB {
  header "ModB.h"
  export *
}

//--- Include/ModB/ModB.h
void modb(void);

//--- Variants/module.modulemap
module ModB {
  header "ModBNew.h"
  export *
}

//--- Variants/ModBNew.h
void modb_new(void);
