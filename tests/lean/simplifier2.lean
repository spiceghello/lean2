/- Basic rewriting with eq and lambda without congruence or conditionals -/
universe l
constant T : Type.{l}
constants (x y z : T) (f g h : T → T)
constants (Hfxgy : f x = g y) (Hgyhz : g y = h z)

namespace tst attribute Hfxgy [simp] end tst
#simplify eq tst 0 (λ a b c : bool, f x) -- λ (a b c : bool), g y
namespace tst attribute Hgyhz [simp] end tst
#simplify eq tst 0 (λ a b c : bool, f x) -- λ (a b c : bool), h z
