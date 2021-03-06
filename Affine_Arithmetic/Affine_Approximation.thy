section \<open>Approximation with Affine Forms\<close>
theory Affine_Approximation
imports
  "~~/src/HOL/Library/Code_Target_Numeral"
  "~~/src/HOL/Library/Monad_Syntax"
  Executable_Euclidean_Space
  Euclidean_Space_Explicit
  Affine_Form
keywords
  "approximate_affine" :: thy_decl
begin
text \<open>\label{sec:approxaffine}\<close>

text \<open>Approximate operations on affine forms.\<close>

subsection \<open>Intervals\<close>

definition One_pdevs_raw::"nat \<Rightarrow> 'a::executable_euclidean_space"
  where "One_pdevs_raw i = (if i < length (Basis_list::'a list) then Basis_list ! i else 0)"

lemma zeros_One_pdevs_raw:
  "One_pdevs_raw -` {0::'a::executable_euclidean_space} = {length (Basis_list::'a list)..}"
  by (auto simp: One_pdevs_raw_def split: if_split_asm dest!: nth_mem)

lemma nonzeros_One_pdevs_raw:
  "{i. One_pdevs_raw i \<noteq> (0::'a::executable_euclidean_space)} = - {length (Basis_list::'a list)..}"
  using zeros_One_pdevs_raw
  by blast

lift_definition One_pdevs::"'a::executable_euclidean_space pdevs" is One_pdevs_raw
  by (auto simp: nonzeros_One_pdevs_raw)

lemma pdevs_apply_One_pdevs[simp]: "pdevs_apply One_pdevs i =
  (if i < length (Basis_list::'a::executable_euclidean_space list) then Basis_list ! i else 0::'a)"
  by transfer (simp add: One_pdevs_raw_def)

lemma length_Basis_list_pos[simp]: "length Basis_list > 0"
  by (metis length_pos_if_in_set Basis_list SOME_Basis)

lemma Basis_list_nth_nonzero:
  "i < length (Basis_list::'a::executable_euclidean_space list) \<Longrightarrow> (Basis_list::'a list) ! i \<noteq> 0"
  by (auto dest!: nth_mem)

lemma Max_Collect_less_nat: "Max {i::nat. i < k} = (if k = 0 then Max {} else k - 1)"
  by (auto intro!: Max_eqI)

lemma degree_One_pdevs[simp]: "degree (One_pdevs::'a pdevs) =
    length (Basis_list::'a::executable_euclidean_space list)"
  by (auto simp: degree_eq_Suc_max Basis_list_nth_nonzero Max_Collect_less_nat intro!: Max_eqI)

definition inner_scaleR_pdevs::"'a::euclidean_space \<Rightarrow> 'a pdevs \<Rightarrow> 'a pdevs"
  where "inner_scaleR_pdevs b x = unop_pdevs (\<lambda>x. (b \<bullet> x) *\<^sub>R x) x"

lemma pdevs_apply_inner_scaleR_pdevs[simp]:
  "pdevs_apply (inner_scaleR_pdevs a x) i = (a \<bullet> (pdevs_apply x i)) *\<^sub>R (pdevs_apply x i)"
  by (simp add: inner_scaleR_pdevs_def)

lemma degree_inner_scaleR_pdevs_le:
  "degree (inner_scaleR_pdevs (l::'a::executable_euclidean_space) One_pdevs) \<le>
    degree (One_pdevs::'a pdevs)"
  by (rule degree_leI) (auto simp: inner_scaleR_pdevs_def One_pdevs_raw_def)

definition "pdevs_of_ivl l u = scaleR_pdevs (1/2) (inner_scaleR_pdevs (u - l) One_pdevs)"

lemma degree_pdevs_of_ivl_le:
  "degree (pdevs_of_ivl l u::'a::executable_euclidean_space pdevs) \<le> length (Basis_list::'a list)"
  using degree_inner_scaleR_pdevs_le
  by (simp add: pdevs_of_ivl_def)

lemma pdevs_apply_pdevs_of_ivl:
  defines "B \<equiv> Basis_list::'a::executable_euclidean_space list"
  shows "pdevs_apply (pdevs_of_ivl l u) i = (if i < length B then ((u - l)\<bullet>(B!i)/2)*\<^sub>R(B!i) else 0)"
  by (auto simp: pdevs_of_ivl_def B_def)

lemma deg_length_less_imp[simp]:
  "k < degree (pdevs_of_ivl l u::'a::executable_euclidean_space pdevs) \<Longrightarrow>
    k < length (Basis_list::'a list)"
  by (metis degree_pdevs_of_ivl_le dual_order.strict_trans nat_neq_iff not_le)

lemma tdev_pdevs_of_ivl: "tdev (pdevs_of_ivl l u) = \<bar>u - l\<bar> /\<^sub>R 2"
proof -
  have "tdev (pdevs_of_ivl l u) =
    (\<Sum>i <degree (pdevs_of_ivl l u). \<bar>pdevs_apply (pdevs_of_ivl l u) i\<bar>)"
    by (auto simp: tdev_def)
  also have "\<dots> = (\<Sum>i = 0..<length (Basis_list::'a list). \<bar>pdevs_apply (pdevs_of_ivl l u) i\<bar>)"
    by (rule sum.mono_neutral_cong_left) (auto simp: degree_pdevs_of_ivl_le)
  also have "\<dots> = (\<Sum>i = 0..<length (Basis_list::'a list).
      \<bar>((u - l) \<bullet> Basis_list ! i / 2) *\<^sub>R Basis_list ! i\<bar>)"
    by (auto simp: pdevs_apply_pdevs_of_ivl)
  also have "\<dots> = (\<Sum>b \<leftarrow> Basis_list. \<bar>((u - l) \<bullet> b / 2) *\<^sub>R b\<bar>)"
    by (auto simp: sum_list_sum_nth)
  also have "\<dots> = (\<Sum>b\<in>Basis. \<bar>((u - l) \<bullet> b / 2) *\<^sub>R b\<bar>)"
    by (auto simp: sum_list_distinct_conv_sum_set)
  also have "\<dots> = \<bar>u - l\<bar> /\<^sub>R 2"
    by (subst euclidean_representation[symmetric, of "\<bar>u - l\<bar> /\<^sub>R 2"])
      (simp add:  abs_inner abs_scaleR)
  finally show ?thesis .
qed

definition "aform_of_ivl l u = ((l + u)/\<^sub>R2, pdevs_of_ivl l u)"

definition "aform_of_point x = aform_of_ivl x x"

lemma Elem_affine_of_ivl_le:
  assumes "e \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes "l \<le> u"
  shows "l \<le> aform_val e (aform_of_ivl l u)"
proof -
  have "l =  (1 / 2) *\<^sub>R l + (1 / 2) *\<^sub>R l"
    by (simp add: scaleR_left_distrib[symmetric])
  also have "\<dots> = (l + u)/\<^sub>R2 - tdev (pdevs_of_ivl l u)"
    by (auto simp: assms tdev_pdevs_of_ivl algebra_simps)
  also have "\<dots> \<le> aform_val e (aform_of_ivl l u)"
    using abs_pdevs_val_le_tdev[OF assms(1), of "pdevs_of_ivl l u"]
    by (auto simp: aform_val_def aform_of_ivl_def minus_le_iff dest!: abs_le_D2)
  finally show ?thesis .
qed

lemma Elem_affine_of_ivl_ge:
  assumes "e \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes "l \<le> u"
  shows "aform_val e (aform_of_ivl l u) \<le> u"
proof -
  have "aform_val e (aform_of_ivl l u) \<le>  (l + u)/\<^sub>R2 + tdev (pdevs_of_ivl l u)"
    using abs_pdevs_val_le_tdev[OF assms(1), of "pdevs_of_ivl l u"]
    by (auto simp: aform_val_def aform_of_ivl_def minus_le_iff dest!: abs_le_D1)
  also have "\<dots> = (1 / 2) *\<^sub>R u + (1 / 2) *\<^sub>R u"
    by (auto simp: assms tdev_pdevs_of_ivl algebra_simps)
  also have "\<dots> = u"
    by (simp add: scaleR_left_distrib[symmetric])
  finally show ?thesis .
qed

lemma
  map_of_zip_upto_length_eq_nth:
  assumes "i < length B"
  shows "(map_of (zip [0..<length B] B) i) = Some (B ! i)"
proof -
  have "length [0..<length B] = length B"
    by simp
  from map_of_zip_is_Some[OF this, of i] assms
  have "map_of (zip [0..<length B] B) i = Some (B ! i)"
    by (auto simp: in_set_zip)
  thus ?thesis by simp
qed

lemma in_ivl_affine_of_ivlE:
  assumes "k \<in> {l .. u}"
  obtains e where "e \<in> UNIV \<rightarrow> {-1 .. 1}" "k = aform_val e (aform_of_ivl l u)"
proof atomize_elim
  define e where [abs_def]: "e i = (let b = if i <length (Basis_list::'a list) then
    (the (map_of (zip [0..<length (Basis_list::'a list)] (Basis_list::'a list)) i)) else 0 in
      ((k - (l + u) /\<^sub>R 2) \<bullet> b) / (((u - l) /\<^sub>R 2) \<bullet> b))" for i
  let ?B = "Basis_list::'a list"

  have "k = (1 / 2) *\<^sub>R (l + u) +
      (\<Sum>b \<in> Basis. (if (u - l) \<bullet> b = 0 then 0 else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> b)) *\<^sub>R b)"
    (is "_ = _ + ?dots")
    using assms
    by (force simp add: algebra_simps eucl_le[where 'a='a] intro!: euclidean_eqI[where 'a='a])
  also have
    "?dots = (\<Sum>b \<in> Basis. (if (u - l) \<bullet> b = 0 then 0 else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> b) *\<^sub>R b))"
    by (auto intro!: sum.cong)
  also have "\<dots> = (\<Sum>b \<leftarrow> ?B. (if (u - l) \<bullet> b = 0 then 0 else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> b) *\<^sub>R b))"
    by (auto simp: sum_list_distinct_conv_sum_set)
  also have "\<dots> =
    (\<Sum>i = 0..<length ?B.
        (if (u - l) \<bullet> ?B ! i = 0 then 0 else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> ?B ! i) *\<^sub>R ?B ! i))"
    by (auto simp: sum_list_sum_nth)
  also have "\<dots> =
    (\<Sum>i = 0..<degree (inner_scaleR_pdevs (u - l) One_pdevs).
        (if (u - l) \<bullet> Basis_list ! i = 0 then 0
        else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> Basis_list ! i) *\<^sub>R Basis_list ! i))"
    using degree_inner_scaleR_pdevs_le[of "u - l"]
    by (intro sum.mono_neutral_cong_right) (auto dest!: degree)
  also have "(1 / 2) *\<^sub>R (l + u) +
    (\<Sum>i = 0..<degree (inner_scaleR_pdevs (u - l) One_pdevs).
        (if (u - l) \<bullet> Basis_list ! i = 0 then 0
        else ((k - (1 / 2) *\<^sub>R (l + u)) \<bullet> Basis_list ! i) *\<^sub>R Basis_list ! i)) =
      aform_val e (aform_of_ivl l u)"
    by (auto simp: aform_val_def aform_of_ivl_def pdevs_of_ivl_def map_of_zip_upto_length_eq_nth
      e_def Let_def pdevs_val_sum field_simps
      intro!: sum.cong)
  finally have "k = aform_val e (aform_of_ivl l u)" .

  moreover
  {
    fix k l u::real assume *: "l \<le> k" "k \<le> u"
    let ?m = "l / 2 + u / 2"
    have "\<bar>k - ?m\<bar> \<le> \<bar>if k \<le> ?m then ?m - l else u - ?m\<bar>"
      using * by auto
    also have "\<dots> \<le> \<bar>u / 2 - l / 2\<bar>"
      by (auto simp: abs_real_def)
    finally have "\<bar>k - (l / 2 + u / 2)\<bar> \<le> \<bar>u / 2 - l/2\<bar>" .
  } note midpoint_abs = this
  have "e \<in> UNIV \<rightarrow> {- 1..1}"
    using assms
    unfolding e_def Let_def
    by (intro Pi_I divide_atLeastAtMost_1_absI)
      (auto simp: map_of_zip_upto_length_eq_nth eucl_le[where 'a='a]
        divide_le_eq_1 not_less inner_Basis algebra_simps intro!: midpoint_abs
        dest!: nth_mem)
  ultimately show "\<exists>e. e \<in> UNIV \<rightarrow> {- 1..1} \<and> k = aform_val e (aform_of_ivl l u)"
    by blast
qed

lemma Inf_aform_aform_of_ivl:
  assumes "l \<le> u"
  shows "Inf_aform (aform_of_ivl l u) = l"
  using assms
  by (auto simp: Inf_aform_def aform_of_ivl_def tdev_pdevs_of_ivl abs_diff_eq1 algebra_simps)
    (metis real_sum_of_halves scaleR_add_left scaleR_one)

lemma Sup_aform_aform_of_ivl:
  assumes "l \<le> u"
  shows "Sup_aform (aform_of_ivl l u) = u"
  using assms
  by (auto simp: Sup_aform_def aform_of_ivl_def tdev_pdevs_of_ivl abs_diff_eq1 algebra_simps)
    (metis real_sum_of_halves scaleR_add_left scaleR_one)

lemma Affine_aform_of_ivl:
  "a \<le> b \<Longrightarrow> Affine (aform_of_ivl a b) = {a .. b}"
  by (force simp: Affine_def valuate_def intro!: Elem_affine_of_ivl_ge Elem_affine_of_ivl_le
    elim!: in_ivl_affine_of_ivlE)

lemma Affine_notempty[intro, simp]: "Affine X \<noteq> {}"
  by (auto simp: Affine_def valuate_def)

lemma truncate_up_lt: "x < y \<Longrightarrow> x < truncate_up prec y"
  by (rule less_le_trans[OF _ truncate_up])

lemma truncate_up_pos_eq[simp]: "0 < truncate_up p x \<longleftrightarrow> 0 < x"
  by (auto simp: truncate_up_lt) (metis (poly_guards_query) not_le truncate_up_nonpos)

lemma inner_scaleR_pdevs_0: "inner_scaleR_pdevs 0 One_pdevs = zero_pdevs"
  unfolding inner_scaleR_pdevs_def
  by transfer (auto simp: unop_pdevs_raw_def)

lemma Affine_aform_of_point_eq[simp]: "Affine (aform_of_point p) = {p}"
  by (simp add: Affine_aform_of_ivl aform_of_point_def)

lemma mem_Affine_aform_of_point: "x \<in> Affine (aform_of_point x)"
  by simp

lemma
  aform_val_aform_of_ivl_innerE:
  assumes "e \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes "a \<le> b" "c \<in> Basis"
  obtains f where "aform_val e (aform_of_ivl a b) \<bullet> c = aform_val f (aform_of_ivl (a \<bullet> c) (b \<bullet> c))"
    "f \<in> UNIV \<rightarrow> {-1 .. 1}"
proof -
  have [simp]: "a \<bullet> c \<le> b \<bullet> c"
    using assms by (auto simp: eucl_le[where 'a='a])
  have "(\<lambda>x. x \<bullet> c) ` Affine (aform_of_ivl a b) = Affine (aform_of_ivl (a \<bullet> c) (b \<bullet> c))"
    using assms
    by (auto simp: Affine_aform_of_ivl eucl_le[where 'a='a]
      image_eqI[where x="\<Sum>i\<in>Basis. (if i = c then x else a \<bullet> i) *\<^sub>R i" for x])
  then obtain f where
      "aform_val e (aform_of_ivl a b) \<bullet> c = aform_val f (aform_of_ivl (a \<bullet> c) (b \<bullet> c))"
      "f \<in> UNIV \<rightarrow> {-1 .. 1}"
    using assms
    by (force simp: Affine_def valuate_def)
  thus ?thesis ..
qed


subsection \<open>Approximate Operations\<close>

definition "max_pdev x = fold (\<lambda>x y. if infnorm (snd x) > infnorm (snd y) then x else y) (list_of_pdevs x) (0, 0)"


subsubsection \<open>set of generated endpoints\<close>

fun points_of_list where
  "points_of_list x0 [] = [x0]"
| "points_of_list x0 ((i, x)#xs) = (points_of_list (x0 + x) xs @ points_of_list (x0 - x) xs)"

primrec points_of_aform where
  "points_of_aform (x, xs) = points_of_list x (list_of_pdevs xs)"


