clear

set obs 4000

gen id = _n

gen eta1 = rnormal()
gen eta2 = rnormal()

* Generate 5 irrelevant factors that might affect each of the
* different responses on the pretest
gen f1 = rnormal()
gen f2 = rnormal()
gen f3 = rnormal()
gen f4 = rnormal()
gen f5 = rnormal()

* Now let's apply the treatment
expand 2, gen(t)  // double our data

gen treat=0
replace treat=1 if ((id<=_N/4)&(t==1))

* Now let's generate our changes in etas
replace eta1 = eta1 + treat*1 + t*.5
replace eta2 = eta2 + treat*.5 + t*1

* Finally we generate out pre and post test responses
gen v1 = f1*.8  + eta1*1  + eta2*.4  // eta1 has more loading on
gen v2 = f2*1.5 + eta1*1  + eta2*.3  // the first few questions
gen v3 = f3*2   + eta1*1  + eta2*1  
gen v4 = f4*1   + eta1*.2 + eta2*1  // eta2 has more loading on
gen v5 = f5*1   +           eta2*1  // the last few questions

* END Simulation
* Begin Estimation

sem (L1 -> v1 v2 v3 v4 v5) (L2 -> v1 v2 v3 v4 v5) if t==0
predict L1 L2, latent

sem (L1 -> v1 v2 v3 v4 v5) (L2 -> v1 v2 v3 v4 v5) if t==1
predict L12 L22, latent

replace  L1 = L12 if t==1
replace  L2 = L22 if t==1

* Now let's see if our latent predicted factors are correlated with our true factors.
corr eta1 eta2 L1 L2

* We can see already that we are having problems.  
* I am no expert on SEM so I don't really know what is going wrong except
* that eta1 is reasonably highly correlated with L1 and L2 and
* eta2 is less highly correlated with L1 and L2 equally each
* individually, which is not what we want.

* Well too late to stop now.  Let's do our diff in diff estimation.
* In this case we can easily accomplish it by generating one more variable.

* Let's do a seemingly unrelated regression form to make a single joint estimator.

sureg (L1 t id treat) (L2 t id treat)

* Now we have estimated the effect of the treatment given a control for the
* time effect and individual differences.  Can we be sure of our results?
* Not quite.  We are treating L1 and L2 like observed varaibles rather than
* random variables we estimated.  We need to adjust out standard errors to
* take this into account.  The easiest way though computationally intensive is
* to use a bootstrap routine.

* This is how it is done.  Same as above but we will use temporary variables.
cap program drop SEMdnd
program define SEMdnd

  tempvar L1 L2 L12 L22
  
  sem (L1 -> v1 v2 v3 v4 v5) (L2 -> v1 v2 v3 v4 v5) if t==0
  predict `L1' `L2', latent
  
  sem (L1 -> v1 v2 v3 v4 v5) (L2 -> v1 v2 v3 v4 v5) if t==1
  predict `L12' `L22', latent

  replace  `L1' = `L12' if t==1
  replace  `L2' = `L22' if t==1

  sureg (`L1' t id treat) (`L2' t id treat)

  drop `L1' `L2' `L12' `L22'

end

SEMdnd  // Looking good

* This should do it though I don't hae the machine time available to wait
* for it to finish.
bs , rep(200) cluster(id): SEMdnd 
