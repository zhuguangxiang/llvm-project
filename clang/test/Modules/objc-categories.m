// RUN: rm -rf %t
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t -x objective-c -fmodule-name=category_top -emit-module %S/Inputs/module.map
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t -x objective-c -fmodule-name=category_left -emit-module %S/Inputs/module.map
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t -x objective-c -fmodule-name=category_right -emit-module %S/Inputs/module.map
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t -x objective-c -fmodule-name=category_bottom -emit-module %S/Inputs/module.map
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t -x objective-c -fmodule-name=category_other -emit-module %S/Inputs/module.map
// RUN: %clang_cc1 -fmodules -fmodule-cache-path %t %s -verify

@import category_bottom;




// in category_left.h: expected-note {{previous definition}}
// in category_right.h: expected-warning@11 {{duplicate definition of category}}

@interface Foo(Source)
-(void)source; 
@end

void test(Foo *foo, LeftFoo *leftFoo) {
  [foo source];
  [foo bottom];
  [foo left];
  [foo right1];
  [foo right2];
  [foo top];
  [foo top2];
  [foo top3];

  [leftFoo left];
  [leftFoo bottom];
}

// Load another module that also adds categories to Foo, verify that
// we see those categories.
@import category_other;

void test_other(Foo *foo) {
  [foo other];
}

// Make sure we don't see categories that should be hidden
void test_hidden_all_errors(Foo *foo) {
  [foo left_sub]; // expected-warning{{instance method '-left_sub' not found (return type defaults to 'id')}}
  foo.right_sub_prop = foo; // expected-error{{property 'right_sub_prop' not found on object of type 'Foo *'}}
  int i = foo->right_sub_ivar; // expected-error{{'Foo' does not have a member named 'right_sub_ivar'}}
  id<P1> p1 = foo; // expected-warning{{initializing 'id<P1>' with an expression of incompatible type 'Foo *'}}
  id<P2> p2 = foo; // expected-warning{{initializing 'id<P2>' with an expression of incompatible type 'Foo *'}}
}

@import category_left.sub;

void test_hidden_right_errors(Foo *foo) {
  // These are okay
  [foo left_sub]; // okay
  id<P1> p1 = foo;
  // FIXME: these should fail
  foo.right_sub_prop = foo; // expected-error{{property 'right_sub_prop' not found on object of type 'Foo *'}}
  int i = foo->right_sub_ivar; // expected-error{{'Foo' does not have a member named 'right_sub_ivar'}}
  id<P2> p2 = foo; // expected-warning{{initializing 'id<P2>' with an expression of incompatible type 'Foo *'}}
}

@import category_right.sub;

void test_hidden_okay(Foo *foo) {
  [foo left_sub];
  foo.right_sub_prop = foo;
  int i = foo->right_sub_ivar;
  id<P1> p1 = foo;
  id<P2> p2 = foo;
}