subsubsection \<open>Approximate total deviation\<close>

definition sum_list'::"nat \<Rightarrow> 'a list \<Rightarrow> 'a::executable_euclidean_space"
  where "sum_list' p xs = fold (\<lambda>a b. eucl_truncate_up p (a + b)) xs 0"

definition "tdev' p x = sum_list' p (map (abs o snd) (list_of_pdevs x))"

lemma
  eucl_fold_mono:
  fixes f::"'a::ordered_euclidean_space\<Rightarrow>'a\<Rightarrow>'a"
  assumes mono: "\<And>w x y z. w \<le> x \<Longrightarrow> y \<le> z \<Longrightarrow> f w y \<le> f x z"
  shows "x \<le> y \<Longrightarrow> fold f xs x \<le> fold f xs y"
  by (induct xs arbitrary: x y) (auto simp: mono)

lemma sum_list_add_le_fold_eucl_truncate_up:
  fixes z::"'a::executable_euclidean_space"
  shows "sum_list xs + z \<le> fold (\<lambda>x y. eucl_truncate_up p (x + y)) xs z"
proof (induct xs arbitrary: z)
  case (Cons x xs)
  have "sum_list (x # xs) + z = sum_list xs + (z + x)"
    by simp
  also have "\<dots> \<le> fold (\<lambda>x y. eucl_truncate_up p (x + y)) xs (z + x)"
    using Cons by simp
  also have "\<dots> \<le> fold (\<lambda>x y. eucl_truncate_up p (x + y)) xs (eucl_truncate_up p (x + z))"
    by (auto intro!: add_mono eucl_fold_mono eucl_truncate_up eucl_truncate_up_mono simp: ac_simps)
  finally show ?case by simp
qed simp

lemma sum_list_le_sum_list':
  "sum_list xs \<le> sum_list' p xs"
  unfolding sum_list'_def
  using sum_list_add_le_fold_eucl_truncate_up[of xs 0] by simp

