// RUN: export DARWIN_TARGET=x86_64-apple-macosx
// RUN: %target-swift-frontend -target $DARWIN_TARGET -emit-ir -o/dev/null -module-name test -validate-tbd-against-ir=all %s
// RUN: %target-swift-frontend -target $DARWIN_TARGET -emit-ir -o/dev/null -module-name test -validate-tbd-against-ir=all %s -O

// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -target $DARWIN_TARGET -typecheck -parse-as-library -module-name test %s -emit-tbd -emit-tbd-path %t/typecheck.tbd
// RUN: %target-swift-frontend -target $DARWIN_TARGET -emit-ir -parse-as-library -module-name test %s -emit-tbd -emit-tbd-path %t/emit-ir.tbd
// RUN: diff -u %t/typecheck.tbd %t/emit-ir.tbd

// Top-level code (i.e. implicit `main`) should be handled
