; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -attributor --attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=4 -S < %s | FileCheck %s --check-prefix=ATTRIBUTOR
; Copied from Transforms/FunctoinAttrs/nofree-attributor.ll

; UTC_ARGS: --disable

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

; Test cases specifically designed for the "nofree" function attribute.
; We use FIXME's to indicate problems and missing attributes.

; Free functions
declare void @free(i8* nocapture) local_unnamed_addr #1
declare noalias i8* @realloc(i8* nocapture, i64) local_unnamed_addr #0
declare void @_ZdaPv(i8*) local_unnamed_addr #2


; TEST 1 (positive case)
; ATTRIBUTOR: Function Attrs: nofree noinline nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @only_return()
define void @only_return() #0 {
    ret void
}


; TEST 2 (negative case)
; Only free
; void only_free(char* p) {
;    free(p);
; }

; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT: define void @only_free(i8* nocapture %0) local_unnamed_addr #1
define void @only_free(i8* nocapture %0) local_unnamed_addr #0 {
    tail call void @free(i8* %0) #1
    ret void
}


; TEST 3 (negative case)
; Free occurs in same scc.
; void free_in_scc1(char*p){
;    free_in_scc2(p);
; }
; void free_in_scc2(char*p){
;    free_in_scc1(p);
;    free(p);
; }


; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT :define void @free_in_scc1(i8* nocapture %0) local_unnamed_addr
define void @free_in_scc1(i8* nocapture %0) local_unnamed_addr #0 {
  tail call void @free_in_scc2(i8* %0) #1
  ret void
}


; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR: define void @free_in_scc2(i8* nocapture %0) local_unnamed_addr
define void @free_in_scc2(i8* nocapture %0) local_unnamed_addr #0 {
  %cmp = icmp eq i8* %0, null
  br i1 %cmp, label %rec, label %call
call:
  tail call void @free(i8* %0) #1
  br label %end
rec:
  tail call void @free_in_scc1(i8* %0)
  br label %end
end:
  ret void
}


; TEST 4 (positive case)
; Free doesn't occur.
; void mutual_recursion1(){
;    mutual_recursion2();
; }
; void mutual_recursion2(){
;     mutual_recursion1();
; }


; ATTRIBUTOR: Function Attrs: nofree noinline noreturn nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @mutual_recursion1()
define void @mutual_recursion1() #0 {
  call void @mutual_recursion2()
  ret void
}

; ATTRIBUTOR: Function Attrs: nofree noinline noreturn nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @mutual_recursion2()
define void @mutual_recursion2() #0 {
  call void @mutual_recursion1()
  ret void
}


; TEST 5
; C++ delete operation (negative case)
; void delete_op (char p[]){
;     delete [] p;
; }

; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT: define void @_Z9delete_opPc(i8* %0) local_unnamed_addr #1
define void @_Z9delete_opPc(i8* %0) local_unnamed_addr #0 {
  %2 = icmp eq i8* %0, null
  br i1 %2, label %4, label %3

; <label>:3:                                      ; preds = %1
  tail call void @_ZdaPv(i8* nonnull %0) #2
  br label %4

; <label>:4:                                      ; preds = %3, %1
  ret void
}


; TEST 6 (negative case)
; Call realloc
; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT: define noalias i8* @call_realloc(i8* nocapture %0, i64 %1) local_unnamed_addr
define noalias i8* @call_realloc(i8* nocapture %0, i64 %1) local_unnamed_addr #0 {
    %ret = tail call i8* @realloc(i8* %0, i64 %1) #2
    ret i8* %ret
}


; TEST 7 (positive case)
; Call function declaration with "nofree"


; ATTRIBUTOR: Function Attrs:  nofree noinline nounwind readnone uwtable
; ATTRIBUTOR-NEXT: declare void @nofree_function()
declare void @nofree_function() nofree readnone #0