lemma sum_list'_sum_list_le:
  "y \<le> sum_list xs \<Longrightarrow> y \<le> sum_list' p xs"
  by (metis sum_list_le_sum_list' order.trans)

lemma tdev': "tdev x \<le> tdev' p x"
  unfolding tdev'_def
proof -
  have "tdev x = (\<Sum>i = 0 ..< degree x. \<bar>pdevs_apply x i\<bar>)"
    by (auto intro!: sum.mono_neutral_cong_left simp: tdev_def)
  also have "\<dots> = (\<Sum>i \<leftarrow> rev [0 ..< degree x]. \<bar>pdevs_apply x i\<bar>)"
    by (metis atLeastLessThan_upt sum_list_rev rev_map sum_set_upt_conv_sum_list_nat)
  also have
    "\<dots> = sum_list (map (\<lambda>xa. \<bar>pdevs_apply x xa\<bar>) [xa\<leftarrow>rev [0..<degree x] . pdevs_apply x xa \<noteq> 0])"
    unfolding filter_map map_map o_def
    by (subst sum_list_map_filter) auto
  also note sum_list_le_sum_list'[of _ p]
  also have "[xa\<leftarrow>rev [0..<degree x] . pdevs_apply x xa \<noteq> 0] =
      rev (sorted_list_of_set (pdevs_domain x))"
    by (subst rev_is_rev_conv[symmetric])
      (auto simp: filter_map rev_filter intro!: sorted_distinct_set_unique
        sorted_filter[of "\<lambda>x. x", simplified] degree_gt)
  finally
  show "tdev x \<le> sum_list' p (map (abs \<circ> snd) (list_of_pdevs x))"
    by (auto simp: list_of_pdevs_def o_def rev_map filter_map rev_filter)
qed

lemma tdev'_le: "x \<le> tdev y \<Longrightarrow> x \<le> tdev' p y"
  by (metis order.trans tdev')

lemmas abs_pdevs_val_le_tdev' = tdev'_le[OF abs_pdevs_val_le_tdev]

lemma tdev'_uminus_pdevs[simp]: "tdev' p (uminus_pdevs x) = tdev' p x"
  by (auto simp: tdev'_def o_def rev_map filter_map rev_filter list_of_pdevs_def pdevs_domain_def)

abbreviation Radius::"'a::ordered_euclidean_space aform \<Rightarrow> 'a"
  where "Radius X \<equiv> tdev (snd X)"

abbreviation Radius'::"nat\<Rightarrow>'a::executable_euclidean_space aform \<Rightarrow> 'a"
  where "Radius' p X \<equiv> tdev' p (snd X)"

lemma Radius'_uminus_aform[simp]: "Radius' p (uminus_aform X) = Radius' p X"
  by (auto simp: uminus_aform_def)


subsubsection \<open>truncate partial deviations\<close>

definition trunc_pdevs_raw::"nat \<Rightarrow> (nat \<Rightarrow> 'a) \<Rightarrow> nat \<Rightarrow> 'a::executable_euclidean_space"
  where "trunc_pdevs_raw p x i = eucl_truncate_down p (x i)"

lemma nonzeros_trunc_pdevs_raw:
  "{i. trunc_pdevs_raw r x i \<noteq> 0} \<subseteq> {i. x i \<noteq> 0}"
  by (auto simp: trunc_pdevs_raw_def[abs_def])

lift_definition trunc_pdevs::"nat \<Rightarrow> 'a::executable_euclidean_space pdevs \<Rightarrow> 'a pdevs"
  is trunc_pdevs_raw
  by (auto intro!: finite_subset[OF nonzeros_trunc_pdevs_raw])

definition trunc_err_pdevs_raw::"nat \<Rightarrow> (nat \<Rightarrow> 'a) \<Rightarrow> nat \<Rightarrow> 'a::executable_euclidean_space"
  where "trunc_err_pdevs_raw p x i = trunc_pdevs_raw p x i - x i"

lemma nonzeros_trunc_err_pdevs_raw:
  "{i. trunc_err_pdevs_raw r x i \<noteq> 0} \<subseteq> {i. x i \<noteq> 0}"
  by (auto simp: trunc_pdevs_raw_def trunc_err_pdevs_raw_def[abs_def])

lift_definition trunc_err_pdevs::"nat \<Rightarrow> 'a::executable_euclidean_space pdevs \<Rightarrow> 'a pdevs"
  is trunc_err_pdevs_raw
  by (auto intro!: finite_subset[OF nonzeros_trunc_err_pdevs_raw])

lemma pdevs_apply_trunc_pdevs[simp]:
  fixes x y::"'a::euclidean_space"
  shows "pdevs_apply (trunc_pdevs p X) n = eucl_truncate_down p (pdevs_apply X n)"
  by transfer (simp add: trunc_pdevs_raw_def)

lemma pdevs_apply_trunc_err_pdevs[simp]:
  fixes x y::"'a::euclidean_space"
  shows "pdevs_apply (trunc_err_pdevs p X) n =
    eucl_truncate_down p (pdevs_apply X n) - (pdevs_apply X n)"
  by transfer (auto simp: trunc_err_pdevs_raw_def trunc_pdevs_raw_def)

lemma pdevs_val_trunc_pdevs:
  fixes x y::"'a::euclidean_space"
  shows "pdevs_val e (trunc_pdevs p X) = pdevs_val e X + pdevs_val e (trunc_err_pdevs p X)"
proof -
  have "pdevs_val e X + pdevs_val e (trunc_err_pdevs p X) =
      pdevs_val e (add_pdevs X (trunc_err_pdevs p X))"
    by simp
  also have "\<dots> = pdevs_val e (trunc_pdevs p X)"
    by (auto simp: pdevs_val_def trunc_pdevs_raw_def trunc_err_pdevs_raw_def)
  finally show ?thesis by simp
qed

lemma pdevs_val_trunc_err_pdevs:
  fixes x y::"'a::euclidean_space"
  shows "pdevs_val e (trunc_err_pdevs p X) = pdevs_val e (trunc_pdevs p X) - pdevs_val e X"
  by (simp add: pdevs_val_trunc_pdevs)

definition truncate_aform::"nat \<Rightarrow> 'a aform \<Rightarrow> 'a::executable_euclidean_space aform"
  where "truncate_aform p x = (eucl_truncate_down p (fst x), trunc_pdevs p (snd x))"

definition truncate_error_aform::"nat \<Rightarrow> 'a aform \<Rightarrow> 'a::executable_euclidean_space aform"
  where "truncate_error_aform p x =
    (eucl_truncate_down p (fst x) - fst x, trunc_err_pdevs p (snd x))"

lemma
  abs_aform_val_le:
  assumes "e \<in> UNIV \<rightarrow> {- 1..1}"
  shows "abs (aform_val e X) \<le> eucl_truncate_up p (\<bar>fst X\<bar> + tdev' p (snd X))"
proof -
  have "abs (aform_val e X) \<le> \<bar>fst X\<bar> + \<bar>pdevs_val e (snd X)\<bar>"
    by (auto simp: aform_val_def intro!: abs_triangle_ineq)
  also have "\<bar>pdevs_val e (snd X)\<bar> \<le> tdev (snd X)"
    using assms by (rule abs_pdevs_val_le_tdev)
  also note tdev'
  also note eucl_truncate_up
  finally show ?thesis by simp
qed


subsubsection \<open>truncation with error bound\<close>

definition "trunc_bound_eucl p s =
  (let
    d = eucl_truncate_down p s;
    ed = abs (d - s) in
  (d, eucl_truncate_up p ed))"

lemma trunc_bound_euclE:
  obtains err where
  "\<bar>err\<bar> \<le> snd (trunc_bound_eucl p x)"
  "fst (trunc_bound_eucl p x) = x + err"
proof atomize_elim
  have "fst (trunc_bound_eucl p x) = x + (eucl_truncate_down p x - x)"
    (is "_ = _ + ?err")
    by (simp_all add: trunc_bound_eucl_def Let_def)
  moreover have "abs ?err \<le> snd (trunc_bound_eucl p x)"
    by (simp add: trunc_bound_eucl_def Let_def eucl_truncate_up)
  ultimately show "\<exists>err. \<bar>err\<bar> \<le> snd (trunc_bound_eucl p x) \<and> fst (trunc_bound_eucl p x) = x + err"
    by auto
qed

definition "trunc_bound_pdevs p x = (trunc_pdevs p x, tdev' p (trunc_err_pdevs p x))"

lemma pdevs_apply_fst_trunc_bound_pdevs[simp]: "pdevs_apply (fst (trunc_bound_pdevs p x)) =
  pdevs_apply (trunc_pdevs p x)"
  by (simp add: trunc_bound_pdevs_def)

lemma trunc_bound_pdevsE:
  assumes "e \<in> UNIV \<rightarrow> {- 1..1}"
  obtains err where
  "\<bar>err\<bar> \<le> snd (trunc_bound_pdevs p x)"
  "pdevs_val e (fst ((trunc_bound_pdevs p x))) = pdevs_val e x + err"
proof atomize_elim
  have "pdevs_val e (fst (trunc_bound_pdevs p x)) = pdevs_val e x +
    pdevs_val e (add_pdevs (trunc_pdevs p x) (uminus_pdevs x))"
    (is "_ = _ + ?err")
    by (simp_all add: trunc_bound_pdevs_def Let_def)
  moreover have "abs ?err \<le> snd (trunc_bound_pdevs p x)"
    using assms
    by (auto simp add: pdevs_val_trunc_pdevs trunc_bound_pdevs_def Let_def eucl_truncate_up
      intro!: order_trans[OF abs_pdevs_val_le_tdev tdev'])
  ultimately show "\<exists>err. \<bar>err\<bar> \<le> snd (trunc_bound_pdevs p x) \<and>
      pdevs_val e (fst ((trunc_bound_pdevs p x))) = pdevs_val e x + err"
    by auto
qed


subsubsection \<open>Addition\<close>

definition add_aform::"'a::real_vector aform \<Rightarrow> 'a aform \<Rightarrow> 'a aform"
  where "add_aform x y = (fst x + fst y, add_pdevs (snd x) (snd y))"

lemma aform_val_add_aform:
  shows "aform_val e (add_aform X Y) = aform_val e X + aform_val e Y"
  by (auto simp: add_aform_def aform_val_def)

definition add_aform'::"nat \<Rightarrow> nat \<Rightarrow> 'a::executable_euclidean_space aform \<Rightarrow> 'a aform \<Rightarrow> 'a aform"
  where "add_aform' p n x y =
    (let
      z0 = trunc_bound_eucl p (fst x + fst y);
      z = trunc_bound_pdevs p (add_pdevs (snd x) (snd y))
      in (fst z0, pdev_upd (fst z) n (sum_list' p [snd z0, snd z])))"

lemma truncate_aform_error_aform_cancel:
  "aform_val e (truncate_aform p z) = aform_val e z + aform_val e (truncate_error_aform p z) "
  by (simp add: truncate_aform_def aform_val_def truncate_error_aform_def pdevs_val_trunc_pdevs)

lemma error_absE:
  assumes "abs err \<le> k"
  obtains e::real where "err = e * k" "e \<in> {-1 .. 1}"
  using assms
  by atomize_elim
    (safe intro!: exI[where x="err / abs k"] divide_atLeastAtMost_1_absI, auto)

lemma eucl_truncate_up_nonneg_eq_zero_iff:
  "x \<ge> 0 \<Longrightarrow> eucl_truncate_up p x = 0 \<longleftrightarrow> x = 0"
  by (metis (poly_guards_query) eq_iff eucl_truncate_up eucl_truncate_up_zero)

lemma
  aform_val_consume_error:
  assumes "abs err \<le> abs (pdevs_apply (snd X) n)"
  shows "aform_val (e(n := 0)) X + err = aform_val (e(n := err/pdevs_apply (snd X) n)) X"
  using assms
  by (auto simp add: aform_val_def)

lemma
  aform_val_consume_errorE:
  fixes X::"real aform"
  assumes "abs err \<le> abs (pdevs_apply (snd X) n)"
  obtains err' where "aform_val (e(n := 0)) X + err = aform_val (e(n := err')) X" "err' \<in> {-1 .. 1}"
  by atomize_elim
    (rule aform_val_consume_error assms aform_val_consume_error exI conjI
      divide_atLeastAtMost_1_absI)+

lemma add_aform'E:
  fixes X Y::"real aform"
  assumes e: "e \<in> UNIV \<rightarrow> {- 1..1}"
    and xn: "pdevs_apply (snd X) n = 0"
    and yn: "pdevs_apply (snd Y) n = 0"
  obtains err
  where "aform_val e (add_aform X Y) = aform_val (e(n:=err)) (add_aform' p n X Y)" "err \<in> {-1 .. 1}"
proof atomize_elim
  let ?t1 = "trunc_bound_eucl p (fst X + fst Y)"
  from trunc_bound_euclE
  obtain e1 where abs_e1: "\<bar>e1\<bar> \<le> snd ?t1" and e1: "fst ?t1 = fst X + fst Y + e1"
    by blast
  let ?t2 = "trunc_bound_pdevs p (add_pdevs (snd X) (snd Y))"
  from trunc_bound_pdevsE[OF e, of p "add_pdevs (snd X) (snd Y)"]
  obtain e2 where abs_e2: "\<bar>e2\<bar> \<le> snd (?t2)"
    and e2: "pdevs_val e (fst ?t2) = pdevs_val e (add_pdevs (snd X) (snd Y)) + e2"
    by blast

  have e_le: "\<bar>-(e1 + e2)\<bar> \<le> \<bar>pdevs_apply (snd (add_aform' p n X Y)) n\<bar>"
    by (auto simp: add_aform'_def Let_def assms
      intro!: order.trans[OF _ abs_ge_self] order.trans[OF abs_triangle_ineq4]
        sum_list'_sum_list_le add_mono abs_e1 abs_e2)

  have "aform_val e (add_aform X Y) = aform_val (e(n:=0)) (add_aform' p n X Y) + -(e1 + e2)"
    by (simp add: aform_val_def add_aform_def add_aform'_def Let_def e1 e2 assms)
  also obtain en where "\<dots> = aform_val (e(n:=en)) (add_aform' p n X Y)" and en: "en \<in> {-1 .. 1}"
    using e_le
    by (rule aform_val_consume_errorE)
  note this(1)
  finally
  show "\<exists>err. aform_val e (add_aform X Y) = aform_val (e(n := err)) (add_aform' p n X Y) \<and>
      err \<in> {- 1..1}"
    by (blast intro: en)
qed


subsubsection \<open>Scaling\<close>

definition aform_scaleR::"real aform \<Rightarrow> 'a::real_vector \<Rightarrow> 'a aform"
  where "aform_scaleR x y = (fst x *\<^sub>R y, pdevs_scaleR (snd x) y)"

lemma aform_val_scaleR_aform[simp]:
  shows "aform_val e (aform_scaleR X y) = aform_val e X *\<^sub>R y"
  by (auto simp: aform_scaleR_def aform_val_def scaleR_left_distrib)


subsubsection \<open>Multiplication\<close>

definition mult_aform::"nat \<Rightarrow> real aform \<Rightarrow> real aform \<Rightarrow> real aform"
  where "mult_aform n x y = (fst x * fst y,
    pdev_upd (add_pdevs (scaleR_pdevs (fst y) (snd x)) (scaleR_pdevs (fst x) (snd y)))
      n (tdev (snd x) * tdev (snd y)))"

lemma mult_aformE:
  fixes X Y::"real aform"
  assumes e: "e \<in> UNIV \<rightarrow> {- 1..1}"
    and xn: "pdevs_apply (snd X) n = 0" and yn: "pdevs_apply (snd Y) n = 0"
  obtains err
  where "aform_val (e(n:=err)) (mult_aform n X Y) = aform_val e X * aform_val e Y" "err \<in> {-1 .. 1}"
proof atomize_elim
  have err_le:
    "\<bar>pdevs_val e (snd X) * pdevs_val e (snd Y)\<bar> \<le> \<bar>pdevs_apply (snd (mult_aform n X Y)) n\<bar>"
    by (auto simp: abs_mult mult_aform_def assms
      intro!: mult_mono abs_pdevs_val_le_tdev[OF e] abs_ge_zero order_trans[OF _ abs_ge_self])
  have "aform_val e X * aform_val e Y = (fst X)*(fst Y) +
      pdevs_val e (scaleR_pdevs (fst X) (snd Y)) +
      pdevs_val e (scaleR_pdevs (fst Y) (snd X)) +
      pdevs_val e (snd X) * pdevs_val e (snd Y)"
    by (simp add: aform_val_def algebra_simps)
  also
  have "\<dots> = aform_val (e(n:=0)) (mult_aform n X Y) + pdevs_val e (snd X) * pdevs_val e (snd Y)"
    by (simp add: aform_val_def mult_aform_def assms)
  also obtain err where  "\<dots> = aform_val (e(n:=err)) (mult_aform n X Y)" and err: "err \<in> {-1 .. 1}"
    using err_le
    by (rule aform_val_consume_errorE)
  note this(1)
  finally have "aform_val e X * aform_val e Y = aform_val (e(n:=err)) (mult_aform n X Y)" .
  with err show "\<exists>err. aform_val (e(n := err)) (mult_aform n X Y) = aform_val e X * aform_val e Y \<and>
    err \<in> {- 1..1}"
    by auto
qed

definition mult_aform'::"nat \<Rightarrow> nat \<Rightarrow> real aform \<Rightarrow> real aform \<Rightarrow> real aform"
  where "mult_aform' p n x y = (
    let
      z0 = trunc_bound_eucl p (fst x * fst y);
      u = trunc_bound_pdevs p (scaleR_pdevs (fst y) (snd x));
      v = trunc_bound_pdevs p (scaleR_pdevs (fst x) (snd y));
      w = trunc_bound_pdevs p (add_pdevs (fst u) (fst v));
      l = trunc_bound_eucl p (tdev (snd x) * tdev (snd y))
    in
      (fst z0, pdev_upd (fst w) n (sum_list' p [fst l, snd l, snd z0, snd u, snd v, snd w])))"

lemma mult_aform'E:
  fixes X Y::"real aform"
  assumes e: "e \<in> UNIV \<rightarrow> {- 1..1}"
    and xn: "pdevs_apply (snd X) n = 0" and yn: "pdevs_apply (snd Y) n = 0"
  obtains err
  where
    "aform_val (e(n:=err)) (mult_aform' p n X Y) = aform_val e X * aform_val e Y"
    "err \<in> {-1 .. 1}"
proof atomize_elim
  let ?z0 = "trunc_bound_eucl p (fst X * fst Y)"
  from trunc_bound_euclE
  obtain e1 where abs_e1: "\<bar>e1\<bar> \<le> snd ?z0" and e1: "fst ?z0 = fst X * fst Y + e1"
    by blast
  let ?u = "trunc_bound_pdevs p (scaleR_pdevs (fst Y) (snd X))"
  from trunc_bound_pdevsE[OF e]
  obtain e2 where abs_e2: "\<bar>e2\<bar> \<le> snd (?u)"
    and e2: "pdevs_val e (fst ?u) = pdevs_val e (scaleR_pdevs (fst Y) (snd X)) + e2"
    by blast
  let ?v = "trunc_bound_pdevs p (scaleR_pdevs (fst X) (snd Y))"
  from trunc_bound_pdevsE[OF e]
  obtain e3 where abs_e3: "\<bar>e3\<bar> \<le> snd (?v)"
    and e3: "pdevs_val e (fst ?v) = pdevs_val e (scaleR_pdevs (fst X) (snd Y)) + e3"
    by blast
  let ?w = "trunc_bound_pdevs p (add_pdevs (fst ?u) (fst ?v))"
  from trunc_bound_pdevsE[OF e]
  obtain e4 where abs_e4: "\<bar>e4\<bar> \<le> snd (?w)"
    and e4: "pdevs_val e (fst ?w) = pdevs_val e (add_pdevs (fst ?u) (fst ?v)) + e4"
    by blast
  let ?l = "trunc_bound_eucl p (tdev (snd X) * tdev (snd Y))"
  from trunc_bound_euclE
  obtain e5 where abs_e5: "\<bar>e5\<bar> \<le> snd ?l" and e5: "fst ?l = tdev (snd X) * tdev (snd Y) + e5"
    by blast

  let ?err = "pdevs_val e (snd X) * pdevs_val e (snd Y) - e1 - e2 - e3 - e4"
  have "abs ?err \<le> \<bar>pdevs_val e (snd X) * pdevs_val e (snd Y)\<bar> + abs e1 + abs e2 + abs e3 + abs e4"
    by simp
  also have "\<dots> \<le> tdev (snd X) * tdev (snd Y) + snd ?z0 + snd ?u + snd ?v + snd ?w"
    unfolding abs_mult
    by (blast intro!: add_mono mult_mono e abs_pdevs_val_le_tdev abs_ge_zero abs_e1 abs_e2 abs_e3
      abs_e4 abs_e5)
  also have "tdev (snd X) * tdev (snd Y) \<le> fst ?l + snd ?l"
    using abs_e5
    by (auto simp add: e5)
  also have "fst ?l + snd ?l + snd ?z0 + snd ?u + snd ?v + snd ?w \<le>
      sum_list' p [fst ?l, snd ?l, snd ?z0, snd ?u, snd ?v, snd ?w]"
    by (rule order_trans[OF _ sum_list_le_sum_list']) simp
  also have "\<dots> \<le> \<bar>pdevs_apply (snd (mult_aform' p n X Y)) n\<bar>"
    by (simp add: mult_aform'_def Let_def assms)
  finally have err_le: "abs ?err \<le> \<bar>pdevs_apply (snd (mult_aform' p n X Y)) n\<bar>" by arith

  have "aform_val e X * aform_val e Y = (fst X)*(fst Y) +
      pdevs_val e (scaleR_pdevs (fst X) (snd Y)) +
      pdevs_val e (scaleR_pdevs (fst Y) (snd X)) +
      pdevs_val e (snd X) * pdevs_val e (snd Y)"
    by (simp add: aform_val_def algebra_simps)
  also have "\<dots> =
      aform_val (e(n:=0)) (mult_aform' p n X Y) + (pdevs_val e (snd X) * pdevs_val e (snd Y) -
        e1 - e2 - e3 - e4)"
    by (simp add: aform_val_def mult_aform'_def Let_def e1 e2 e3 e4 e5 assms)
  also obtain err
  where "\<dots> = aform_val (e(n:=err)) (mult_aform' p n X Y)" and err: "err \<in> {-1 .. 1}"
    using err_le
    by (rule aform_val_consume_errorE)
  note this(1)
  finally have "aform_val (e(n := err)) (mult_aform' p n X Y) = aform_val e X * aform_val e Y"
    by simp
  with err show "\<exists>err. aform_val (e(n := err)) (mult_aform' p n X Y) =
      aform_val e X * aform_val e Y \<and> err \<in> {- 1..1}"
    by blast
qed


subsubsection \<open>Inf/Sup\<close>

definition "Inf_aform' p X = eucl_truncate_down p (fst X - tdev' p (snd X))"

definition "Sup_aform' p X = eucl_truncate_up p (fst X + tdev' p (snd X))"

lemma Inf_aform':
  shows "Inf_aform' p X \<le> Inf_aform X"
  unfolding Inf_aform_def Inf_aform'_def
  by (auto intro!: eucl_truncate_down_le add_left_mono tdev')

lemma Sup_aform':
  shows "Sup_aform X \<le> Sup_aform' p X"
  unfolding Sup_aform_def Sup_aform'_def
  by (rule eucl_truncate_up_le add_left_mono tdev')+

lemma Inf_aform_le_Sup_aform[intro]:
  "Inf_aform X \<le> Sup_aform X"
  by (simp add: Inf_aform_def Sup_aform_def algebra_simps)

lemma Inf_aform'_le_Sup_aform'[intro]:
  "Inf_aform' p X \<le> Sup_aform' p X"
  by (metis Inf_aform' Inf_aform_le_Sup_aform Sup_aform' order.trans)


subsubsection \<open>Inverse\<close>

definition inverse_aform'::"nat \<Rightarrow> nat \<Rightarrow> real aform \<Rightarrow> real aform" where
  "inverse_aform' p n X = (
    let l = Inf_aform' p X in
    let u = Sup_aform' p X in
    let a = min (abs l) (abs u) in
    let b = max (abs l) (abs u) in
    let sq = truncate_up p (b * b) in
    let alpha = - real_divl p 1 sq in
    let dmax = truncate_up p (real_divr p 1 a - alpha * a) in
    let dmin = truncate_down p (real_divl p 1 b - alpha * b) in
    let zeta' = truncate_up p ((dmin + dmax) / 2) in
    let zeta = if l < 0 then - zeta' else zeta' in
    let delta = truncate_up p (zeta - dmin) in
    let res1 = trunc_bound_eucl p (alpha * fst X) in
    let res2 = trunc_bound_eucl p (fst res1 + zeta) in
    let zs = trunc_bound_pdevs p (scaleR_pdevs alpha (snd X)) in
    (fst res2, pdev_upd (fst zs) n (sum_list' p [delta, snd res1, snd res2, snd zs])))"

lemma
  linear_lower:
  fixes x::real
  assumes "\<And>x. x \<in> {a .. b} \<Longrightarrow> (f has_field_derivative f' x) (at x within {a .. b})"
  assumes "\<And>x. x \<in> {a .. b} \<Longrightarrow> f' x \<le> u"
  assumes "x \<in> {a .. b}"
  shows "f b + u * (x - b) \<le> f x"
proof -
  from assms(2-)
    mvt_very_simple[of x b f "\<lambda>x. op * (f' x)",
      rule_format,
      OF _ has_derivative_subset[OF assms(1)[simplified has_field_derivative_def]]]
  obtain y where "y \<in> {x .. b}"  "f b - f x = (b - x) * f' y"
    by (auto simp: Bex_def ac_simps)
  moreover hence "f' y \<le> u" using assms by auto
  ultimately have "f b - f x \<le> (b - x) * u"
    by (auto intro!: mult_left_mono)
  thus ?thesis by (simp add: algebra_simps)
qed

lemma
  linear_upper:
  fixes x::real
  assumes "\<And>x. x \<in> {a .. b} \<Longrightarrow> (f has_field_derivative f' x) (at x within {a .. b})"
  assumes "\<And>x. x \<in> {a .. b} \<Longrightarrow> f' x \<le> u"
  assumes "x \<in> {a .. b}"
  shows "f x \<le> f a + u * (x - a)"
proof -
  from assms(2-)
    mvt_very_simple[of a x f "\<lambda>x. op * (f' x)",
      rule_format,
      OF _ has_derivative_subset[OF assms(1)[simplified has_field_derivative_def]]]
  obtain y where "y \<in> {a .. x}"  "f x - f a = (x - a) * f' y"
    by (auto simp: Bex_def ac_simps)
  moreover hence "f' y \<le> u" using assms by auto
  ultimately have "(x - a) * u \<ge> f x - f a"
    by (auto intro!: mult_left_mono)
  thus ?thesis by (simp add: algebra_simps)
qed

lemma
  fixes x a b::real
  assumes "a > 0"
  assumes "x \<in> {a ..b}"
  assumes "- inverse (b*b) \<le> alpha"
  shows inverse_linear_lower: "inverse b + alpha * (x - b) \<le> inverse x" (is ?lower)
    and inverse_linear_upper: "inverse x \<le> inverse a + alpha * (x - a)" (is ?upper)
proof -
  have deriv_inv:
    "\<And>x. x \<in> {a .. b} \<Longrightarrow> (inverse has_field_derivative - inverse (x*x)) (at x within {a .. b})"
    using assms
    by (auto intro!: derivative_eq_intros)
  show ?lower
    using assms
    by (intro linear_lower[OF deriv_inv])
        (auto simp: mult_mono intro!:  order_trans[OF _ assms(3)])
  show ?upper
    using assms
    by (intro linear_upper[OF deriv_inv])
        (auto simp: mult_mono intro!:  order_trans[OF _ assms(3)])
qed

lemma inverse_aform'E:
  fixes X::"real aform"
  assumes Inf_pos: "Inf_aform' p X > 0"
  assumes e: "e \<in> UNIV \<rightarrow> {-1 .. 1}"
    and xn: "pdevs_apply (snd X) n = 0"
  obtains err where
    "aform_val (e(n:=err)) (inverse_aform' p n X) = inverse (aform_val e X)"
    "err \<in> {-1 .. 1}"
proof atomize_elim
  define l where "l = Inf_aform' p X"
  define u where "u = Sup_aform' p X"
  define a where "a = min (abs l) (abs u)"
  define b where "b = max (abs l) (abs u)"
  define sq where "sq = truncate_up p (b * b)"
  define alpha where "alpha = - (real_divl p 1 sq)"
  define d_max' where "d_max' = truncate_up p (real_divr p 1 a - alpha * a)"
  define d_min' where "d_min' = truncate_down p (real_divl p 1 b - alpha * b)"
  define zeta where "zeta = truncate_up p ((d_min' + d_max') / 2)"
  define delta where "delta = truncate_up p (zeta - d_min')"
  note vars = l_def u_def a_def b_def sq_def alpha_def d_max'_def d_min'_def zeta_def delta_def
  let ?x = "aform_val e X"

  have "0 < l" using assms by (auto simp add: l_def Inf_aform_def)
  have "l \<le> u" by (auto simp: l_def u_def)

  hence a_def': "a = l" and b_def': "b = u" and "0 < a" "0 < b"
    using \<open>0 < l\<close> by (simp_all add: a_def b_def)
  have "0 < ?x"
    by (rule less_le_trans[OF Inf_pos order.trans[OF Inf_aform' Inf_aform], OF e])
  have "a \<le> ?x"
    by (metis order.trans Inf_aform e Inf_aform' a_def' l_def)
  have "?x \<le> b"
    by (metis order.trans Sup_aform e Sup_aform' b_def' u_def)
  hence "?x \<in> {?x .. b}"
    by simp

  have "- inverse (b * b) \<le> alpha"
    by (auto simp add: alpha_def inverse_mult_distrib[symmetric] inverse_eq_divide sq_def
      intro!: order_trans[OF real_divl] divide_left_mono truncate_up mult_pos_pos \<open>0 < b\<close>)

  {
    note \<open>0 < a\<close>
    moreover
    have "?x \<in> {a .. b}" using \<open>a \<le> ?x\<close> \<open>?x \<le> b\<close> by simp
    moreover
    note \<open>- inverse (b * b) \<le> alpha\<close>
    ultimately have "inverse ?x \<le> inverse a + alpha * (?x - a)"
      by (rule inverse_linear_upper)
    also have "\<dots> = alpha * ?x + (inverse a - alpha * a)"
      by (simp add: algebra_simps)
    also have "inverse a - (alpha * a) \<le> (real_divr p 1 a - alpha * a)"
      by (auto simp: inverse_eq_divide real_divr)
    also have "\<dots> \<le> (truncate_down p (real_divl p 1 b - alpha * b) +
          (real_divr p 1 a - alpha * a)) / 2 +
        (truncate_up p (real_divr p 1 a - alpha * a) -
          truncate_down p (real_divl p 1 b - alpha * b)) / 2"
      (is "_ \<le> (truncate_down p ?lb + ?ra) / 2 + (truncate_up p ?ra - truncate_down p ?lb) / 2")
      by (auto simp add: field_simps
        intro!: order_trans[OF _ add_left_mono[OF mult_left_mono[OF truncate_up]]])
    also have "(truncate_down p ?lb + ?ra) / 2 \<le>
        truncate_up p ((truncate_down p ?lb + truncate_up p ?ra) / 2)"
      by (intro truncate_up_le divide_right_mono add_left_mono truncate_up) auto
    also
    have "(truncate_up p ?ra - truncate_down p ?lb) / 2 + truncate_down p ?lb \<le>
        (truncate_up p ((truncate_down p ?lb + truncate_up p ?ra) / 2))"
      by (rule truncate_up_le) (simp add: field_simps)
    hence "(truncate_up p ?ra - truncate_down p ?lb) / 2 \<le> truncate_up p
        (truncate_up p ((truncate_down p ?lb + truncate_up p ?ra) / 2) - truncate_down p ?lb)"
      by (intro truncate_up_le) (simp add: field_simps)
    finally have "inverse ?x \<le> alpha * ?x + zeta + delta"
      by (auto simp: zeta_def delta_def d_min'_def d_max'_def right_diff_distrib ac_simps)
  } note upper = this

  {
    have "alpha * b + truncate_down p (real_divl p 1 b - alpha * b) \<le> inverse b"
      by (rule order_trans[OF add_left_mono[OF truncate_down]])
        (auto simp: inverse_eq_divide real_divl)
    hence "zeta + alpha * b \<le> delta + inverse b"
      by (auto simp: zeta_def delta_def d_min'_def d_max'_def right_diff_distrib
        intro!: order_trans[OF _ add_right_mono[OF truncate_up]])
    hence "alpha * ?x + zeta - delta \<le> inverse b + alpha * (?x - b)"
      by (simp add: algebra_simps)
    also
    {
      note \<open>0 < aform_val e X\<close>
      moreover
      note \<open>aform_val e X \<in> {aform_val e X .. b}\<close>
      moreover

      note \<open>- inverse (b * b) \<le> alpha\<close>
      ultimately
      have "inverse b + alpha * (aform_val e X - b) \<le> inverse (aform_val e X)"
        by (rule inverse_linear_lower)
    }
    finally have "alpha * (aform_val e X) + zeta - delta \<le> inverse (aform_val e X)" .
  } note lower = this


  have "inverse (aform_val e X) = alpha * (aform_val e X) + zeta +
      (inverse (aform_val e X) - alpha * (aform_val e X) - zeta)"
    (is "_ = _ + ?linerr")
    by simp
  also
  have "?linerr \<in> {- delta .. delta}"
    using lower upper by simp
  hence linerr_le: "abs ?linerr \<le> delta"
    by auto

  let ?z0 = "trunc_bound_eucl p (alpha * fst X)"
  from trunc_bound_euclE
  obtain e1 where abs_e1: "\<bar>e1\<bar> \<le> snd ?z0" and e1: "fst ?z0 = alpha * fst X + e1"
    by blast
  let ?z1 = "trunc_bound_eucl p (fst ?z0 + zeta)"
  from trunc_bound_euclE
  obtain e1' where abs_e1': "\<bar>e1'\<bar> \<le> snd ?z1" and e1': "fst ?z1 = fst ?z0 + zeta + e1'"
    by blast

  let ?zs = "trunc_bound_pdevs p (scaleR_pdevs alpha (snd X))"
  from trunc_bound_pdevsE[OF e]
  obtain e2 where abs_e2: "\<bar>e2\<bar> \<le> snd (?zs)"
    and e2: "pdevs_val e (fst ?zs) = pdevs_val e (scaleR_pdevs alpha (snd X)) + e2"
    by blast

  have "alpha * (aform_val e X) + zeta =
      aform_val (e(n:=0)) (inverse_aform' p n X) + (- e1 - e1' - e2)"
    unfolding inverse_aform'_def Let_def vars[symmetric]
    using \<open>0 < l\<close>
    by (simp add: aform_val_def assms e1') (simp add: e1 e2 algebra_simps)
  also
  let ?err = "(- e1 - e1' - e2 + inverse (aform_val e X) - alpha * aform_val e X - zeta)"
  {
    have "abs ?err \<le> abs ?linerr + abs e1 + abs e1' + abs e2"
      by simp
    also have "\<dots> \<le> delta + snd ?z0 + snd ?z1 + snd ?zs"
      by (blast intro: add_mono linerr_le abs_e1 abs_e1' abs_e2)
    also have "\<dots> \<le> pdevs_apply (snd (inverse_aform' p n X)) n"
      unfolding inverse_aform'_def Let_def vars[symmetric]
      using \<open>0 < l\<close>
      by (auto simp add: inverse_aform'_def pdevs_apply_trunc_pdevs assms vars[symmetric]
        intro!: order.trans[OF _ sum_list'_sum_list_le])
    finally have "abs ?err \<le> abs (pdevs_apply (snd (inverse_aform' p n X)) n)" by simp
  } note err_le = this
  have "aform_val (e(n := 0)) (inverse_aform' p n X) + (- e1 - e1' - e2) +
    (inverse (aform_val e X) - alpha * aform_val e X - zeta) =
    aform_val (e(n := 0)) (inverse_aform' p n X) + ?err"
    by simp
  also obtain err where "\<dots> = aform_val (e(n:=err)) (inverse_aform' p n X)"
    and err: "err \<in> {-1 .. 1}"
    using err_le
    by (rule aform_val_consume_errorE)
  note this(1)
  finally show "\<exists>err. aform_val (e(n := err)) (inverse_aform' p n X) = inverse (aform_val e X) \<and>
    err \<in> {- 1..1}"
    using err
    by auto
qed

definition "inverse_aform p d a =
  do {
    let l = Inf_aform' p a;
    let u = Sup_aform' p a;
    if (l \<le> 0 \<and> 0 \<le> u) then None
    else if (l \<le> 0) then (Some (uminus_aform (inverse_aform' p d (uminus_aform a))))
    else Some (inverse_aform' p d a)
  }"

lemma eucl_truncate_up_eq_eucl_truncate_down:
  "eucl_truncate_up p x = - (eucl_truncate_down p (- x))"
  by (auto simp: eucl_truncate_up_def eucl_truncate_down_def truncate_up_eq_truncate_down sum_negf)

lemma inverse_aformE:
  fixes X::"real aform"
  assumes e: "e \<in> UNIV \<rightarrow> {-1 .. 1}"
    and xn: "pdevs_apply (snd X) n = 0"
    and disj: "Inf_aform' p X > 0 \<or> Sup_aform' p X < 0"
  obtains err Y where
    "inverse_aform p n X = Some Y"
    "aform_val (e(n:=err)) Y = inverse (aform_val e X)"
    "err \<in> {-1 .. 1}"
proof -
  {
    assume neg: "Sup_aform' p X < 0"
    from neg have [simp]: "Inf_aform' p X \<le> 0"
      by (metis Inf_aform'_le_Sup_aform' dual_order.strict_trans1 less_asym not_less)
    from neg disj have "0 < Inf_aform' p (uminus_aform X)"
      by (auto simp: Inf_aform'_def Sup_aform'_def eucl_truncate_up_eq_eucl_truncate_down ac_simps)
    from inverse_aform'E[OF this e(1)] xn
    obtain err where err:
      "aform_val (e(n := err)) (inverse_aform' p n (uminus_aform X)) =
        inverse (aform_val e (uminus_aform X))"
       "err \<in>{-1..1}"
      by (auto simp: uminus_aform_def)
    let ?Y = "uminus_aform (inverse_aform' p n (uminus_aform X))"
    have "inverse_aform p n X = Some ?Y"
      "aform_val (e(n:=err)) ?Y = inverse (aform_val e X)"
      using err neg by (auto simp: inverse_aform_def)
    from this \<open>err \<in> _\<close> have ?thesis ..
  } moreover {
    assume pos: "Inf_aform' p X > 0"
    from pos have eq: "inverse_aform p n X = Some (inverse_aform' p n X)"
      by (auto simp: inverse_aform_def)
    from inverse_aform'E[OF pos e(1) xn]
    obtain err where err:
      "aform_val (e(n := err)) (inverse_aform' p n X) = inverse (aform_val e X)"
       "err \<in> {-1..1}"
       by auto
    have "aform_val (e(n:=err)) (inverse_aform' p n X) = inverse (aform_val e X)"
      using err by (auto simp: inverse_aform_def)
    from eq this \<open>err \<in> _\<close> have ?thesis ..
  } ultimately show ?thesis
    using assms by auto
qed

subsection \<open>Reduction (Summarization of Coefficients)\<close>
text \<open>\label{sec:affinesummarize}\<close>

definition "pdevs_of_centered_ivl r = (inner_scaleR_pdevs r One_pdevs)"

lemma pdevs_of_centered_ivl_eq_pdevs_of_ivl[simp]: "pdevs_of_centered_ivl r = pdevs_of_ivl (-r) r"
  by (auto simp: pdevs_of_centered_ivl_def pdevs_of_ivl_def algebra_simps intro!: pdevs_eqI)

lemma filter_pdevs_raw_nonzeros: "{i. filter_pdevs_raw s f i \<noteq> 0} = {i. f i \<noteq> 0} \<inter> {x. s x (f x)}"
  by (auto simp: filter_pdevs_raw_def)

lift_definition filter_pdevs::"(nat \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> 'a::real_vector pdevs \<Rightarrow> 'a pdevs" is filter_pdevs_raw
  by (simp add: filter_pdevs_raw_nonzeros)

lemma pdevs_apply_filter_pdevs[simp]:
  "pdevs_apply (filter_pdevs I x) i = (if I i (pdevs_apply x i) then pdevs_apply x i else 0)"
  by transfer (auto simp: filter_pdevs_raw_def)

lemma degree_filter_pdevs_le: "degree (filter_pdevs I x) \<le> degree x"
  by (rule degree_leI) (simp split: if_split_asm)

lemma pdevs_val_filter_pdevs:
  "pdevs_val e (filter_pdevs I x) = (\<Sum>i \<in> {..<degree x} \<inter> {i. I i (pdevs_apply x i)}. e i *\<^sub>R pdevs_apply x i)"
  by (auto simp: pdevs_val_sum if_distrib sum.inter_restrict degree_filter_pdevs_le degree_gt
    intro!: sum.mono_neutral_cong_left split: if_split_asm)

definition summarize_pdevs::
  "nat \<Rightarrow> (nat \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> 'a::executable_euclidean_space pdevs \<Rightarrow> 'a pdevs"
  where "summarize_pdevs p I d x =
    (let t = tdev' p (filter_pdevs (-I) x)
     in msum_pdevs d (filter_pdevs I x) (pdevs_of_centered_ivl t))"

definition summarize_threshold::
  "nat \<Rightarrow> real \<Rightarrow> nat \<Rightarrow> 'a::executable_euclidean_space pdevs \<Rightarrow> 'a pdevs"
  where "summarize_threshold p t d x = summarize_pdevs p
    (\<lambda>i y. infnorm y \<ge> t * infnorm (eucl_truncate_up p (tdev' p x))) d x"

lemma error_abs_euclE:
  fixes err::"'a::ordered_euclidean_space"
  assumes "abs err \<le> k"
  obtains e::"'a \<Rightarrow> real" where "err = (\<Sum>i\<in>Basis. (e i * (k \<bullet> i)) *\<^sub>R i)" "e \<in> UNIV \<rightarrow> {-1 .. 1}"
proof atomize_elim
  {
    fix i::'a
    assume "i \<in> Basis"
    hence "abs (err \<bullet> i) \<le> (k \<bullet> i)" using assms by (auto simp add: eucl_le[where 'a='a] abs_inner)
    hence "\<exists>e. (err  \<bullet> i = e * (k \<bullet> i)) \<and> e \<in> {-1..1}"
      by (rule error_absE) auto
  }
  then obtain e where e:
    "\<And>i. i \<in> Basis \<Longrightarrow> err \<bullet> i = e i * (k \<bullet> i)"
    "\<And>i. i \<in> Basis \<Longrightarrow> e i \<in> {-1 .. 1}"
    by metis
  have singleton: "\<And>b. b \<in> Basis \<Longrightarrow> (\<Sum>i\<in>Basis. e i * (k \<bullet> i) * (if i = b then 1 else 0)) =
    (\<Sum>i\<in>{b}. e i * (k \<bullet> i) * (if i = b then 1 else 0))"
    by (rule sum.mono_neutral_cong_right) auto
  show "\<exists>e::'a\<Rightarrow>real. err = (\<Sum>i\<in>Basis. (e i * (k \<bullet> i)) *\<^sub>R i) \<and> (e \<in> UNIV \<rightarrow> {-1..1})"
    using e
    by (auto intro!: exI[where x="\<lambda>i. if i \<in> Basis then e i else 0"] euclidean_eqI[where 'a='a]
      simp: inner_sum_left inner_Basis singleton)
qed

lemma summarize_pdevsE:
  fixes x::"'a::executable_euclidean_space pdevs"
  assumes e: "e \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes d: "degree x \<le> d"
  obtains e' where "pdevs_val e x = pdevs_val e' (summarize_pdevs p I d x)"
    "\<And>i. i < d \<Longrightarrow> e i = e' i"
    "e' \<in> UNIV \<rightarrow> {-1 .. 1}"
proof atomize_elim
  have "pdevs_val e x = (\<Sum>i<degree x. e i *\<^sub>R pdevs_apply x i)"
    by (auto simp add: pdevs_val_sum intro!: sum.cong)
  also have "\<dots> = (\<Sum>i \<in> {..<degree x} \<inter> {i. I i (pdevs_apply x i)}. e i *\<^sub>R pdevs_apply x i) +
    (\<Sum>i\<in> {..<degree x} - {i. I i (pdevs_apply x i)}. e i *\<^sub>R pdevs_apply x i)"
    (is "_ = ?large + ?small")
    by (subst sum.union_disjoint[symmetric]) (auto simp: ac_simps intro!: sum.cong)
  also have "?large = pdevs_val e (filter_pdevs I x)"
    by (simp add: pdevs_val_filter_pdevs)
  also have "?small = pdevs_val e (filter_pdevs (-I) x)"
    by (simp add: pdevs_val_filter_pdevs Diff_eq Collect_neg_eq)
  also
  have "abs \<dots> \<le> tdev' p (filter_pdevs (-I) x)" (is "abs ?r \<le> ?t")
    using e by (rule abs_pdevs_val_le_tdev')
  hence "?r \<in> {-?t .. ?t}"
    by (metis abs_le_D1 abs_le_D2 atLeastAtMost_iff minus_le_iff)
  from in_ivl_affine_of_ivlE[OF this] obtain e2
    where "?r = aform_val e2 (aform_of_ivl (- ?t) ?t)"
      and e2: "e2 \<in> UNIV \<rightarrow> {- 1..1}"
    by auto
  note this(1)
  also
  define e' where "e' i = (if i < d then e i else e2 (i - d))" for i
  hence "aform_val e2 (aform_of_ivl (- ?t) ?t) =
      pdevs_val (\<lambda>i. e' (i + d)) (pdevs_of_ivl (- ?t) ?t)"
    by (auto simp: aform_of_ivl_def aform_val_def)
  also
  have "pdevs_val e (filter_pdevs I x) = pdevs_val e' (filter_pdevs I x)"
    using assms by (auto simp: e'_def pdevs_val_sum intro!: sum.cong)
  finally have "pdevs_val e x =
      pdevs_val e' (filter_pdevs I x) + pdevs_val (\<lambda>i. e' (i + d)) (pdevs_of_ivl (- ?t) ?t)"
    .
  also note pdevs_val_msum_pdevs[symmetric, OF order_trans[OF degree_filter_pdevs_le d]]
  finally have "pdevs_val e x = pdevs_val e' (summarize_pdevs p I d x)"
    by (auto simp: summarize_pdevs_def Let_def)
  moreover have "e' \<in> UNIV \<rightarrow> {-1 .. 1}" using e e2 by (auto simp: e'_def Pi_iff)
  moreover have "\<forall>i < d. e' i = e i"
    by (auto simp: e'_def)
  ultimately show "\<exists>e'. pdevs_val e x = pdevs_val e' (summarize_pdevs p I d x) \<and>
      (\<forall>i<d. e i = e' i) \<and> e' \<in> UNIV \<rightarrow> {- 1..1}"
    by auto
qed


subsection \<open>Splitting with heuristics\<close>

definition "split_aform_largest_uncond X =
    (let (i, x) = max_pdev (snd X) in split_aform X i)"

definition "split_aform_largest p t X =
  split_aform_largest_uncond (fst X, summarize_threshold p t (degree_aform X) (snd X))"


subsection \<open>Approximating Expressions\<close>
text \<open>\label{sec:affineexpr}\<close>

datatype 'a realarith
  = Add "'a realarith" "'a realarith"
  | Minus "'a realarith"
  | Mult "'a realarith" "'a realarith"
  | Inverse "'a realarith"
  | Var nat 'a
  | Num real

datatype ('a, 'b) euclarith
  = AddE "('a, 'b) euclarith" "('a, 'b) euclarith"
  | ScaleR "'a realarith" 'b

fun interpret_realarith :: "'a::real_inner realarith \<Rightarrow> 'a list \<Rightarrow> real" where
  "interpret_realarith (Add a b) vs = interpret_realarith a vs + interpret_realarith b vs"
| "interpret_realarith (Minus a) vs = - interpret_realarith a vs"
| "interpret_realarith (Mult a b) vs = interpret_realarith a vs * interpret_realarith b vs"
| "interpret_realarith (Inverse a) vs = inverse (interpret_realarith a vs)"
| "interpret_realarith (Var i b) vs = (vs ! i) \<bullet> b"
| "interpret_realarith (Num r) vs = r"

fun interpret_euclarith ::
  "('a::{real_inner, scaleR, plus}, 'b) euclarith \<Rightarrow> 'a list \<Rightarrow> 'b::{plus, scaleR}"
where
  "interpret_euclarith (AddE a b) vs = interpret_euclarith a vs +\<^sub>E interpret_euclarith b vs"
| "interpret_euclarith (ScaleR a b) vs = (interpret_realarith a vs) *\<^sub>R b"

fun
  approx_realarith :: "nat \<Rightarrow> 'a::ordered_euclidean_space realarith \<Rightarrow> 'a aform list \<Rightarrow> nat \<Rightarrow>
    real aform option"
where
  "approx_realarith p (Add a b) vs l =
    do {
      a1 \<leftarrow> approx_realarith p a vs l;
      let d1 = max l (degree_aform a1);
      a2 \<leftarrow> approx_realarith p b vs d1;
      let d1 = max d1 (degree_aform a2);
      Some (add_aform' p d1 a1 a2)
    }"
| "approx_realarith p (Mult a b) vs l =
    do {
      a1 \<leftarrow> approx_realarith p a vs l;
      let d1 = max l (degree_aform a1);
      a2 \<leftarrow> approx_realarith p b vs (d1);
      let d2 = max d1 (degree_aform a2);
      Some (mult_aform' p d2 a1 a2)
    }"
| "approx_realarith p (Inverse a) vs m =
    do {
      a \<leftarrow> approx_realarith p a vs m;
      let d = max m (degree (snd a));
      inverse_aform p d a}"
| "approx_realarith p (Minus a) vs m =
    map_option uminus_aform (approx_realarith p a vs m)"
| "approx_realarith p (Num f) vs m =
    Some (num_aform f)"
| "approx_realarith p (Var i b) vs m =
  (if i < length vs
  then Some (inner_aform (vs ! i) b)
  else None)"

lemma uminus_aform_uminus_aform[simp]: "uminus_aform (uminus_aform z) = (z::'a::real_vector aform)"
  by (auto intro!: prod_eqI pdevs_eqI simp: uminus_aform_def)

lemma approx_realarith_Elem:
  assumes "vs = map (aform_val e') VS"
  assumes "e' \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes "approx_realarith p ra VS d = Some X"
  assumes "\<And>V. V \<in> set VS \<Longrightarrow> degree (snd V) \<le> d"
  shows
    "\<exists>e. e \<in> UNIV \<rightarrow> {-1 .. 1} \<and> (\<forall>i < d. e i = e' i) \<and> interpret_realarith ra vs = aform_val e X"
  using assms(1-4)
proof (induction ra arbitrary: X d e')
  case (Add ra1 ra2)
  thus ?case
  proof (cases "approx_realarith p ra1 VS d")
    fix Y1
    assume Y1: "approx_realarith p ra1 VS d = Some Y1"
    define d1 where "d1 = max d (degree_aform Y1)"
    from Y1
    show ?case
    proof (cases "approx_realarith p ra2 VS d1")
      fix Y2
      assume Y2: "approx_realarith p ra2 VS d1 = Some Y2"
      from Add(1)[OF Add(3-4) Y1 Add(6)] obtain e1 where e1:
        "e1 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d. e1 i = e' i)"
        "interpret_realarith ra1 vs = aform_val e1 Y1" by blast
      from this(2) have "vs = map (\<lambda>x. aform_val e1 x) VS"
        using Add(3,6)
        by (auto simp: aform_val_def pdevs_val_sum intro!: sum.cong)
          (metis dual_order.order_iff_strict less_trans)
      from Add(2)[OF this e1(1) Y2 order_trans[OF Add(6)]]
      obtain e2 where e2:
        "e2 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d1. e2 i = e1 i)"
        "interpret_realarith ra2 vs = aform_val e2 Y2"
        by (auto simp: d1_def)
      hence e1Y1: "aform_val e1 Y1 = aform_val e2 Y1" using e1
        by (auto simp: aform_val_def pdevs_val_sum d1_def)
      define d2 where "d2 = max d1 (degree_aform Y2)"
      have "pdevs_apply (snd Y1) d2 = 0" "pdevs_apply (snd Y2) d2 = 0"
        by (auto simp: d1_def d2_def)
      from add_aform'E[of e2 Y1 d2 Y2, OF e2(1) this]
      obtain err where err:
        "aform_val e2 (add_aform Y1 Y2) = aform_val (e2(d2 := err)) (add_aform' p d2 Y1 Y2)"
         "err \<in> {-1..1}"
         by blast
      define e3 where "e3 = e2(d2 := err)"
      have "e2(max (max d (degree_aform Y1)) (degree_aform Y2) := err) =
        (\<lambda>a. if a = max (max d (degree_aform Y1)) (degree_aform Y2)
          then err else e2 a)"
        by auto
      thus ?case
        using err e2 e1 Add Y1 Y2
        by (auto intro!: exI[where x=e3] simp: e3_def d2_def d1_def aform_val_add_aform e1Y1)
    qed (insert Add, simp add: d1_def)
  qed simp
next
  case (Mult ra1 ra2)
  thus ?case
  proof (cases "approx_realarith p ra1 VS d")
    fix Y1
    assume Y1: "approx_realarith p ra1 VS d = Some Y1"
    define d1 where "d1 = max d (degree_aform Y1)"
    from Y1 show ?case
    proof (cases "approx_realarith p ra2 VS d1")
      fix Y2
      assume Y2: "approx_realarith p ra2 VS d1 = Some Y2"
      from Mult(1)[OF Mult(3-4) Y1 Mult(6)] obtain e1 where e1:
        "e1 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d. e1 i = e' i)"
        "interpret_realarith ra1 vs = aform_val e1 Y1" by blast
      from this(2) have "vs = map (\<lambda>x. aform_val e1 x) VS"
        using Mult(3,6)
        by (auto simp: aform_val_def pdevs_val_sum intro!: sum.cong)
          (metis dual_order.order_iff_strict less_trans)
      from Mult(2)[OF this e1(1) Y2 order_trans[OF Mult(6)]]
      obtain e2 where e2:
        "e2 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d1. e2 i = e1 i)"
        "interpret_realarith ra2 vs = aform_val e2 Y2"
        by (auto simp: d1_def)
      hence e1Y1: "aform_val e1 Y1 = aform_val e2 Y1" using e1
        by (auto simp: aform_val_def pdevs_val_sum d1_def)
      define d2 where "d2 = max d1 (degree_aform Y2)"
      have "pdevs_apply (snd Y1) d2 = 0" "pdevs_apply (snd Y2) d2 = 0"
        by (auto simp: d1_def d2_def)
      from mult_aform'E[of e2 Y1 d2 Y2,OF e2(1) this]
      obtain err where err:
        "aform_val (e2(d2 := err)) (mult_aform' p d2 Y1 Y2) =
          aform_val e2 Y1 * aform_val e2 Y2"
        "err \<in> {-1 .. 1}" by blast
      define e3 where "e3 = e2(d2 := err)"
      have "e2(max (max d (degree_aform Y1)) (degree_aform Y2) := err) =
        (\<lambda>a. if a = max (max d (degree_aform Y1)) (degree_aform Y2)
          then err else e2 a)"
        by auto
      thus ?case
        using err e2 e1 Mult Y1 Y2
        by (auto intro!: exI[where x=e3] simp: e3_def d2_def d1_def e1Y1)
    qed (insert Mult, simp add: d1_def)
  qed simp
next
  case (Minus ra)
  have "approx_realarith p ra VS d = Some (uminus_aform X)"
    using Minus by auto
  from Minus(1)[OF Minus(2-3) this Minus(5)] obtain e where e:
    "e \<in> UNIV \<rightarrow> {-1..1}" "(\<forall>i<d. e i = e' i)"
    "interpret_realarith ra vs = aform_val e (uminus_aform X)"
    by auto
  thus ?case
    by (auto simp: aform_val_def uminus_aform_def)
next
  case (Num f)
  thus ?case
    by (auto simp: num_aform_def aform_val_def)
next
  case (Var x y)
  thus ?case
    by (auto simp: aform_val_def inner_aform_def inner_add_left split: if_split_asm
      intro!: exI[where x=e'])
next
  case (Inverse ra)
  thus ?case
  proof (cases "approx_realarith p ra VS d")
    fix Y
    assume Y: "approx_realarith p ra VS d = Some Y"
    define d1 where "d1 = max d (degree_aform Y)"
    have d1: "pdevs_apply (snd Y) d1 = 0"
      by (auto simp: d1_def uminus_aform_def)
    from Inverse(1)[OF Inverse(2-3) Y Inverse (5)]
    obtain e where e: "e \<in> UNIV \<rightarrow> {-1..1}" "(\<forall>i<d. e i = e' i)" and affine_pos:
      "interpret_realarith ra vs = aform_val e Y"
      by auto
    have "Inf_aform' p Y > 0 \<or> Sup_aform' p Y < 0"
      using Inverse Y
      by (auto split: if_split_asm simp: Let_def inverse_aform_def)
    from inverse_aformE[OF e(1) d1 this]
    obtain err Z where Z:
      "inverse_aform p d1 Y = Some Z"
      "aform_val (e(d1 := err)) Z = inverse (aform_val e Y)"
      "err \<in> {- 1..1}" .
    with Inverse(4) have "X = Z"
      by (auto simp: d1_def Y)
    show ?case
      using e \<open>err \<in> _\<close>
      by (auto simp: affine_pos d1_def fun_upd_def \<open>X = Z\<close> Z(2)[symmetric]
          intro!: exI[where x="e(d1:=err)"])
  qed simp
qed

fun approx_euclarith ::
  "nat \<Rightarrow> ('a::ordered_euclidean_space, 'b::ordered_euclidean_space) euclarith \<Rightarrow> 'a aform list \<Rightarrow>
    nat \<Rightarrow> 'b aform option"
where
  "approx_euclarith p (AddE a b) vs l =
    do {
      a1 \<leftarrow> approx_euclarith p a vs l;
      let d1 = max l (degree_aform a1);
      a2 \<leftarrow> approx_euclarith p b vs d1;
      let d1 = max d1 (degree_aform a2);
      Some (add_aform a1 a2)
    }"
| "approx_euclarith p (ScaleR a b) vs m =
    map_option (\<lambda>a. aform_scaleR a b) (approx_realarith p a vs m::real aform option)"

lemma approx_euclarith_Elem:
  assumes "vs = map (aform_val e') VS"
  assumes "e' \<in> UNIV \<rightarrow> {-1 .. 1}"
  assumes "approx_euclarith p ra VS d = Some X"
  assumes "\<And>V. V \<in> set VS \<Longrightarrow> degree_aform V \<le> d"
  shows
    "\<exists>e. e \<in> UNIV \<rightarrow> {-1 .. 1} \<and> (\<forall>i < d. e i = e' i) \<and> interpret_euclarith ra vs = aform_val e X"
  using assms
proof (induction ra arbitrary: X d e')
  case (AddE ra1 ra2)
  thus ?case
  proof (cases "approx_euclarith p ra1 VS d")
    fix Y1
    assume Y1: "approx_euclarith p ra1 VS d = Some Y1"
    define d1 where "d1 = max d (degree_aform Y1)"
    from Y1 show ?case
    proof (cases "approx_euclarith p ra2 VS d1")
      fix Y2
      assume Y2: "approx_euclarith p ra2 VS d1 = Some Y2"
      from AddE(1)[OF AddE(3-4) Y1 AddE(6)] obtain e1 where e1:
        "e1 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d. e1 i = e' i)"
        "interpret_euclarith ra1 vs = aform_val e1 Y1" by blast
      from this(2) have "vs = map (\<lambda>x. aform_val e1 x) VS"
        using AddE(3,6)
        by (auto simp: aform_val_def pdevs_val_sum intro!: sum.cong)
          (metis dual_order.order_iff_strict less_trans)
      from AddE(2)[OF this e1(1) Y2 order_trans[OF AddE(6)]]
      obtain e2 where e2:
        "e2 \<in> UNIV \<rightarrow> {-1..1}"
        "(\<forall>i<d1. e2 i = e1 i)"
        "interpret_euclarith ra2 vs = aform_val e2 Y2"
        by (auto simp: d1_def)
      hence e1Y1: "aform_val e1 Y1 = aform_val e2 Y1" using e1
        by (auto simp: aform_val_def pdevs_val_sum d1_def)
      define d2 where "d2 = max d1 (degree_aform Y2)"
      have "pdevs_apply (snd Y1) d2 = 0" "pdevs_apply (snd Y2) d2 = 0"
        by (auto simp: d1_def d2_def)
      from aform_val_add_aform[of e2 Y1 Y2]
      have "aform_val e2 (add_aform Y1 Y2) = aform_val e2 Y1 + aform_val e2 Y2"
        by blast
      thus ?case
        using e2 e1 AddE Y1 Y2
        by (auto intro!: exI[where x=e2] simp: plusE_def d2_def d1_def aform_val_add_aform e1Y1)
    qed (insert AddE, simp add: d1_def)
  qed simp
next
  case (ScaleR a b)
  then obtain Y where Y: "approx_realarith p a VS d = Some Y"
    and X: "X = aform_scaleR Y b" by auto
  from approx_realarith_Elem[OF ScaleR(1-2) Y ScaleR(4)]
  obtain e where e: "e \<in> UNIV \<rightarrow> {-1..1}" "(\<forall>i<d. e i = e' i)"
      "interpret_realarith a vs = aform_val e Y"
    by auto
  show ?case
    using e X Y
    by (auto intro!: exI[where x=e])
qed

lemma fold_max_mono:
  fixes x::"'a::linorder"
  shows "x \<le> y \<Longrightarrow> fold max zs x \<le> fold max zs y"
  by (induct zs arbitrary: x y) (auto intro!: Cons simp: max_def)

lemma fold_max_le_self:
  fixes y::"'a::linorder"
  shows "y \<le> fold max ys y"
  by (induct ys) (auto intro: order_trans[OF _ fold_max_mono])

lemma fold_max_le:
  fixes x::"'a::linorder"
  shows "x \<in> set xs \<Longrightarrow> x \<le> fold max xs z"
  by (induct xs arbitrary: x z) (auto intro: order_trans[OF _ fold_max_le_self])

definition "approx_euclarith_outer p t ea as =
  do {
    let d = (fold max (map degree_aform as) 0);
    s \<leftarrow> approx_euclarith p ea as d;
    Some (apsnd (summarize_threshold p t (max d (degree_aform s))) s)
  }"

lemma approx_euclarith_outer2_shift:
  assumes "approx_euclarith_outer p t ea VS' = Some X"
  assumes "vs \<in> Joints VS"
  assumes "length vs' = length VS'"
  assumes "length VS = length VS'"
  assumes "set (zip vs' VS') = set (zip vs VS)"
  shows "(vs, interpret_euclarith ea vs') \<in> Joints2 VS X"
proof -
  from assms
  have subset: "set (zip vs VS) \<subseteq> set (zip vs' VS')"
    and l1: "length vs' = length VS'"
    and l2: "length vs = length VS"
    by (auto simp: Joints_def valuate_def)
  have vs': "vs' \<in> Joints VS'"
    using assms(2-5)
    by (rule Joints_set_zip)
  define d where "d = fold max (map degree_aform (VS')) 0"
  from assms obtain a b where approx: "approx_euclarith p ea VS' d = Some (a, b)"
    and X: "X = (a, summarize_threshold p t (max d (degree_aform (a, b))) b)"
    by (cases "approx_euclarith p ea VS' (fold max (map degree_aform (VS')) 0)")
      (force simp: approx_euclarith_outer_def d_def)+
  from assms obtain e' where vs: "vs = (map (aform_val e') VS)" and e': "e' \<in> UNIV \<rightarrow> {-1 .. 1}"
    by (auto simp: Joints_def valuate_def)
  from approx_euclarith_Elem[OF refl e' approx]
  obtain e where e: "e \<in> UNIV \<rightarrow> {- 1..1}"
     and e_eq: "\<And>i. i<d \<Longrightarrow> e i = e' i"
     and aform_val: "interpret_euclarith ea (map (aform_val e') VS') = aform_val e (a, b)"
     by (auto simp: d_def fold_max_le)
  let ?summ = "\<lambda>i y. t * infnorm (eucl_truncate_up p (tdev' p b)) \<le> infnorm y"
  have d: "degree b \<le> max (fold max (map degree_aform (VS')) 0) (degree b)"
    by simp
  obtain e''' where
    e''': "e''' \<in> UNIV \<rightarrow> {- 1..1}"
      "\<And>i. i < max (fold max (map degree_aform (VS')) 0) (degree b) \<Longrightarrow> e i = e''' i"
      "pdevs_val e b = pdevs_val e''' (snd (the (approx_euclarith_outer p t ea VS')))"
    by (rule summarize_pdevsE[OF e d, of p ?summ])
      (auto simp: assms X d_def summarize_threshold_def)
  have e'_eq_e''': "\<And>i. i <d \<Longrightarrow> e' i = e''' i"
    using e_eq e'''(2)
    by (auto simp: d_def)
  have VS_degreeD: "\<And>a b. (a, b) \<in> set VS' \<Longrightarrow> degree b \<le> d"
    unfolding d_def
    by (rule fold_max_le) force
  have "vs' = map (aform_val e') VS'"
    using e' e''' assms
    by (intro zipped_subset_mapped_Elem[OF vs]) (auto simp: l2)
  hence "(vs', interpret_euclarith ea vs') \<in> Joints2 VS' X"
    using e''' vs e' X aform_val approx
    by (auto simp: Joints2_def Joints_def valuate_def aform_val_def approx_euclarith_outer_def
        Let_def d_def
      intro!: pdevs_val_degree_cong[OF refl] max.strict_coboundedI1 image_eqI[where x=e''']
      dest!: VS_degreeD intro!: e'_eq_e''')
  then obtain e
  where e: "vs' = (map (aform_val e) VS')" "interpret_euclarith ea vs' = aform_val e X"
    "\<And>i. e i \<in> {-1..1}"
    by (force simp: Joints2_def valuate_def)
  thus ?thesis
    using zipped_subset_mapped_Elem[OF e(1,3)  l1 l2 subset]
    by (auto simp: Joints2_def valuate_def intro!: exI[where x=e])
qed

lemma approx_euclarith_outer:
  assumes "approx_euclarith_outer p t e VS = Some R"
  assumes "vs \<in> Joints VS"
  shows "(vs, interpret_euclarith e vs) \<in> Joints2 VS R"
  using approx_euclarith_outer2_shift[OF assms, of vs] assms
  by (auto simp: Joints2_def Joints_def valuate_def)

lemma length_eq_NilI: "length [] = length []"
  and length_eq_ConsI: "length xs = length ys \<Longrightarrow> length (x#xs) = length (y#ys)"
  by auto


subsection \<open>Definition of Approximating Function using Affine Arithmetic\<close>

lemma interpret_Floatreal: "interpret_realarith (realarith.Num (real_of_float f)) vs = (real_of_float f)"
  by simp
lemmas reify_euclarith_eqs =

  interpret_euclarith.simps
  interpret_realarith.simps(1-5)
  interpret_Floatreal

lemma floatify_thms: "1 \<equiv> real_of_float 1" "0 \<equiv> real_of_float 0"
  "numeral k \<equiv> real_of_float (numeral k)"
  by simp_all

primrec max_Var_realarith where
  "max_Var_realarith (Add a b) = max (max_Var_realarith a) (max_Var_realarith b)"
| "max_Var_realarith (Mult a b) = max (max_Var_realarith a) (max_Var_realarith b)"
| "max_Var_realarith (Inverse a) = max_Var_realarith a"
| "max_Var_realarith (Minus a) = max_Var_realarith a"
| "max_Var_realarith (Num a) = 0"
| "max_Var_realarith (Var i c) = Suc i"

primrec max_Var_euclarith where
  "max_Var_euclarith (AddE a b) = max (max_Var_euclarith a) (max_Var_euclarith b)"
| "max_Var_euclarith (ScaleR x a) = max_Var_realarith x"

lemma take_greater_eqI: "take c xs = take c ys \<Longrightarrow> c \<ge> a \<Longrightarrow> take a xs = take a ys"
proof (induct xs arbitrary: a c ys)
  case (Cons x xs) note ICons = Cons
  thus ?case
  proof (cases a)
    case (Suc b)
    thus ?thesis using Cons(2,3)
    proof (cases ys)
      case (Cons z zs)
      from ICons obtain d where c: "c = Suc d"
        by (auto simp: Cons Suc dest!: Suc_le_D)
      show ?thesis
        using ICons(2,3)
        by (auto simp: Suc Cons c intro: ICons(1))
    qed simp
  qed simp
qed (metis le_0_eq take_eq_Nil)

lemma take_max_eqD:
  "take (max a b) xs = take (max a b) ys \<Longrightarrow> take a xs = take a ys \<and> take b xs = take b ys"
  by (metis max.cobounded1 max.cobounded2 take_greater_eqI)

lemma take_Suc_eq: "take (Suc n) xs = (if n < length xs then take n xs @ [xs ! n] else xs)"
  by (auto simp: take_Suc_conv_app_nth)

lemma
  interpret_realarith_eq_take_max_VarI:
  assumes "take (max_Var_realarith ra) ys = take (max_Var_realarith ra) zs"
  shows "interpret_realarith ra ys = interpret_realarith ra zs"
  using assms
  by (induct ra) (auto dest!: take_max_eqD simp: take_Suc_eq split: if_split_asm)

lemma
  interpret_euclarith_eq_take_max_VarI:
  assumes "take (max_Var_euclarith ea) ys = take (max_Var_euclarith ea) zs"
  shows "interpret_euclarith ea ys = interpret_euclarith ea zs"
  using assms
  by (induct ea) (auto dest!: take_max_eqD interpret_realarith_eq_take_max_VarI)

lemma approx_euclarith_outer2_shift_addvars:
  assumes "approx_euclarith_outer p t ea VS' = Some X"
  assumes "vs \<in> Joints VS"
  assumes "length vs' = length VS'"
  assumes "length VS = length VS'"
  assumes "set (zip vs' VS') = set (zip vs VS)"
  assumes "take (max_Var_euclarith ea) vs'' = take (max_Var_euclarith ea) vs'"
  shows "(vs, interpret_euclarith ea vs'') \<in> Joints2 VS X"
  using approx_euclarith_outer2_shift[OF assms(1-5)]
    interpret_euclarith_eq_take_max_VarI[OF assms(6)]
  by simp

ML \<open>
fun dest_interpret_euclarith (Const (@{const_name "interpret_euclarith"}, _) $ b $ xs) = (b, xs)
  | dest_interpret_euclarith t = raise TERM ("interpret_euclarith", [t])

fun euclarithT aty bty = Type (@{type_name "euclarith"}, [aty, bty])

fun aformT aty = HOLogic.mk_prodT (aty, Type (@{type_name "pdevs"}, [aty]))

fun mk_optionT ty = Type (@{type_name "option"}, [ty])

fun mk_None ty = Const (@{const_name "None"}, mk_optionT ty)
fun mk_Some ty x = Const (@{const_name "Some"}, ty --> mk_optionT ty) $ x

fun approx_euclarith_const aty bty = (Const (@{const_name "approx_euclarith_outer"},
  @{typ nat} --> @{typ real} --> euclarithT aty bty --> HOLogic.listT (aformT aty) -->
  mk_optionT (aformT bty)))

fun dest_approx_euclarith (Const (@{const_name "approx_euclarith_outer"}, _) $ p $ t $ ea $ xs) =
      (p, t, ea, xs)
  | dest_approx_euclarith t = raise TERM ("approx_euclarith_outer", [t])

fun Joints_const aty = (Const (@{const_name "Joints"},
  (aty |> aformT |> HOLogic.listT) --> (aty |> HOLogic.listT |> HOLogic.mk_setT)))

fun Joints2_const aty bty = (Const (@{const_name "Joints2"},
  (aty |> aformT |> HOLogic.listT) --> (bty |> aformT) -->
    (HOLogic.mk_prodT(aty |> HOLogic.listT, bty) |> HOLogic.mk_setT)))

fun length_const ty = Const (@{const_name size}, HOLogic.listT ty --> @{typ nat})

fun floatify_conv ctxt = Raw_Simplifier.rewrite ctxt true @{thms floatify_thms}

fun conss ty xs t = fold_rev (fn t => fn ts => HOLogic.cons_const ty $ t $ ts) xs t

fun print_term ctxt t = Pretty.writeln (Syntax.pretty_term ctxt t)

fun approximate_affine (name, term) lthy =
  let
    val t_in = Syntax.read_term lthy term
    val euclidify_thm = t_in |> Thm.cterm_of lthy |> euclidify lthy
    val t = euclidify_thm |> Thm.prop_of |> Logic.dest_equals |> snd
    val ty = fastype_of t
    val (atys, bty) = strip_type ty
    val aty = case distinct (fn (x, y) => x = y) atys of
        [aty] => aty
      | _ => error "Only one type for arguments supported"
    fun free aty n = Free (n, aty)
    val (prec::thres::qs::args, ctxt') =
      Variable.variant_fixes ("prec"::"thres"::"qs"::map (fn _ => "x") atys) lthy
    val t_beta = fold (fn x => fn t => betapply (t, x)) (map (free aty) args) t
    val ct = Thm.cterm_of ctxt' t_beta
    val atypat = (("'a", 0), @{sort "{real_inner, scaleR, plus}" })
    val btypat = (("'b", 0), @{sort "{scaleR, plus}" })
    val thms = map (Thm.instantiate (
      [(atypat, Thm.ctyp_of ctxt' aty), (btypat, Thm.ctyp_of ctxt' bty)], [])) @{thms reify_euclarith_eqs}
    val thm = (floatify_conv ctxt' then_conv Reification.conv ctxt' thms) ct
    val interpret = Thm.prop_of thm |> Logic.dest_equals |> snd
    val (ea, xs) = dest_interpret_euclarith interpret
    val xs_aform = (map (fn t => Free (apsnd aformT (dest_Free t))) (HOLogic.dest_list xs))
    val approx = approx_euclarith_const aty bty $
      Free (prec, @{typ nat}) $
      Free (thres, @{typ real}) $
      ea $
      conss (aformT aty) xs_aform (Free (qs, HOLogic.listT (aformT aty)))
    val approx_raw = fold_rev absfree
      (prec::thres::args@[qs] ~~
        (@{typ nat}::(@{typ real})::map aformT atys@[HOLogic.listT (aformT aty)]))
      approx
    val ((approx, (_, def_raw)), lthy') =
      Local_Theory.define ((name, NoSyn), (Binding.empty_atts, approx_raw)) lthy
    val (_, lthy'') = Local_Theory.notes
      [((Thm.def_binding name, [Code.add_default_eqn_attrib Code.Equation]), [([def_raw], [])])] lthy'

    (* correctness theorem *)
    (* shows "(vs, interpret_euclarith ea vs) \<in> Joints2 VS X" *)
    val (prec::thres::R::qs::QS::args, lthy3) =
      Variable.variant_fixes ("prec"::"thres"::"R"::"qs"::"QS"::map (fn _ => "x") atys) lthy''
    val (ARGS, lthy4) = Variable.variant_fixes (map (fn _ => "X") args) lthy3
    val vs = (map (fn n => Free (n, aty)) args)
    val VS = (map (fn n => Free (n, aformT aty)) ARGS)
    val xsqs = conss aty (HOLogic.dest_list xs) (Free (qs, HOLogic.listT aty))
    val vsqs = conss aty vs (Free (qs, HOLogic.listT aty))
    val VSQS = conss (aformT aty) VS (Free (QS, HOLogic.listT (aformT aty)))
    val joints = HOLogic.mk_mem (vsqs, Joints_const aty $ VSQS)
      |> HOLogic.mk_Trueprop
      |> Thm.cterm_of lthy4
    val approx_args = Free (prec, HOLogic.natT) :: Free (thres, @{typ real}) :: VS @
      [Free (QS, HOLogic.listT (aformT aty))]
    val approx_term = betapplys (approx, approx_args)
    val approx_eq = HOLogic.mk_eq (approx_term, mk_Some (aformT bty) (Free (R, aformT bty)))
      |> HOLogic.mk_Trueprop |> Thm.cterm_of lthy4

    val interpret_eq = HOLogic.mk_mem (HOLogic.mk_prod (vsqs, betapplys (t_in, vs)),
      Joints2_const aty bty $ VSQS $ Free (R, aformT bty))
      |> HOLogic.mk_Trueprop
    val len_qs_eq =
      HOLogic.mk_eq
        (length_const aty $ Free (qs, HOLogic.listT aty),
          length_const (aformT aty) $ Free (QS, HOLogic.listT (aformT aty)))
      |> HOLogic.mk_Trueprop |> Thm.cterm_of lthy4
    val ([joints_thm, approx_eq_thm, len_qs_eq_thm], lthy5) =
      Assumption.add_assumes [joints, approx_eq, len_qs_eq] lthy4
    val thm' = singleton (Proof_Context.export ctxt' lthy) thm
    val approx_eq_thm' = approx_eq_thm
      |> Conv.fconv_rule (Conv.bottom_conv (fn _ => Conv.try_conv (Conv.rewr_conv def_raw)) lthy5)

    fun len_tac ctxt =
      TRY (REPEAT (resolve_tac ctxt @{thms length_eq_ConsI} 1))
      THEN resolve_tac ctxt [len_qs_eq_thm, refl] 1
    val (_, _, _, XSQS) = betapplys (approx_raw, approx_args) |> dest_approx_euclarith
    val len_eq =
      HOLogic.mk_eq (length_const aty $ xsqs, length_const (aformT aty) $ XSQS)
      |> HOLogic.mk_Trueprop
    val len_thm = Goal.prove lthy5 [] [] len_eq (len_tac o #context)

    val interpret_eq_thm = Goal.prove lthy5 [] [] interpret_eq
      (fn {context = ctxt, ...} =>
        CONVERSION
          (Conv.bottom_conv (fn _ => Conv.try_conv (Conv.rewr_conv euclidify_thm)) ctxt) 1
        THEN CONVERSION (Conv.bottom_conv (fn _ => Conv.try_conv (Conv.rewr_conv thm')) ctxt) 1
        THEN resolve_tac ctxt [approx_eq_thm' RS @{thm approx_euclarith_outer2_shift_addvars}] 1
        THEN resolve_tac ctxt [joints_thm] 1
        THEN resolve_tac ctxt [len_thm] 1 (* instantiates *)
        THEN len_tac ctxt
        THEN Local_Defs.unfold_tac ctxt @{thms zip_Cons_Cons zip_Nil set_simps}
        THEN blast_tac ctxt 1
        THEN simp_tac ctxt 1
        )
    val correct_thm = singleton (Proof_Context.export lthy5 lthy'') interpret_eq_thm
    val (_, lthy''') = Local_Theory.notes [((name, []), [([correct_thm], [])])] lthy''
  in
     lthy'''
  end
\<close>

ML \<open>
val _ =
  Outer_Syntax.local_theory @{command_keyword approximate_affine}
    "define approximation of term"
    (Parse.binding -- Parse.term >> approximate_affine)
\<close>


subsection \<open>Generic operations on Affine Forms in Euclidean Space\<close>

lemma sum_list_Basis_list[simp]: "sum_list (map f Basis_list) = (\<Sum>b\<in>Basis. f b)"
  by (subst sum_list_distinct_conv_sum_set) (auto simp: Basis_list distinct_Basis_list)

subsubsection \<open> Binary operations \<close>

fun binary_componentwise'::
  "'a::zero list \<Rightarrow> ('a realarith \<Rightarrow> 'a realarith \<Rightarrow> 'a realarith) \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> ('a, 'a) euclarith"
where
  "binary_componentwise' [] f i j = ScaleR (Num 0) 0"
| "binary_componentwise' (b#bs) f i j = AddE (ScaleR (f (Var i b) (Var j b)) b) (binary_componentwise' bs f i j)"

lemma interpret_binary_componentwise':
  shows "interpret_euclarith (binary_componentwise' Bs f i j) xs =
    (\<Sum>b\<leftarrow>Bs. ((interpret_realarith (f (Var i b) (Var j b)) xs) *\<^sub>R b))"
  by (induct Bs) (auto simp: algebra_simps plusE_def)


subsubsection \<open>Adding\<close>

definition "add_ea = binary_componentwise' Basis_list Add"

lemma interpret_add_ea[simp]:
  "interpret_euclarith (add_ea i j) xs = xs!i + xs!j"
  unfolding interpret_binary_componentwise' add_ea_def
  by (auto simp: euclidean_representation inner_add_left[symmetric])

definition "add_aform_componentwise prec tol X Y YS =
  approx_euclarith_outer prec tol (add_ea 0 1) (X # Y # YS)"

lemma
  add_aform_componentwise:
  assumes "add_aform_componentwise prec tol X Y YS = Some R"
  assumes "x # y # xs \<in> Joints (X # Y # YS)"
  shows "((x + y) # x # y # xs) \<in> Joints (R # X # Y # YS)"
  using assms
    approx_euclarith_outer2_shift[OF
      assms[simplified add_aform_componentwise_def],
      where vs'="x # y # xs"]
  by (auto simp: valuate_def Joints2_def Joints_def)


subsubsection \<open> pointwise multiplication \<close>

context euclidean_space begin

definition hadamard::"'a \<Rightarrow> 'a \<Rightarrow> 'a" (infix "\<odot>" 70) where
  "hadamard a b = (\<Sum>i\<in>Basis. ((a \<bullet> i) * (b \<bullet> i)) *\<^sub>R i)"

end

interpretation hadamard: comm_semiring_0_cancel "op +" "op -" 0 "op \<odot>"
  by standard (simp_all add: hadamard_def algebra_simps sum.distrib)

lemma hadamard_inner_Basis: "c \<in> Basis \<Longrightarrow> (a \<odot> b) \<bullet> c = (a \<bullet> c) * (b \<bullet> c)"
  by (auto simp: hadamard_def inner_sum_left inner_Basis if_distrib sum.delta cong: if_cong)

lemma hadamard_real[simp]: "(op \<odot>::real\<Rightarrow>real\<Rightarrow>real) = op *"
  by (force simp: hadamard_def)

definition "hadamard_ea = binary_componentwise' Basis_list Mult"

lemma interpret_hadamard_ea[simp]:
  "interpret_euclarith (hadamard_ea i j) xs = (xs ! i) \<odot> (xs ! j)"
  unfolding interpret_binary_componentwise' hadamard_ea_def hadamard_def
  by (auto simp: euclidean_representation)


subsubsection \<open>Unary operations\<close>

fun unary_componentwise'::
  "'a::zero list \<Rightarrow> ('a realarith \<Rightarrow> 'a realarith) \<Rightarrow> nat \<Rightarrow> ('a, 'a) euclarith"
where
  "unary_componentwise' [] f i = ScaleR (Num 0) 0"
| "unary_componentwise' (b#bs) f i = AddE (ScaleR (f (Var i b)) b) (unary_componentwise' bs f i)"

lemma interpret_unary_componentwise':
  shows "interpret_euclarith (unary_componentwise' Bs f i) xs =
    (\<Sum>b\<leftarrow>Bs. ((interpret_realarith (f (Var i b)) xs) *\<^sub>R b))"
  by (induct Bs) (auto simp: algebra_simps plusE_def)


subsection \<open>Scale with expression\<close>

definition scaleR_ea::"'a realarith \<Rightarrow> nat \<Rightarrow> ('a, 'a::executable_euclidean_space) euclarith"
where "scaleR_ea x i = unary_componentwise' Basis_list (Mult x) i"

lemma interpret_scaleR_ea[simp]:
  "interpret_euclarith (scaleR_ea x i) xs = interpret_realarith x xs *\<^sub>R (xs!i)"
  unfolding scaleR_ea_def interpret_unary_componentwise' sum_list_Basis_list euclidean_representation
  by (auto simp: divide_simps intro!: euclidean_eqI[where 'a='a])


subsubsection \<open>Scale with fraction\<close>

definition "scaleQ_aform_componentwise prec tol x z Y YS =
  approx_euclarith_outer prec tol (scaleR_ea (Mult (Num x) (Inverse (Num z))) 0) (Y # YS)"

lemma
  scaleQ_aform_componentwise:
  assumes "scaleQ_aform_componentwise prec tol x z Y YS = Some R"
  assumes "y # ys \<in> Joints (Y # YS)"
  shows "(((x / z) *\<^sub>R y) # y # ys) \<in> Joints (R # Y # YS)"
  using assms
    approx_euclarith_outer2_shift[OF assms[simplified scaleQ_aform_componentwise_def], of "y#ys"]
  by (auto simp: valuate_def Joints2_def Joints_def inverse_eq_divide)


subsubsection \<open>scale with an interval\<close>

definition "scaleR_aform_ivl prec tol a b Y YS =
  (let c = hd Basis_list
  in
  approx_euclarith_outer prec tol (scaleR_ea (Var 0 c) 1)
    ((((a + b)/2) *\<^sub>R c, pdev_upd zero_pdevs (fold max (map degree_aform (Y#YS)) 0) ((\<bar>b-a\<bar>/2)*\<^sub>Rc)) # Y # YS))"

lemma hd_Basis_list[simp]: "hd Basis_list \<in> Basis"
  unfolding Basis_list[symmetric]
  by (rule hd_in_set) (auto simp: set_empty[symmetric])

lemma pdevs_val_domain_cong:
  assumes "b = d"
  assumes "\<And>i. i \<in> pdevs_domain b \<Longrightarrow> a i = c i"
  shows "pdevs_val a b = pdevs_val c d"
  using assms
  by (auto simp: pdevs_val_pdevs_domain)

lemma fresh_JointsI:
  assumes "xs \<in> Joints XS"
  assumes "list_all (\<lambda>Y. pdevs_domain (snd X) \<inter> pdevs_domain (snd Y) = {}) XS"
  assumes "x \<in> Affine X"
  shows "x#xs \<in> Joints (X#XS)"
  using assms
  unfolding Joints_def Affine_def valuate_def
proof safe
  fix e e'::"nat \<Rightarrow> real"
  assume H: "list_all (\<lambda>Y. pdevs_domain (snd X) \<inter> pdevs_domain (snd Y) = {}) XS"
    "e \<in> UNIV \<rightarrow> {- 1..1}"
    "e' \<in> UNIV \<rightarrow> {- 1..1}"
  have "\<And>a b i. \<forall>Y\<in>set XS. pdevs_domain (snd X) \<inter> pdevs_domain (snd Y) = {} \<Longrightarrow>
       pdevs_apply b i \<noteq> 0 \<Longrightarrow>
       pdevs_apply (snd X) i \<noteq> 0 \<Longrightarrow>
       (a, b) \<notin> set XS"
    by (metis (poly_guards_query) IntI all_not_in_conv in_pdevs_domain snd_eqD)
  with H show
    "aform_val e' X # map (aform_val e) XS \<in> (\<lambda>e. map (aform_val e) (X # XS)) ` (UNIV \<rightarrow> {- 1..1})"
    by (intro image_eqI[where x = "\<lambda>i. if i \<in> pdevs_domain (snd X) then e' i else e i"])
      (auto simp: aform_val_def list_all_iff Pi_iff intro!: pdevs_val_domain_cong)
qed

lemma
  scaleR_aform_ivl:
  assumes "scaleR_aform_ivl prec tol a b Y YS = Some R"
  assumes "y # ys \<in> Joints (Y#YS)"
  assumes "c \<in> {a ..b}"
  shows "((c *\<^sub>R y) # y # ys) \<in> Joints (R # Y # YS)"
proof -
  have deg_le_one: "degree (pdevs_of_ivl a b) \<le> 1"
    by (rule order_trans[OF degree_pdevs_of_ivl_le]) (auto simp: Basis_list_real_def)
  define i where "i = fold max (map degree_aform (Y#YS)) 0"
  have i: "\<And>Z. Z \<in> set (Y#YS) \<Longrightarrow> degree_aform Z \<le> i"
    unfolding i_def
    by (rule fold_max_le) auto
  let ?ivl = "(((a + b)/2)*\<^sub>R(hd Basis_list::'a),
      pdev_upd zero_pdevs i (((b - a)/2)*\<^sub>R(hd Basis_list::'a)))"
  from in_ivl_affine_of_ivlE[OF \<open>c\<in>{a..b}\<close>] obtain e where e: "e \<in> UNIV \<rightarrow> {- 1..1}"
    and c: "c = aform_val e (aform_of_ivl a b)"
    by auto
  note c
  also have "\<dots> = aform_val (\<lambda>i. if i = 0 then e i else 0) (aform_of_ivl a b)"
    using deg_le_one
    by (auto simp: aform_val_def aform_of_ivl_def intro!: pdevs_val_degree_cong)
  also have "\<dots> = (a + b)/2 +
      (\<Sum>i<degree (pdevs_of_ivl a b).
        (if i = 0 then e i else 0) * pdevs_apply (pdevs_of_ivl a b) i)"
    by (auto simp: aform_val_def aform_of_ivl_def pdevs_val_sum)
  also have
    "(\<Sum>i<degree (pdevs_of_ivl a b). (if i = 0 then e i else 0) * pdevs_apply (pdevs_of_ivl a b) i) =
    (\<Sum>i\<in>{0}. (if i = 0 then e i else 0) * pdevs_apply (pdevs_of_ivl a b) i)"
    by (cases "degree (pdevs_of_ivl a b)", simp)
      (rule sum.mono_neutral_cong_right, auto)
  also have "\<dots> = e 0 * (b - a)/2"
    by (simp add: pdevs_of_ivl_def Basis_list_real_def)
  finally have "c = (a + b)/2 + e 0 * (b - a)/2" by simp
  from this
  have in_Aff: "c*\<^sub>Rhd Basis_list \<in> Affine ?ivl"
    using assms e
    by (auto simp: Affine_def valuate_def simp: aform_val_def algebra_simps Basis_list_real_def
      intro!: image_eqI[where x="(\<lambda>_. 0)(i:=e 0)"])

  have "pdevs_domain (snd ?ivl) \<inter> pdevs_domain (snd Y) = {}"
    using i[of Y] by (auto split: if_split_asm)
  moreover
  have "list_all (\<lambda>Y. pdevs_domain (snd ?ivl) \<inter> pdevs_domain (snd Y) = {}) YS"
    using i
    by (force split: if_split_asm simp: list_all_iff)
  ultimately have Joints: "c*\<^sub>Rhd Basis_list#y#ys \<in> Joints (?ivl#Y#YS)"
    by (auto intro!: fresh_JointsI[OF assms(2) _ in_Aff])
  with approx_euclarith_outer2_shift[OF assms(1)[simplified scaleR_aform_ivl_def Let_def] Joints,
    of "c*\<^sub>R(hd Basis_list)#y#ys"] assms
  have "(c *\<^sub>R hd Basis_list # y # ys,
      interpret_euclarith (scaleR_ea (Var 0 (hd Basis_list)) 1) (c *\<^sub>R hd Basis_list # y # ys))
    \<in> Joints2 (?ivl # Y # YS) R"
    by (force simp: valuate_def Joints2_def Joints_def i_def)
  thus ?thesis
    by (auto simp: valuate_def Joints2_def Joints_def)
qed

lemma scaleR_aform_ivl_commute:
  "scaleR_aform_ivl prec tol a b Y YS = scaleR_aform_ivl prec tol b a Y YS"
  by (simp add: scaleR_aform_ivl_def abs_minus_commute add.commute)

lemma
  scaleR_aform_ivl_segment:
  assumes "scaleR_aform_ivl prec tol a b Y YS = Some R"
  assumes "y # ys \<in> Joints (Y#YS)"
  assumes "c \<in> closed_segment a b"
  shows "((c *\<^sub>R y) # y # ys) \<in> Joints (R # Y # YS)"
  using assms scaleR_aform_ivl_commute[of prec tol "max a b" "min a b" Y YS]
  by (auto split: if_split_asm
      simp: closed_segment_eq_real_ivl min_def max_def
      intro: scaleR_aform_ivl
      dest: scaleR_aform_ivl)

subsection \<open>operations on expressions\<close>

definition "minus_ea = binary_componentwise' Basis_list (\<lambda>i j. Add i (Minus j))"
definition "scaleR_eas i   j = scaleR_ea (Var i (hd Basis_list)) j"
definition "scaleQ_eas i d j = scaleR_ea (Mult (Var i (hd Basis_list)) (Inverse (Num d))) j"

lemma interpret_minus_ea[simp]:
  "interpret_euclarith (minus_ea i j) xs = (xs ! i) - (xs ! j)"
  unfolding interpret_binary_componentwise' minus_ea_def
  by (auto simp: euclidean_representation inner_diff_left[symmetric])

lemma interpret_scaleR_ea_Var[simp]:
  "interpret_euclarith (scaleR_eas i j) xs = (xs ! i \<bullet> hd Basis_list) *\<^sub>R (xs ! j)"
  by (auto simp: scaleR_eas_def)

lemma interpret_scaleQ[simp]:
  "interpret_euclarith (scaleQ_eas i d j) xs = (xs ! i \<bullet> hd Basis_list / d) *\<^sub>R xs ! j"
  by (auto simp: scaleQ_eas_def inverse_eq_divide)

subsection \<open>encoding of reals in Euclidean space\<close>

definition eor::"real \<Rightarrow> 'a::ordered_euclidean_space"
  where "eor r = r *\<^sub>R One"
definition "roe e = e \<bullet> (hd Basis_list)"

lemma roe_eor[simp]: "roe (eor r) = r"
  by (auto simp: eor_def roe_def)

lemma roe_scaleR[simp]: "roe (r *\<^sub>R One) = r"
  by (auto simp: roe_def)

lemma eor_nonneg_iff[simp]: "0 \<le> eor h \<longleftrightarrow> 0 \<le> h"
  by (auto simp: eucl_le[where 'a='a] eor_def)

lemma eor_le_iff[simp]: "eor a \<le> eor b \<longleftrightarrow> a \<le> b"
  by (auto simp: eucl_le[where 'a='a] eor_def)

lemma eor_inner_Basis_le_iff[simp]: "i \<in> Basis \<Longrightarrow> eor x \<bullet> i \<le> eor y \<bullet> i \<longleftrightarrow> x \<le> y"
  by (auto simp: eucl_le[where 'a='a] eor_def)

lemma le_roe[simp]: "eor a \<le> h \<Longrightarrow> a \<le> roe h"
  and roe_le[simp]: "h \<le> eor a \<Longrightarrow> roe h \<le> a"
  by (auto simp: eucl_le[where 'a = 'a] roe_def eor_def)

lemma Bex_Icc_zero_scaleR_One_iff_old: "(\<forall>h\<in>{eor a .. eor b}. P (roe h)) \<longleftrightarrow> (\<forall>h\<in>{a..b}. P h)"
proof safe
  fix h
  assume "h \<in> {a .. b}"
  then have "eor h \<in> {eor a .. eor b}"
    by (auto simp: )
  moreover
  assume "\<forall>h::'a\<in>{eor a .. eor b}. P (roe h)"
  ultimately have "P (roe (eor h::'a))"
    by (auto simp del: roe_eor)
  then show "P h" by simp
qed simp

lemma Bex_Icc_zero_scaleR_One_iff[simp]:
  assumes "\<And>h. P (eor (roe h)) = P h"
  shows "Ball {eor a .. eor b} (\<lambda>h. P h) \<longleftrightarrow> (\<forall>h\<in>{a..b}. P (eor h))"
  using assms
  by (meson atLeastAtMost_iff eor_le_iff le_roe roe_le)

definition "ra_of_ea v = Var v (hd Basis_list)"

lemma interpret_ra_of_ea[simp]: "interpret_realarith (ra_of_ea v) xs = (xs ! v) \<bullet> hd Basis_list"
  by (auto simp: ra_of_ea_def)


subsection \<open>fresh Variables\<close>

fun fresh_realarith where
  "fresh_realarith (Add a b) x \<longleftrightarrow> fresh_realarith a x \<and> fresh_realarith b x"
| "fresh_realarith (Mult a b) x \<longleftrightarrow> fresh_realarith a x \<and> fresh_realarith b x"
| "fresh_realarith (Minus a) x \<longleftrightarrow> fresh_realarith a x"
| "fresh_realarith (Inverse a) x \<longleftrightarrow> fresh_realarith a x"
| "fresh_realarith (Num a) x \<longleftrightarrow> True"
| "fresh_realarith (Var y b) x \<longleftrightarrow> (x \<noteq> y)"

lemma fresh_realarith_subst:
  assumes "fresh_realarith e x"
  assumes "x < length vs"
  shows "interpret_realarith e (vs[x:=v]) = interpret_realarith e vs"
  using assms
  by (induction e) auto

lemma fresh_realarith_max_Var:
  assumes "max_Var_realarith ea \<le> i"
  shows "fresh_realarith ea i"
  using assms
  by (induction ea) auto

fun fresh_euclarith where
  "fresh_euclarith (AddE a b) x \<longleftrightarrow> fresh_euclarith a x \<and> fresh_euclarith b x"
| "fresh_euclarith (ScaleR a b) x \<longleftrightarrow> fresh_realarith a x"

lemma fresh_euclarith_subst:
  assumes "fresh_euclarith ea i"
  assumes "i < length xs"
  shows "interpret_euclarith ea (xs[i:=x]) = interpret_euclarith ea xs"
  using assms
  by (induction ea) (auto simp: fresh_realarith_subst)

lemma fresh_euclarith_max_Var:
  assumes "max_Var_euclarith ea \<le> i"
  shows "fresh_euclarith ea i"
  using assms
  by (induction ea) (auto simp: fresh_realarith_max_Var)

lemma
  interpret_euclarith_take_eqI:
  assumes "take n ys = take n zs"
  assumes "max_Var_euclarith ea \<le> n"
  shows "interpret_euclarith ea ys = interpret_euclarith ea zs"
  by (rule interpret_euclarith_eq_take_max_VarI) (rule take_greater_eqI[OF assms])

lemma
  interpret_realarith_fresh_eqI:
  assumes "\<And>i. fresh_realarith ea i \<or> (i < length ys \<and> i < length zs \<and> ys ! i = zs ! i)"
  shows "interpret_realarith ea ys = interpret_realarith ea zs"
  using assms
  by (induction ea) force+

lemma
  interpret_euclarith_fresh_eqI:
  assumes "\<And>i. fresh_euclarith ea i \<or> (i < length ys \<and> i < length zs \<and> ys ! i = zs ! i)"
  shows "interpret_euclarith ea ys = interpret_euclarith ea zs"
  using assms
  apply (induction ea)
  subgoal by (force simp: interpret_realarith_fresh_eqI intro: interpret_realarith_fresh_eqI)
  subgoal by simp (metis interpret_realarith_fresh_eqI)
  done

subsection \<open>Derivatives\<close>

fun derive_realarith where
  "derive_realarith (Add a b) x dx = Add (derive_realarith a x dx) (derive_realarith b x dx)"
| "derive_realarith (Minus a) x dx = Minus (derive_realarith a x dx)"
| "derive_realarith (Mult a b) x dx = Add (Mult (derive_realarith a x dx) b) (Mult a (derive_realarith b x dx))"
| "derive_realarith (Inverse a) x dx = Minus (Mult (derive_realarith a x dx) (Inverse (Mult a a)))"
| "derive_realarith (Var y b) x dx = (if x = y then (Var dx b) else Num 0)"
| "derive_realarith (Num r) x dx = Num 0"

fun isdiff_realarith where
  "isdiff_realarith (Add a b) xs \<longleftrightarrow> isdiff_realarith a xs \<and> isdiff_realarith b xs"
| "isdiff_realarith (Mult a b) xs \<longleftrightarrow> isdiff_realarith a xs \<and> isdiff_realarith b xs"
| "isdiff_realarith (Minus a) xs \<longleftrightarrow> isdiff_realarith a xs"
| "isdiff_realarith (Inverse a) xs \<longleftrightarrow> isdiff_realarith a xs \<and> interpret_realarith a xs \<noteq> 0"
| "isdiff_realarith (Num a) xs \<longleftrightarrow> True"
| "isdiff_realarith (Var y b) xs \<longleftrightarrow> True"

lemma
  assumes "\<And>i. e'' i \<le> 1"
  assumes "\<And>i. -1 \<le> e'' i"
  shows Inf_aform'_le: "Inf_aform' p r \<le> aform_val e'' r"
    and Sup_aform'_le: "aform_val e'' r \<le> Sup_aform' p r"
  by (auto intro!: order_trans[OF Inf_aform'] order_trans[OF _ Sup_aform'] Inf_aform Sup_aform
    simp: Affine_def valuate_def intro!: image_eqI[where x=e''] assms)

lemma derive_realarith:
  assumes "fresh_realarith e j"
  assumes "i < length vs"
  assumes "j < length vs"
  assumes "isdiff_realarith e vs"
  shows "((\<lambda>x. interpret_realarith e (vs[i:=x])) has_derivative
    (\<lambda>dx. interpret_realarith (derive_realarith e i j) (vs[j:=dx]))) (at (vs ! i))"
  using assms
  by (induct e) (auto intro!: derivative_eq_intros simp: fresh_realarith_subst)

fun derive_euclarith where
  "derive_euclarith (AddE a b) x dx = AddE (derive_euclarith a x dx) (derive_euclarith b x dx)"
| "derive_euclarith (ScaleR a b) x dx = ScaleR (derive_realarith a x dx) b"

fun isdiff_euclarith where
  "isdiff_euclarith (AddE a b) x \<longleftrightarrow> isdiff_euclarith a x \<and> isdiff_euclarith b x"
| "isdiff_euclarith (ScaleR a b) x \<longleftrightarrow> isdiff_realarith a x"

fun isndiff_euclarith where
  "isndiff_euclarith 0       _ _  _       xs \<longleftrightarrow> True"
| "isndiff_euclarith _       _ _  []      xs \<longleftrightarrow> False"
| "isndiff_euclarith (Suc n) e x (dx#dxs) xs \<longleftrightarrow>
    isdiff_euclarith e xs \<and>
    isndiff_euclarith n (derive_euclarith e x dx) x dxs xs"

lemma derive_euclarith:
  assumes "fresh_euclarith e j"
  assumes "i < length vs"
  assumes "j < length vs"
  assumes "isdiff_euclarith e vs"
  shows "((\<lambda>x. interpret_euclarith e (vs[i:=x])) has_derivative
    (\<lambda>dx. interpret_euclarith (derive_euclarith e i j) (vs[j:=dx]))) (at (vs ! i))"
  using assms
  by (induct e) (auto intro!: derivative_eq_intros derive_realarith simp: plusE_def)

lemma isdiff_realarithI:
  assumes vs: "vs = map (aform_val e') VS"
  assumes e': "e' \<in> funcset UNIV {-1 .. 1}"
  assumes "approx_realarith p e VS d \<noteq> None"
  assumes "\<And>V. V \<in> set VS \<Longrightarrow> degree (snd V) \<le> d"
  shows "isdiff_realarith e vs"
  using assms
proof (induction e arbitrary: d)
  case (Inverse a)
  from \<open>approx_realarith p (Inverse a) VS d \<noteq> None\<close>
  obtain r s
  where Some: "approx_realarith p a VS d = Some (r, s)"
    and nonzero: "Inf_aform' p (r, s) \<le> 0 \<and> Sup_aform' p (r, s) < 0 \<or> Inf_aform' p (r, s) > 0"
    by (auto simp: bind_eq_Some_conv Let_def inverse_aform_def split: if_split_asm)
  from approx_realarith_Elem[OF vs e' Some Inverse(5)]
  obtain e'' where e'': "e'' \<in> funcset UNIV {- 1..1}"
    and "interpret_realarith a vs = aform_val e'' (r, s)"
    by auto
  note this(2)
  also have "aform_val e'' (r, s) \<in> {Inf_aform' p (r, s) .. Sup_aform' p (r, s)}"
    using e'' by (auto intro!: Inf_aform'_le Sup_aform'_le)
  also have "\<dots> \<subseteq> UNIV - {0}" using nonzero by auto
  finally have "interpret_realarith a vs \<noteq> 0" by auto
  with Some Inverse(1)[of d] Inverse(2-)
  show ?case by auto
qed (force simp: Let_def bind_eq_Some_conv)+

lemma isdiff_euclarithI:
  assumes vs: "vs = map (aform_val e') VS"
  assumes e': "e' \<in> funcset UNIV {-1 .. 1}"
  assumes "approx_euclarith p e VS d \<noteq> None"
  assumes "\<And>V. V \<in> set VS \<Longrightarrow> degree (snd V) \<le> d"
  shows "isdiff_euclarith e vs"
  using assms
  by (induction e arbitrary: d) (force intro!: isdiff_realarithI simp: bind_eq_Some_conv)+

lemma fresh_realarith_derive_realarith:
  assumes "fresh_realarith ea n"
  assumes "fresh_realarith ea k"
  assumes "n \<noteq> k"
  shows "fresh_realarith (derive_realarith ea i n) k"
  using assms
  by (induction ea) auto

lemma fresh_euclarith_derive_realarith:
  assumes "fresh_euclarith ea n"
  assumes "fresh_euclarith ea k"
  assumes "n \<noteq> k"
  shows "fresh_euclarith (derive_euclarith ea i n) k"
  using assms
  by (induction ea) (auto simp: fresh_realarith_derive_realarith)

lemma max_Var_realarith_derive_realarith:
  assumes "max_Var_realarith ea \<le> n"
  shows "max_Var_realarith (derive_realarith ea i n) \<le> Suc (max i n)"
  using assms
  by (induction ea) auto

lemma max_Var_euclarith_derive_euclarith:
  assumes "max_Var_euclarith ea \<le> n"
  shows "max_Var_euclarith (derive_euclarith ea i n) \<le> Suc (max i n)"
  using assms
  by (induction ea) (auto simp: max_Var_realarith_derive_realarith)

lemma
  isdiff_realarith_eq_take_max_VarI:
  assumes "take (max_Var_realarith ra) ys = take (max_Var_realarith ra) zs"
  shows "isdiff_realarith ra ys = isdiff_realarith ra zs"
  using assms
  by (induct ra) (auto dest: take_max_eqD interpret_realarith_eq_take_max_VarI)

lemma isdiff_euclarith_eq_take_max_VarI:
  "take (max_Var_euclarith ea) ys = take (max_Var_euclarith ea) zs \<Longrightarrow>
    isdiff_euclarith ea ys = isdiff_euclarith ea zs"
  by (induct ea) (auto dest!: take_max_eqD isdiff_realarith_eq_take_max_VarI)

lemma
  isdiff_euclarith_take_eqI:
  assumes "take n ys = take n zs"
  assumes "max_Var_euclarith ea \<le> n"
  shows "isdiff_euclarith ea ys = isdiff_euclarith ea zs"
  by (rule isdiff_euclarith_eq_take_max_VarI) (rule take_greater_eqI[OF assms])

lemma
  isdiff_realarith_freshI:
  assumes "\<And>i. fresh_realarith ea i \<or> (i < length ys \<and> i < length zs \<and> ys ! i = zs ! i)"
  assumes "isdiff_realarith ea zs"
  shows "isdiff_realarith ea ys"
  using assms
  apply (induction ea)
  subgoal by auto
  subgoal by auto
  subgoal by auto
  subgoal by auto (metis interpret_realarith_fresh_eqI)
  subgoal by auto
  subgoal by auto
  done

lemma
  isdiff_euclarith_freshI:
  assumes "\<And>i. fresh_euclarith ea i \<or> (i < length ys \<and> i < length zs \<and> ys ! i = zs ! i)"
  assumes "isdiff_euclarith ea zs"
  shows "isdiff_euclarith ea ys"
  using assms
  apply (induction ea)
  subgoal by auto
  subgoal using isdiff_realarith_freshI by auto
  done


subsection \<open>Proving Formulas with AA\<close>

datatype ('a, 'b) euclarithform =
  Pos "('a, 'b) euclarith"
| Nonneg "('a, 'b) euclarith"
| Conj "('a, 'b) euclarithform" "('a, 'b) euclarithform"
| Disj "('a, 'b) euclarithform" "('a, 'b) euclarithform"

fun interpret_euclarithform :: "('a::real_inner, 'b::ordered_euclidean_space) euclarithform \<Rightarrow> 'a list \<Rightarrow> bool" where
"interpret_euclarithform (Pos a) vs      = (eucl_less 0 (interpret_euclarith a vs))" |
"interpret_euclarithform (Nonneg a) vs = (interpret_euclarith a vs \<ge> 0)" |
"interpret_euclarithform (Conj f g) vs \<longleftrightarrow> interpret_euclarithform f vs \<and> interpret_euclarithform g vs" |
"interpret_euclarithform (Disj f g) vs \<longleftrightarrow> interpret_euclarithform f vs \<or> interpret_euclarithform g vs"

fun approx_euclarithform :: "nat \<Rightarrow> real \<Rightarrow> ('a::ordered_euclidean_space, 'b::executable_euclidean_space) euclarithform \<Rightarrow> 'a aform list \<Rightarrow> bool" where
"approx_euclarithform p t  (Pos a) vs = (case approx_euclarith_outer p t a vs of None \<Rightarrow> False | Some a' \<Rightarrow> (eucl_less 0 (Inf_aform' p a')))" |
"approx_euclarithform p t (Nonneg a) vs = (case approx_euclarith_outer p t a vs of None \<Rightarrow> False | Some a' \<Rightarrow> (0 \<le> Inf_aform' p a'))" |
"approx_euclarithform p t (Conj f g) vs \<longleftrightarrow> approx_euclarithform p t f vs \<and> approx_euclarithform p t g vs" |
"approx_euclarithform p t (Disj f g) vs \<longleftrightarrow> approx_euclarithform p t f vs \<or> approx_euclarithform p t g vs"

lemma eucl_less_le_trans:
  fixes x y::"'a :: ordered_euclidean_space"
  shows "eucl_less x y \<Longrightarrow> y \<le> z \<Longrightarrow> eucl_less x z"
  by (force simp: eucl_less_def eucl_le[where 'a='a])

lemma approx_euclarithform:
  assumes "xs \<in> Joints XS"
  assumes "approx_euclarithform p t f XS"
  shows "interpret_euclarithform f xs"
  using assms
  by (induction f)
    (auto
      split: option.split_asm
      dest!: approx_euclarith_outer
      elim!: Joints2E
      intro!: eucl_less_le_trans[OF _ Inf_aform'_le] order.trans[OF _ Inf_aform'_le])

primrec max_Var_euclarithform where
  "max_Var_euclarithform (Pos a) = max_Var_euclarith a"
| "max_Var_euclarithform (Nonneg a) = max_Var_euclarith a"
| "max_Var_euclarithform (Conj f g) = max (max_Var_euclarithform f) (max_Var_euclarithform g)"
| "max_Var_euclarithform (Disj f g) = max (max_Var_euclarithform f) (max_Var_euclarithform g)"

definition true_euclarithform :: "nat \<Rightarrow> ('a, 'b::ordered_real_vector) euclarithform"
  where "true_euclarithform _ = Nonneg (ScaleR (Num (real_of_float 0)) 0)"

lemma interpret_euclarithform_euclarithform[simp]:
  "interpret_euclarithform (true_euclarithform i) xs = True"
  by (auto simp: true_euclarithform_def)

end

