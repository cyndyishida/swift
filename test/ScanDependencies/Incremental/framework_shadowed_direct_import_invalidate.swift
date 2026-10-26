// REQUIRES: objc_interop
// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t/module-cache)
// RUN: %empty-directory(%t/BuildDir)
// RUN: %empty-directory(%t/Later)

// RUN: split-file %s %t

// Initial scan: ModB, imported directly, is only in 'Frameworks'.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_initial.json -module-name Test -I %t/SwiftDeps -F %t/BuildDir -F %t/Frameworks -F %t/Later -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_initial.json | %FileCheck %s -check-prefix=INITIAL

// A ModB in a later search path does not change which ModB is found.
// RUN: cp -R %t/BuildDirVariants/ModB.framework %t/Later/ModB.framework
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_later.json -module-name Test -I %t/SwiftDeps -F %t/BuildDir -F %t/Frameworks -F %t/Later -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/later_output.txt
// RUN: cat %t/later_output.txt | %FileCheck %s -check-prefix=LATER-OUTPUT
// RUN: %validate-json %t/deps_later.json | %FileCheck %s -check-prefix=INITIAL

// A ModB in an earlier search path is found instead. Nothing asks Clang for ModB
// again, so only the check of the prior scan's results can notice it.
// RUN: cp -R %t/BuildDirVariants/ModB.framework %t/BuildDir/ModB.framework
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_rescan.json -module-name Test -I %t/SwiftDeps -F %t/BuildDir -F %t/Frameworks -F %t/Later -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/rescan_output.txt
// RUN: cat %t/rescan_output.txt | %FileCheck %s -check-prefix=RESCAN-OUTPUT
// RUN: %validate-json %t/deps_rescan.json | %FileCheck %s -check-prefix=RESCAN

// The re-scan reproduces what a scan with no cache finds.
// RUN: %empty-directory(%t/clean-module-cache)
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -module-cache-path %t/clean-module-cache %t/test.swift -o %t/deps_clean.json -module-name Test -I %t/SwiftDeps -F %t/BuildDir -F %t/Frameworks -F %t/Later -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %validate-json %t/deps_clean.json | %FileCheck %s -check-prefix=RESCAN

// A further scan with no changes gives the same results.
// RUN: %target-swift-frontend -scan-dependencies -scanner-module-validation -module-load-mode prefer-interface -Rdependency-scan-cache -load-dependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/module-cache %t/test.swift -o %t/deps_noop.json -module-name Test -I %t/SwiftDeps -F %t/BuildDir -F %t/Frameworks -F %t/Later -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import -validate-prior-dependency-scan-cache &> %t/noop_output.txt
// RUN: cat %t/noop_output.txt | %FileCheck %s -check-prefix=LATER-OUTPUT
// RUN: %validate-json %t/deps_noop.json | %FileCheck %s -check-prefix=RESCAN

// INITIAL: "moduleMapPath": "{{.*}}Frameworks{{/|\\\\}}ModA.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"
// INITIAL-NOT: BuildDir{{/|\\\\}}ModB.framework
// INITIAL-NOT: Later{{/|\\\\}}ModB.framework
// INITIAL: "moduleMapPath": "{{.*}}Frameworks{{/|\\\\}}ModB.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"

// LATER-OUTPUT: remark: Incremental module scan: Re-using serialized module scanning dependency cache from: {{.*}}cache.moddepcache
// LATER-OUTPUT-NOT: invalidated

// RESCAN-OUTPUT: remark: Incremental module scan: Re-using serialized module scanning dependency cache from: {{.*}}cache.moddepcache
// RESCAN-OUTPUT: remark: Incremental module scan: Dependency info for module 'ModB' invalidated because the module was previously defined in '{{.*}}Frameworks{{[/\\]}}ModB.framework{{[/\\]}}Modules{{[/\\]}}module.modulemap' but is now found in '{{.*}}BuildDir{{[/\\]}}ModB.framework{{[/\\]}}Modules{{[/\\]}}module.modulemap'.
// RESCAN-OUTPUT-NOT: unexpected variant

// ModA's build command must use the same ModB as Test does.
// RESCAN: "moduleMapPath": "{{.*}}Frameworks{{/|\\\\}}ModA.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"
// RESCAN-NOT: Frameworks{{/|\\\\}}ModB.framework
// RESCAN: "-fmodule-map-file={{.*}}BuildDir{{/|\\\\}}ModB.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"
// RESCAN: "moduleMapPath": "{{.*}}BuildDir{{/|\\\\}}ModB.framework{{/|\\\\}}Modules{{/|\\\\}}module.modulemap"

//--- test.swift
import SwiftDep
import ModB

//--- SwiftDeps/SwiftDep.swiftinterface
// swift-interface-format-version: 1.0
// swift-module-flags: -module-name SwiftDep
import ModA

//--- Frameworks/ModA.framework/Headers/ModA.h
#import <ModB/ModB.h>

//--- Frameworks/ModA.framework/Modules/module.modulemap
framework module ModA {
  header "ModA.h"
  export *
}

//--- Frameworks/ModB.framework/Headers/ModB.h
// ModB in 'Frameworks'

//--- Frameworks/ModB.framework/Modules/module.modulemap
framework module ModB {
  header "ModB.h"
  export *
}

//--- BuildDirVariants/ModB.framework/Headers/ModB.h
// ModB in 'BuildDir'

//--- BuildDirVariants/ModB.framework/Modules/module.modulemap
framework module ModB {
  header "ModB.h"
  export *
}