; ATTRIBUTOR: Function Attrs: nofree noinline nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @call_nofree_function()
define void @call_nofree_function() #0 {
    tail call void @nofree_function()
    ret void
}

; TEST 8 (negative case)
; Call function declaration without "nofree"


; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NEXT: declare void @maybe_free()
declare void @maybe_free() #0


; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT: define void @call_maybe_free()
define void @call_maybe_free() #0 {
    tail call void @maybe_free()
    ret void
}


; TEST 9 (negative case)
; Call both of above functions

; ATTRIBUTOR: Function Attrs: noinline nounwind uwtable
; ATTRIBUTOR-NOT: nofree
; ATTRIBUTOR-NEXT: define void @call_both()
define void @call_both() #0 {
    tail call void @maybe_free()
    tail call void @nofree_function()
    ret void
}


; TEST 10 (positive case)
; Call intrinsic function
; ATTRIBUTOR: Function Attrs: nounwind readnone speculatable
; ATTRIBUTOR-NEXT: declare float @llvm.floor.f32(float)
declare float @llvm.floor.f32(float)

; FIXME: missing nofree
; ATTRIBUTOR: Function Attrs: nofree noinline nosync nounwind readnone uwtable willreturn
; ATTRIBUTOR-NEXT: define void @call_floor(float %a)

define void @call_floor(float %a) #0 {
    tail call float @llvm.floor.f32(float %a)
    ret void
}

; FIXME: missing nofree
; ATTRIBUTOR: Function Attrs: noinline nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define float @call_floor2(float %a)
define float @call_floor2(float %a) #0 {
    %c = tail call float @llvm.floor.f32(float %a)
    ret float %c
}

; TEST 11 (positive case)
; Check propagation.

; ATTRIBUTOR: Function Attrs: nofree noinline nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @f1()
define void @f1() #0 {
    tail call void @nofree_function()
    ret void
}

; ATTRIBUTOR: Function Attrs: nofree noinline nosync nounwind readnone uwtable
; ATTRIBUTOR-NEXT: define void @f2()
define void @f2() #0 {
    tail call void @f1()
    ret void
}

; TEST 12 NoFree argument - positive.
; ATTRIBUTOR: define double @test12(double* nocapture nofree nonnull readonly align 8 dereferenceable(8) %a)
define double @test12(double* nocapture readonly %a) {
entry:
	%0 = load double, double* %a, align 8
	%call = tail call double @cos(double %0) #2
	ret double %call
}

declare double @cos(double) nobuiltin nounwind nofree

; FIXME: %a should be nofree.
; TEST 13 NoFree argument - positive.
; ATTRIBUTOR: define noalias i32* @test13(i64* nocapture nonnull readonly align 8 dereferenceable(8) %a)
define noalias i32* @test13(i64* nocapture readonly %a) {
entry:
	%0 = load i64, i64* %a, align 8
	%call = tail call noalias i8* @malloc(i64 %0) #2
	%1 = bitcast i8* %call to i32*
	ret i32* %1
}

; ATTRIBUTOR: define void @test14(i8* nocapture %0, i8* nocapture nofree readnone %1)
define void @test14(i8* nocapture %0, i8* nocapture %1) {
	tail call void @free(i8* %0) #1
	ret void
}

; UTC_ARGS: --enable

