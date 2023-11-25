# Linear mixed-effects modeling

For this first set of exercises, we will generate simulated data corresponding to an experiment with a single, two-level factor (independent variable) that is within-subjects and between-items.  Let's imagine that the experiment involves lexical decisions to a set of words (e.g., is "PINT" a word or nonword?), and the dependent variable is response time (in milliseconds), and the independent variable is word type (noun vs verb).  We want to treat both subjects and words as random factors (so that we can generalize to the population of events where subjects encounter words).

The general linear model for our study is:

$$Y_{si} = \beta_0 + S_{0s} + I_{0i} + (\beta_1 + S_{1s})X_{i} + e_{si}$$

where:

|           |       |                                                   |
|-----------|-------|---------------------------------------------------|
| $Y_{si}$  | `Y`   | RT for subject $s$ responding to item $i$;        |
| $\beta_0$ | `mu`  | grand mean;                                       |
| $S_{0s}$  | `sri` | random intercept for subject $s$;                 |
| $I_{0i}$  | `iri` | random intercept for item $i$;                    |
| $\beta_1$ | `eff` | fixed effect of word type (slope);                |
| $S_{1s}$  | `srs` | by-subject random slope;                          |
| $X_{i}$   | `x`   | deviation-coded predictor variable for word type; |
| $e_{si}$  | `err` | residual error.                                   |

**Subjects**

$$\left<S_{0i},S_{1i}\right> \sim N(\left<0,0\right>, \Sigma)$$

where

$$\Sigma = \left(\begin{array}{cc}{\tau_{00}}^2 & \rho\tau_{00}\tau_{11} \\ \rho\tau_{00}\tau_{11} & {\tau_{11}}^2 \\ \end{array}\right) $$

**Items**

$$I_{0i} \sim N(0, \omega_{00}^2)$$

## Set up the environment and define the parameters for the DGP

If you want to get the same results as everyone else for this exercise, then we all should seed the random number generator with the same value.  While we're at it, let's load in the packages we need.


```r
library("lme4")
library("tidyverse")

set.seed(1451)
```

Now let's define the parameters for the DGP (data generating process).


```r
nsubj <- 100 # number of subjects
nitem <- 50  # must be an even number

mu <- 800 # grand mean
eff <- 80 # 80 ms difference
effc <- c(-.5, .5) # deviation codes

iri_sd <- 80 # by-item random intercept sd (omega_00)

## for the by-subjects variance-covariance matrix
sri_sd <- 100 # by-subject random intercept sd
srs_sd <- 40 # by-subject random slope sd
rcor <- .2 # correlation between intercept and slope

err_sd <- 200 # residual (standard deviation)
```

You'll create three tables:

|            |                                                                      |
|------------|----------------------------------------------------------------------|
| `subjects` | table of subject data including `subj_id` and subject random effects |
| `items`    | table of stimulus data including `item_id` and item random effect    |
| `trials`   | table of trials enumerating encounters between subjects/stimuli      |

Then you will merge together the information in the three tables, and calculate the response variable according to the model formula above.

## Generate a sample of stimuli

Let's randomly generate our 50 items. Create a tibble called `item` like the one below, where `iri` are the by-item random intercepts (drawn from a normal distribution with variance $\omega_{00}^2$ = `iri_sd^2`).  Half of the words are of type NOUN (`cond` = -.5) and half of type VERB (`cond` = .5).




```
## # A tibble: 50 × 3
##    item_id  cond     iri
##      <int> <dbl>   <dbl>
##  1       1  -0.5 -217.  
##  2       2   0.5  -77.9 
##  3       3  -0.5  -96.9 
##  4       4   0.5   40.4 
##  5       5  -0.5   28.0 
##  6       6   0.5  160.  
##  7       7  -0.5   -4.45
##  8       8   0.5  -83.9 
##  9       9  -0.5 -121.  
## 10      10   0.5  -12.1 
## # ℹ 40 more rows
```


<div class='webex-solution'><button>Hint (cond)</button>


`rep()`


</div>



<div class='webex-solution'><button>Hint (iri)</button>


`rnorm(nitem, ???, ????...)`


</div>



<div class='webex-solution'><button>Solution</button>



```r
items <- tibble(item_id = 1:nitem,
                cond = rep(c(-.5, .5), times = nitem / 2),
                iri = rnorm(nitem, 0, sd = iri_sd))
```


</div>


## Generate a sample of subjects

To generate the by-subject random effects, you will need to generate data from a *bivariate normal distribution*.  To do this, we will use the function `MASS::mvrnorm()`.

::: {.warning}

Do not run `library("MASS")` just to get this one function, because `MASS` has a function `select()` that will overwrite the tidyverse version. Since all we want from MASS is the `mvrnorm()` function, we can just access it directly by the `pkgname::function` syntax, i.e., `MASS::mvrnorm()`.

:::

Here is an example of how to use `MASS::mvrnorm()` to randomly generate correlated data (with $r = -.6$) for a simple bivariate case. In this example, the variances of each of the two variables is defined as 1, such that the covariance becomes equal to the correlation between the variables.


```r
## mx is the variance-covariance matrix
mx <- rbind(c(1, -.6),
            c(-.6, 1))

biv_data <- MASS::mvrnorm(1000, mu = c(0, 0), Sigma = mx)

## look at biv_data
ggplot(as.tibble(biv_data), aes(V1, V2)) +
  geom_point()
```

```
## Warning: `as.tibble()` was deprecated in tibble 2.0.0.
## ℹ Please use `as_tibble()` instead.
## ℹ The signature and semantics have changed, see `?as_tibble`.
## This warning is displayed once every 8 hours.
## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
## generated.
```

```
## Warning: The `x` argument of `as_tibble.matrix()` must have unique column names if
## `.name_repair` is omitted as of tibble 2.0.0.
## ℹ Using compatibility `.name_repair`.
## ℹ The deprecated feature was likely used in the tibble package.
##   Please report the issue at <https://github.com/tidyverse/tibble/issues>.
## This warning is displayed once every 8 hours.
## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
## generated.
```

<img src="02_mixed-effects_files/figure-html/unnamed-chunk-5-1.png" width="100%" style="display: block; margin: auto;" />

Your subjects table should look like this:


<div class='webex-solution'><button>Click to reveal full table</button>





</div>

