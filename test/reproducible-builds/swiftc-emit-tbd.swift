// RUN: export DARWIN_TARGET=x86_64-apple-macosx10.9
// RUN: %empty-directory(%t)
// RUN: %target-build-swift -target $DARWIN_TARGET -O -g -module-name foo %s -emit-tbd-path %t/run-1.tbd -force-single-frontend-invocation
// RUN: %target-build-swift -target $DARWIN_TARGET -O -g -module-name foo %s -emit-tbd-path %t/run-2.tbd -force-single-frontend-invocation
// RUN: diff -u %t/run-1.tbd %t/run-2.tbd
print("foo")
