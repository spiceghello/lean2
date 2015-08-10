/-
Copyright (c) 2015 Leonardo de Moura. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura

Naive sort for lists
-/
import data.list.comb data.list.set data.list.perm logic.connectives

namespace list
open decidable nat

variable  {A : Type}
variable  (R : A → A → Prop)
variable  [decR : decidable_rel R]
include decR

definition min_core : list A → A → A
| []     a := a
| (b::l) a := if R b a then min_core l b else min_core l a

definition min : Π (l : list A), l ≠ nil → A
| []     h := absurd rfl h
| (a::l) h := min_core R l a

variable  [decA : decidable_eq A]
include decA

variable {R}
variables (to : total R) (tr : transitive R) (rf : reflexive R)

lemma min_core_lemma : ∀ {b l} a, b ∈ l ∨ b = a → R (min_core R l a) b
| b []     a h := or.elim h
  (suppose b ∈ [], absurd this !not_mem_nil)
  (suppose b = a,
    assert R a a, from rf a,
    begin subst b, unfold min_core, assumption end)
| b (c::l) a h := or.elim h
  (suppose b ∈ c :: l, or.elim (eq_or_mem_of_mem_cons this)
    (suppose b = c,
      or.elim (em (R c a))
        (suppose R c a,
          assert R (min_core R l b) b, from min_core_lemma _ (or.inr rfl),
          begin unfold min_core, rewrite [if_pos `R c a`], subst c, assumption end)
        (suppose ¬ R c a,
          assert R a c, from or_resolve_right (to c a) this,
          assert R (min_core R l a) a, from min_core_lemma _ (or.inr rfl),
          assert R (min_core R l a) c, from tr this `R a c`,
          begin unfold min_core, rewrite [if_neg `¬ R c a`], subst b, exact `R (min_core R l a) c` end))
    (suppose b ∈ l,
      or.elim (em (R c a))
        (suppose R c a,
          assert R (min_core R l c) b, from min_core_lemma _ (or.inl `b ∈ l`),
          begin unfold min_core, rewrite [if_pos `R c a`], assumption end)
        (suppose ¬ R c a,
          assert R (min_core R l a) b, from min_core_lemma _ (or.inl `b ∈ l`),
          begin unfold min_core, rewrite [if_neg `¬ R c a`], assumption end)))
  (suppose b = a,
    assert R (min_core R l a) b, from min_core_lemma _ (or.inr this),
    or.elim (em (R c a))
       (suppose R c a,
         assert R (min_core R l c) c, from min_core_lemma _ (or.inr rfl),
         assert R (min_core R l c) a, from tr this `R c a`,
         begin unfold min_core, rewrite [if_pos `R c a`], subst b, exact `R (min_core R l c) a` end)
       (suppose ¬ R c a, begin unfold min_core, rewrite [if_neg `¬ R c a`], assumption end))

lemma min_core_le_of_mem {b : A} {l : list A} (a : A) : b ∈ l → R (min_core R l a) b :=
assume h : b ∈ l, min_core_lemma to tr rf a (or.inl h)

lemma min_core_le {l : list A} (a : A) : R (min_core R l a) a :=
min_core_lemma to tr rf a (or.inr rfl)

lemma min_lemma : ∀ {a : A} {l} (h : l ≠ nil), all l (R (min R l h))
| a []     h := absurd rfl h
| a (b::l) h :=
  all_of_forall (take x, suppose x ∈ b::l,
   or.elim (eq_or_mem_of_mem_cons this)
     (suppose x = b,
       assert R (min_core R l b) b, from min_core_le to tr rf b,
       begin subst x, unfold min, assumption end)
     (suppose x ∈ l,
       assert R (min_core R l b) x, from min_core_le_of_mem to tr rf _ this,
       begin unfold min, assumption end))

variable (R)

lemma min_core_mem : ∀ l a, min_core R l a ∈ l ∨ min_core R l a = a
| []     a := or.inr rfl
| (b::l) a := or.elim (em (R b a))
  (suppose R b a,
    begin
      unfold min_core, rewrite [if_pos `R b a`],
      apply  or.elim (min_core_mem l b),
      suppose min_core R l b ∈ l, or.inl (mem_cons_of_mem _ this),
      suppose min_core R l b = b, by rewrite this; exact or.inl !mem_cons
    end)
  (suppose ¬ R b a,
    begin
      unfold min_core, rewrite [if_neg `¬ R b a`],
      apply  or.elim (min_core_mem l a),
      suppose min_core R l a ∈ l, or.inl (mem_cons_of_mem _ this),
      suppose min_core R l a = a, or.inr this
    end)

lemma min_mem : ∀ (l : list A) (h : l ≠ nil), min R l h ∈ l
| []     h := absurd rfl h
| (a::l) h :=
  begin
    unfold min,
    apply or.elim (min_core_mem R l a),
    suppose min_core R l a ∈ l, mem_cons_of_mem _ this,
    suppose min_core R l a = a, by rewrite this; apply mem_cons
  end

omit decR
private lemma ne_nil {l : list A} {n : nat} : length l = succ n → l ≠ nil :=
assume h₁ h₂, by rewrite h₂ at h₁; contradiction

include decR
lemma sort_aux_lemma {l n} (h : length l = succ n) : length (erase (min R l (ne_nil h)) l) = n :=
have min R l _ ∈ l, from min_mem R l (ne_nil h),
assert length (erase (min R l  _) l) = pred (length l), from length_erase_of_mem this,
by rewrite h at this; exact this

definition sort_aux : Π (n : nat) (l : list A), length l = n → list A
| 0        l h := []
| (succ n) l h :=
  let m  := min R l (ne_nil h) in
  let l₁ := erase m l in
  m :: sort_aux n l₁ (sort_aux_lemma R h)

definition sort (l : list A) : list A :=
sort_aux R (length l) l rfl

open perm

lemma sort_aux_perm : ∀ {n : nat} {l : list A} (h : length l = n), sort_aux R n l h ~ l
| 0        l h := by rewrite [↑sort_aux, eq_nil_of_length_eq_zero h]
| (succ n) l h :=
  let m := min R l (ne_nil h) in
  assert leq : length (erase m l) = n,             from sort_aux_lemma R h,
  calc m :: sort_aux R n (erase m l) leq
         ~ m :: erase m l                   : perm.skip m (sort_aux_perm leq)
     ... ~ l                                : perm_erase (min_mem _ _ _)

lemma sort_perm (l : list A) : sort R l ~ l :=
sort_aux_perm R rfl

end list