define void @nonnull_assume_pos(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4) {
; ATTRIBUTOR-LABEL: define {{[^@]+}}@nonnull_assume_pos
; ATTRIBUTOR-SAME: (i8* nofree [[ARG1:%.*]], i8* [[ARG2:%.*]], i8* nofree [[ARG3:%.*]], i8* [[ARG4:%.*]])
; ATTRIBUTOR-NEXT:    call void @llvm.assume(i1 true) #11 [ "nofree"(i8* [[ARG1]]), "nofree"(i8* [[ARG3]]) ]
; ATTRIBUTOR-NEXT:    call void @unknown(i8* nofree [[ARG1]], i8* [[ARG2]], i8* nofree [[ARG3]], i8* [[ARG4]])
; ATTRIBUTOR-NEXT:    ret void
;
  call void @llvm.assume(i1 true) ["nofree"(i8* %arg1), "nofree"(i8* %arg3)]
  call void @unknown(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4)
  ret void
}
define void @nonnull_assume_neg(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4) {
; ATTRIBUTOR-LABEL: define {{[^@]+}}@nonnull_assume_neg
; ATTRIBUTOR-SAME: (i8* [[ARG1:%.*]], i8* [[ARG2:%.*]], i8* [[ARG3:%.*]], i8* [[ARG4:%.*]])
; ATTRIBUTOR-NEXT:    call void @unknown(i8* [[ARG1]], i8* [[ARG2]], i8* [[ARG3]], i8* [[ARG4]])
; ATTRIBUTOR-NEXT:    call void @llvm.assume(i1 true) [ "nofree"(i8* [[ARG1]]), "nofree"(i8* [[ARG3]]) ]
; ATTRIBUTOR-NEXT:    ret void
;
  call void @unknown(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4)
  call void @llvm.assume(i1 true) ["nofree"(i8* %arg1), "nofree"(i8* %arg3)]
  ret void
}
define void @nonnull_assume_call(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4) {
; ATTRIBUTOR-LABEL: define {{[^@]+}}@nonnull_assume_call
; ATTRIBUTOR-SAME: (i8* [[ARG1:%.*]], i8* [[ARG2:%.*]], i8* [[ARG3:%.*]], i8* [[ARG4:%.*]])
; ATTRIBUTOR-NEXT:    call void @unknown(i8* [[ARG1]], i8* [[ARG2]], i8* [[ARG3]], i8* [[ARG4]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr(i8* noalias readnone [[ARG1]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr(i8* noalias readnone [[ARG2]])
; ATTRIBUTOR-NEXT:    call void @llvm.assume(i1 true) [ "nofree"(i8* [[ARG1]]), "nofree"(i8* [[ARG3]]) ]
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr(i8* noalias nofree readnone [[ARG3]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr(i8* noalias readnone [[ARG4]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr_ret(i8* noalias nofree readnone [[ARG1]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr_ret(i8* noalias readnone [[ARG2]])
; ATTRIBUTOR-NEXT:    call void @llvm.assume(i1 true) [ "nofree"(i8* [[ARG1]]), "nofree"(i8* [[ARG4]]) ]
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr_ret(i8* noalias nofree readnone [[ARG3]])
; ATTRIBUTOR-NEXT:    call void @use_i8_ptr_ret(i8* noalias nofree readnone [[ARG4]])
; ATTRIBUTOR-NEXT:    ret void
;
  call void @unknown(i8* %arg1, i8* %arg2, i8* %arg3, i8* %arg4)
  call void @use_i8_ptr(i8* %arg1)
  call void @use_i8_ptr(i8* %arg2)
  call void @llvm.assume(i1 true) ["nofree"(i8* %arg1), "nofree"(i8* %arg3)]
  call void @use_i8_ptr(i8* %arg3)
  call void @use_i8_ptr(i8* %arg4)
  call void @use_i8_ptr_ret(i8* %arg1)
  call void @use_i8_ptr_ret(i8* %arg2)
  call void @llvm.assume(i1 true) ["nofree"(i8* %arg1), "nofree"(i8* %arg4)]
  call void @use_i8_ptr_ret(i8* %arg3)
  call void @use_i8_ptr_ret(i8* %arg4)
  ret void
}
declare void @llvm.assume(i1)
declare void @unknown(i8*, i8*, i8*, i8*)
declare void @use_i8_ptr(i8* nocapture readnone) nounwind
declare void @use_i8_ptr_ret(i8* nocapture readnone) nounwind willreturn

declare noalias i8* @malloc(i64)

attributes #0 = { nounwind uwtable noinline }
attributes #1 = { nounwind }
attributes #2 = { nobuiltin nounwind }
