# Linear mixed-effects modeling

For this first section, we will learn to simulate data corresponding to an experiment with a single, two-level factor (independent variable) that is within-subjects and between-items.  Let's imagine that the experiment involves lexical decisions to a set of words (e.g., is "PINT" a word or nonword?), and the dependent variable is response time (in milliseconds), and the independent variable is word type (noun vs verb).  We want to treat both subjects and words as random factors (so that we can generalize to the population of events where subjects encounter words).

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

## Generate data

### Set up the environment 

If you want to get the same results as everyone else for this exercise, then we all should seed the random number generator with the same value.  While we're at it, let's load in the packages we need.


```r
library("lme4")
library("tidyverse")
requireNamespace("MASS") ## make sure it's there but don't load it

set.seed(1451)
```

### Define the parameters for the DGP {#dgp}

Now let's define the parameters for the DGP (data generating process).


```r
nsubj <- 100 # number of subjects
nitem <- 50  # must be an even number

mu <- 800 # grand mean
eff <- 80 # 80 ms difference

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

### Generate a sample of stimuli

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


### Generate a sample of subjects

To generate the by-subject random effects, you will need to generate data from a *bivariate normal distribution*.  To do this, we will use the function `MASS::mvrnorm()`.

::: {.warning}

Do not run `library("MASS")` just to get this one function, because `MASS` has a function `select()` that will overwrite the tidyverse version. Since all we want from MASS is the `mvrnorm()` function, we can just access it directly by the `pkgname::function` syntax, i.e., `MASS::mvrnorm()`.

:::

Here is an example of how to use `MASS::mvrnorm()` to randomly generate correlated data (with $r = -.6$) for a simple bivariate case. In this example, the variances of each of the two variables is defined as 1, such that the covariance becomes equal to the correlation between the variables.


```r
## mx is the variance-covariance matrix
mx <- rbind(c(1, -.6),
            c(-.6, 1))

biv_data <- MASS::mvrnorm(1000,
                          mu = c(V1 = 0, V2 = 0),
                          Sigma = mx)

## look at biv_data
ggplot(as_tibble(biv_data), aes(V1, V2)) +
  geom_point()
```

<img src="02_mixed-effects_files/figure-html/unnamed-chunk-5-1.png" width="100%" style="display: block; margin: auto;" />

Your subjects table should look like this:


<div class='webex-solution'><button>Click to reveal full table</button>





```
## # A tibble: 100 × 3
##     subj_id      sri      srs
##       <int>    <dbl>    <dbl>
##   1       1   42.9    25.7   
##   2       2  -15.3   -28.2   
##   3       3  -41.4   -30.3   
##   4       4  -77.1     3.64  
##   5       5  182.      2.48  
##   6       6   24.6   -13.3   
##   7       7    8.92   42.8   
##   8       8 -101.    -37.2   
##   9       9  -96.8   -32.7   
##  10      10  -27.4   -52.6   
##  11      11  -80.8    -9.06  
##  12      12   83.8   -40.3   
##  13      13  134.    -18.9   
##  14      14 -130.    132.    
##  15      15  -59.2    -8.42  
##  16      16 -127.     12.5   
##  17      17    8.91  -15.3   
##  18      18  -26.8   -19.0   
##  19      19   48.0    39.5   
##  20      20   35.6    28.5   
##  21      21 -199.    -32.9   
##  22      22  -41.1    -9.77  
##  23      23  -29.9     1.02  
##  24      24   12.0   -24.0   
##  25      25   20.5     0.0251
##  26      26   -0.207  47.9   
##  27      27  -13.7   -77.8   
##  28      28 -154.     31.5   
##  29      29  -59.6    67.7   
##  30      30  -50.6   -27.6   
##  31      31  125.      9.51  
##  32      32  111.     13.4   
##  33      33  -27.0    71.7   
##  34      34 -140.     -7.69  
##  35      35  -31.0    18.4   
##  36      36 -185.     31.4   
##  37      37   12.8   -65.8   
##  38      38  -39.7   -51.6   
##  39      39  -93.9    76.3   
##  40      40  -63.9   -12.5   
##  41      41   68.6    -3.47  
##  42      42  -91.9   -31.8   
##  43      43 -143.     53.9   
##  44      44   44.6    48.0   
##  45      45    5.72   24.2   
##  46      46   51.3   101.    
##  47      47 -176.    -47.8   
##  48      48  -54.0   -23.8   
##  49      49   26.8    32.3   
##  50      50   20.4    -9.41  
##  51      51  122.     -2.03  
##  52      52 -111.    -16.1   
##  53      53  266.     16.4   
##  54      54  -42.1    -6.37  
##  55      55   -3.47  -30.1   
##  56      56   94.9    18.0   
##  57      57  -26.9   -19.9   
##  58      58  154.     43.0   
##  59      59  110.    -18.9   
##  60      60 -167.    -14.9   
##  61      61 -255.     -1.70  
##  62      62   95.9   -28.8   
##  63      63  211.    -78.7   
##  64      64  -40.7   102.    
##  65      65 -174.     -1.30  
##  66      66   42.3    11.0   
##  67      67 -120.    -94.1   
##  68      68 -173.     10.0   
##  69      69 -239.     -7.33  
##  70      70   28.8   -29.9   
##  71      71  107.     13.1   
##  72      72 -114.     -3.12  
##  73      73 -114.     20.7   
##  74      74  -23.5   -29.4   
##  75      75  -77.5    23.9   
##  76      76  160.     78.6   
##  77      77 -139.     40.6   
##  78      78   88.2    31.3   
##  79      79   -2.36  -24.1   
##  80      80    6.12    6.91  
##  81      81  -10.8   -47.2   
##  82      82   97.5    48.6   
##  83      83   38.4     5.61  
##  84      84    7.07  -42.2   
##  85      85   81.2    17.9   
##  86      86   52.8    80.4   
##  87      87  -78.4    16.8   
##  88      88 -116.     36.9   
##  89      89  -88.6    18.4   
##  90      90  -36.9   -12.9   
##  91      91 -100.    -21.8   
##  92      92 -114.    -18.9   
##  93      93   25.9   -45.2   
##  94      94  173.     52.7   
##  95      95   18.0   -68.1   
##  96      96 -112.     43.9   
##  97      97   20.9    -2.86  
##  98      98  169.     -2.79  
##  99      99 -101.     -3.88  
## 100     100  106.    -27.6
```


</div>



<div class='webex-solution'><button>Hint 1</button>


recall that:

|          |                                                |
|----------|------------------------------------------------|
| `sri_sd` | by-subject random intercept standard deviation |
| `srs_sd` | by-subject random slope standard deviation     |
| `r`      | correlation between intercept and slope        |


</div>



<div class='webex-solution'><button>Hint 2 (covariance)</button>


```
covariance = r * sri_sd * srs_sd
```


</div>



<div class='webex-solution'><button>Hint 3 (building a matrix)</button>



```r
## bind together rows
rbind(
  c(sri_sd^2,            r * sri_sd * srs_sd),
  c(r * sri_sd * srs_sd,            srs_sd^2)  )

## see also `matrix()`
```


</div>



<div class='webex-solution'><button>Hint 4: (matrix to tibble)</button>


`as_tibble(mx)`


</div>



<div class='webex-solution'><button>Solution</button>



```r
mx <- rbind(c(sri_sd^2,               rcor * sri_sd * srs_sd),
            c(rcor * sri_sd * srs_sd, srs_sd^2)) # look at it

by_subj_rfx <- MASS::mvrnorm(nsubj,
                             mu = c(sri = 0, srs = 0),
                             Sigma = mx)

subjects <- as_tibble(by_subj_rfx) |>
  mutate(subj_id = row_number()) |>
  select(subj_id, everything())
```


</div>


### Generate a sample of encounters (trials)

Each trial is an *encounter* between a particular subject and stimulus.  In this experiment, each subject will see each stimulus.  Generate a table `trials` that lists the encounters in the experiments. Note: each participant encounters each stimulus item once.  Use the `crossing()` function to create all possible encounters.

Now apply this example to generate the table below, where `err` is the residual term, drawn from \(N \sim \left(0, \sigma^2\right)\), where \(\sigma\) is `err_sd`.




```
## # A tibble: 5,000 × 3
##    subj_id item_id    err
##      <int>   <int>  <dbl>
##  1       1       1  -64.3
##  2       1       2  585. 
##  3       1       3  127. 
##  4       1       4  182. 
##  5       1       5  -47.6
##  6       1       6   22.0
##  7       1       7 -265. 
##  8       1       8  604. 
##  9       1       9  249. 
## 10       1      10 -147. 
## # ℹ 4,990 more rows
```


<div class='webex-solution'><button>Solution</button>



```r
trials <- crossing(subj_id = subjects |> pull(subj_id),
                   item_id = items |> pull(item_id)) |>
  mutate(err = rnorm(n = nsubj * nitem,
                     mean = 0, sd = err_sd))  
```


</div>


### Join `subjects`, `items`, and `trials`

Merge the information in `subjects`, `items`, and `trials` to create the full dataset `dat`, which looks like this:




```
## # A tibble: 5,000 × 7
##    subj_id item_id   sri     iri   srs  cond    err
##      <int>   <int> <dbl>   <dbl> <dbl> <dbl>  <dbl>
##  1       1       1  42.9 -217.    25.7  -0.5  -64.3
##  2       1       2  42.9  -77.9   25.7   0.5  585. 
##  3       1       3  42.9  -96.9   25.7  -0.5  127. 
##  4       1       4  42.9   40.4   25.7   0.5  182. 
##  5       1       5  42.9   28.0   25.7  -0.5  -47.6
##  6       1       6  42.9  160.    25.7   0.5   22.0
##  7       1       7  42.9   -4.45  25.7  -0.5 -265. 
##  8       1       8  42.9  -83.9   25.7   0.5  604. 
##  9       1       9  42.9 -121.    25.7  -0.5  249. 
## 10       1      10  42.9  -12.1   25.7   0.5 -147. 
## # ℹ 4,990 more rows
```

Note: this is the full **decomposition table** for this model.


<div class='webex-solution'><button>Solution</button>



```r
dat_sim <- subjects |>
  inner_join(trials, "subj_id") |>
  inner_join(items, "item_id") |>
  arrange(subj_id, item_id) |>
  select(subj_id, item_id, sri, iri, srs, cond, err)
```


</div>


### Create the response variable {#addy}

Add the response variable `Y` to dat according to the model formula:

$$Y_{si} = \beta_0 + S_{0s} + I_{0i} + (\beta_1 + S_{1s})X_{i} + e_{si}$$

so that the resulting table (`dat2`) looks like this:




```
## # A tibble: 5,000 × 8
##    subj_id item_id     Y   sri     iri   srs  cond    err
##      <int>   <int> <dbl> <dbl>   <dbl> <dbl> <dbl>  <dbl>
##  1       1       1  509.  42.9 -217.    25.7  -0.5  -64.3
##  2       1       2 1403.  42.9  -77.9   25.7   0.5  585. 
##  3       1       3  820.  42.9  -96.9   25.7  -0.5  127. 
##  4       1       4 1118.  42.9   40.4   25.7   0.5  182. 
##  5       1       5  770.  42.9   28.0   25.7  -0.5  -47.6
##  6       1       6 1077.  42.9  160.    25.7   0.5   22.0
##  7       1       7  520.  42.9   -4.45  25.7  -0.5 -265. 
##  8       1       8 1416.  42.9  -83.9   25.7   0.5  604. 
##  9       1       9  918.  42.9 -121.    25.7  -0.5  249. 
## 10       1      10  737.  42.9  -12.1   25.7   0.5 -147. 
## # ℹ 4,990 more rows
```


<div class='webex-solution'><button>Solution</button>



```r
dat_sim2 <- dat_sim |>
  mutate(Y = mu + sri + iri + (eff + srs) * cond + err) |>
  select(subj_id, item_id, Y, everything())
```


</div>


### Fitting the model

Now that you have created simulated data, estimate the model using `lme4::lmer()`, and run `summary()`.


<div class='webex-solution'><button>Solution</button>



```r
mod_sim <- lmer(Y ~ cond + (1 + cond | subj_id) + (1 | item_id),
                dat_sim2, REML = FALSE)

summary(mod_sim, corr = FALSE)
```

```
## Linear mixed model fit by maximum likelihood  ['lmerMod']
## Formula: Y ~ cond + (1 + cond | subj_id) + (1 | item_id)
##    Data: dat_sim2
## 
##      AIC      BIC   logLik deviance df.resid 
##  67657.9  67703.6 -33822.0  67643.9     4993 
## 
## Scaled residuals: 
##     Min      1Q  Median      3Q     Max 
## -3.7634 -0.6571 -0.0058  0.6572  3.2204 
## 
## Random effects:
##  Groups   Name        Variance Std.Dev. Corr
##  subj_id  (Intercept) 10283.1  101.41       
##           cond          993.8   31.52   0.13
##  item_id  (Intercept)  7397.3   86.01       
##  Residual             40296.4  200.74       
## Number of obs: 5000, groups:  subj_id, 100; item_id, 50
## 
## Fixed effects:
##             Estimate Std. Error t value
## (Intercept)   784.73      16.09  48.776
## cond           76.01      25.18   3.019
```


</div>


Now see if you can identify the data generating parameters in the output of `summary()`.



First, try to find $\beta_0$ and $\beta_1$.


<div class='webex-solution'><button>Solution (fixed effects)</button>



|parameter       |variable | input| estimate|
|:---------------|:--------|-----:|--------:|
|$\hat{\beta}_0$ |`mu`     |   800|  784.729|
|$\hat{\beta}_1$ |`eff`    |    80|   76.005|


</div>


Now try to find estimates of random effects parameters $\tau_{00}$, $\tau_{11}$, $\rho$, $\omega_{00}$, and $\sigma$.


<div class='webex-solution'><button>Solution (random effects)</button>



|parameter           |variable | input| estimate|
|:-------------------|:--------|-----:|--------:|
|$\hat{\tau}_{00}$   |`sri_sd` | 100.0|  101.405|
|$\hat{\tau}_{11}$   |`srs_sd` |  40.0|   31.524|
|$\hat{\rho}$        |`rcor`   |   0.2|    0.130|
|$\hat{\omega}_{00}$ |`iri_sd` |  80.0|   86.008|
|$\hat{\sigma}$      |`err_sd` | 200.0|  200.740|


</div>


## Building the simulation script

Now that we've learned to simulated data with crossed random factors of subjects and stimuli, let's build a script to run the simulation. You might want to start a fresh R script for this (and load in tidyverse + lme4 at the top).

### Wrapping the code into `generate_data()`

Now wrap the code you created from section \@ref(dgp) to \@ref(addy) into a single function `generate_data()` that takes four arguments: `id` (run id), `eff` (effect size), `nsubj` (number of subjects), `nitem` (number of items), and then all the remaining DGP paramemters in this order: `mu`, `iri_sd`, `sri_sd`, `srs_sd`, `rcor`, and `err_sd`. These final parameters should all be given the default values shown in section \@ref(dgp).

The code should return a table with columns `subj_id`, `item_id`, `cond`, and `Y`.

Here is 'starter' code that does nothing. 


```r
generate_data <- function(id, eff, nsubj, nitem,
                          mu, iri_sd, sri_sd,
                          srs_sd, rcor, err_sd) {

  ## 1. TODO generate sample of stimuli
  ## 2. TODO generate sample of subjects
  ## 3. TODO generate trials, adding in error
  ## 4. TODO join the three tables together
  ## 5. TODO create the response variable

  ## TODO replace this placeholder table with your result
  tibble(subj_id = integer(0),
         item_id = integer(0),
         cond = double(0),
         Y = double(0))
}

## test it out
generate_data(1, 0, 50, 10,
              mu = 800, iri_sd = 80, sri_sd = 100,
              srs_sd = 40, rcor = .2, err_sd = 200)
```


<div class='webex-solution'><button>Solution</button>



```r
generate_data <- function(id, eff, nsubj, nitem,
                          mu, iri_sd, sri_sd,
                          srs_sd, rcor, err_sd) {

  ## 1. generate sample of stimuli
  items <- tibble(item_id = 1:nitem,
                  cond = rep(c(-.5, .5), times = nitem / 2),
                  iri = rnorm(nitem, 0, sd = iri_sd))
  
  ## 2. generate sample of subjects
  mx <- rbind(c(sri_sd^2,               rcor * sri_sd * srs_sd),
              c(rcor * sri_sd * srs_sd, srs_sd^2)) # look at it

  by_subj_rfx <- MASS::mvrnorm(nsubj,
                               mu = c(sri = 0, srs = 0),
                               Sigma = mx)

  subjects <- as_tibble(by_subj_rfx) |>
    mutate(subj_id = row_number()) |>
    select(subj_id, everything())
  
  ## 3. generate trials, adding in error
  trials <- crossing(subj_id = subjects |> pull(subj_id),
                     item_id = items |> pull(item_id)) |>
    mutate(err = rnorm(n = nsubj * nitem,
                       mean = 0, sd = err_sd))
  
  ## 4. join the three tables together, AND
  ## 5. create the response variable
  subjects |>
    inner_join(trials, "subj_id") |>
    inner_join(items, "item_id") |>
    mutate(Y = mu + sri + iri + (eff + srs) * cond + err) |>
    select(subj_id, item_id, cond, Y)
}
```


</div>


### Re-write `analyze_data()`

Now let's re-write our `analyze_data()` function for this design.


```r
analyze_data <- function(dat) {
  suppressWarnings( # ignore non-convergence
    suppressMessages({ # ignore 'singular fit'
      ## TODO: something with lmer()
    }))
}
```


<div class='webex-solution'><button>Solution</button>



```r
analyze_data <- function(dat) {
  suppressWarnings( # ignore non-convergence
    suppressMessages({ # ignore 'singular fit'
      lmer(Y ~ cond + (cond | subj_id) +
             (1 | item_id), data = dat)
    }))
}
```


</div>


### Re-write `extract_stats()`

Currently, `extract_stats()` only pulls out information about the intercept term.

Let's change it so it gets information about the coefficient of `cond`.

Because this function calls `check_converged()`, we need to copy that into our session too.


```r
check_converged <- function(mobj) {
  ## warning: this is kind of a hack!
  ## see also performance::check_convergence()
  sm <- summary(mobj)
  is.null(sm$optinfo$conv$lme4$messages)
}
```

And here's our previous version of `extract_stats()` that you need to change.


```r
extract_stats <- function(mobj) {
  tibble(sing = isSingular(mobj),
         conv = check_converged(mobj),
         estimate = fixef(mobj)[1],
         stderr = sqrt(diag(vcov(mobj)))[1],
         tval = estimate / stderr,
         pval = 2 * (1 - pnorm(abs(tval))))
}
```


<div class='webex-solution'><button>Solution</button>



```r
extract_stats <- function(mobj) {
  tibble(sing = isSingular(mobj),
         conv = check_converged(mobj),
         estimate = fixef(mobj)["cond"],
         stderr = sqrt(diag(vcov(mobj)))["cond"],
         tval = estimate / stderr,
         pval = 2 * (1 - pnorm(abs(tval))))
}
```


</div>


### Re-write `do_all()`

The function `do_all()` performs all three functions (generates the data, analyzes it, and subtracts the results). It needs some minor changes to work with the parameters of the new DGP. It also depends upon the utility function `full_results()` which can be used as it is, and is repeated here so that you can conveniently paste it into your script.


```r
full_results <- function(x, alpha = .05) {
  ## after completing all the Monte Carlo runs for a set,
  ## calculate statistics
  x |>
    select(run_id, stats) |>
    unnest(stats) |>
    summarize(n_sing = sum(sing),
              n_unconv = sum(!conv),
              n_sig = sum(pval < alpha),
              N = n())
}
```

Now let's re-write `do_all()`. Here's starter code. You'll need to change its arguments to match `generate_data()` as well as the arguments passed to `generate_data()` via `map()`. It's also a good idea to update the `message()` it prints for the user.


```r
do_all <- function(eff, nmc, nsubj, ntrials) {
  ## generate, analyze, and extract for a single parameter setting
  ## you shouldn't need to change anything about this function except
  ## the arguments and paramemters passed to generate_data()
  message("computing stats over ", nmc,
          " runs for nsubj=", nsubj, "; ",
          "ntrials=", ntrials, "; ",
          "eff=", eff)
  dat_full <- tibble(run_id = seq_len(nmc)) |>
    mutate(dat = map(run_id, generate_data,
                     ## change parameters below as needed
                     nsubj = nsubj,
                     ntrials = ntrials,
                     eff = eff),
           mobj = map(dat, analyze_data),
           stats = map(mobj, extract_stats))
  
  bind_cols(tibble(fdat = list(dat_full)),
            full_results(dat_full))
}
```


<div class='webex-solution'><button>Solution</button>



```r
do_all <- function(eff, nsubj, nitem, nmc,
                   mu, iri_sd, sri_sd,
                   srs_sd, rcor, err_sd) {
  ## generate, analyze, and extract for a single parameter setting
  message("computing stats over ", nmc,
          " runs for nsubj=", nsubj, "; ",
          "nitem=", nitem, "; ",
          "eff=", eff)
  dat_full <- tibble(run_id = seq_len(nmc)) |>
    mutate(dat = map(run_id, generate_data,
                     ## change parameters below as needed
                     nsubj = nsubj, nitem = nitem,
                     eff = eff, mu = mu, iri_sd = iri_sd,
                     sri_sd = sri_sd, srs_sd = srs_sd,
                     rcor = rcor, err_sd = err_sd),
           mobj = map(dat, analyze_data),
           stats = map(mobj, extract_stats))
  
  bind_cols(tibble(fdat = list(dat_full)),
            full_results(dat_full))
}
```


</div>


### Main code

Now that we've re-written all of the functions, let's adjust the main code of the template script. All you really need to change here is the code defining `allsets` so that it calls `do_all()` with the new parameter settings. The rest you can just copy.






```r
set.seed(1451) # for deterministic output

## determine number of Monte Carlo runs.
nmc <- if (interactive()) {
         20L # small number just for testing things out
       } else {
         if (length(commandArgs(TRUE))) {
           as.integer(commandArgs(TRUE)[1]) # get value from command line
         } else {
           stop("need to specify number of Monte Carlo runs on commmand line")
         }
       }

params <- tibble(id = 1:5,
                 eff = seq(0, 1.5, length.out = 5))

allsets <- params |>
  mutate(result = map(eff, do_all,
                      nmc = nmc,
                      nsubj = 10, ntrials = 10))

pow_result <- allsets |>
  unnest(result) |>
  mutate(power = n_sig / N) |>
  select(-fdat)

pow_result

outfile <- "power-simulation-results.rds"

saveRDS(pow_result, outfile)

message("results saved to '", outfile, "'")
```


<div class='webex-solution'><button>Solution</button>



```r
set.seed(1451) # for deterministic output

## determine number of Monte Carlo runs.
nmc <- if (interactive()) {
         20L # small number just for testing things out
       } else {
         if (length(commandArgs(TRUE))) {
           as.integer(commandArgs(TRUE)[1]) # get value from command line
         } else {
           stop("need to specify number of Monte Carlo runs on commmand line")
         }
       }

params <- tibble(id = 1:5,
                 eff = seq(0, 1.5, length.out = 5))

allsets <- params |>
  mutate(result = map(eff, do_all,  # see also furrr::future_map()
                      nsubj = 20, nitem = 10, nmc = nmc,
                      mu = 800, iri_sd = 80, sri_sd = 100,
                      srs_sd = 40, rcor = .2, err_sd = 200))
                      

pow_result <- allsets |>
  unnest(result) |>
  mutate(power = n_sig / N) |>
  select(-fdat)

pow_result

outfile <- "power-simulation-results.rds"

saveRDS(pow_result, outfile)

message("results saved to '", outfile, "'")
```


</div>


### The full script


<div class='webex-solution'><button>Click here to see the full script</button>



```r
#############################
## ADD-ON PACKAGES

suppressPackageStartupMessages({
  library("dplyr")
  library("tibble")
  library("purrr")
  library("tidyr")

  library("lme4")
})

requireNamespace("MASS") # make sure it's there but don't load it

#############################
## CUSTOM FUNCTIONS

generate_data <- function(id, eff, nsubj, nitem,
                          mu, iri_sd, sri_sd,
                          srs_sd, rcor, err_sd) {

  ## 1. generate sample of stimuli
  items <- tibble(item_id = 1:nitem,
                  cond = rep(c(-.5, .5), times = nitem / 2),
                  iri = rnorm(nitem, 0, sd = iri_sd))
  
  ## 2. generate sample of subjects
  mx <- rbind(c(sri_sd^2,               rcor * sri_sd * srs_sd),
              c(rcor * sri_sd * srs_sd, srs_sd^2)) # look at it

  by_subj_rfx <- MASS::mvrnorm(nsubj,
                               mu = c(sri = 0, srs = 0),
                               Sigma = mx)

  subjects <- as_tibble(by_subj_rfx) |>
    mutate(subj_id = row_number()) |>
    select(subj_id, everything())
  
  ## 3. generate trials, adding in error
  trials <- crossing(subj_id = subjects |> pull(subj_id),
                     item_id = items |> pull(item_id)) |>
    mutate(err = rnorm(n = nsubj * nitem,
                       mean = 0, sd = err_sd))
  
  ## 4. join the three tables together, AND
  ## 5. create the response variable
  subjects |>
    inner_join(trials, "subj_id") |>
    inner_join(items, "item_id") |>
    mutate(Y = mu + sri + iri + (eff + srs) * cond + err) |>
    select(subj_id, item_id, cond, Y)
}

analyze_data <- function(dat) {
  suppressWarnings( # ignore non-convergence
    suppressMessages({ # ignore 'singular fit'
      lmer(Y ~ cond + (cond | subj_id) +
             (1 | item_id), data = dat)
    }))
}

extract_stats <- function(mobj) {
  tibble(sing = isSingular(mobj),
         conv = check_converged(mobj),
         estimate = fixef(mobj)["cond"],
         stderr = sqrt(diag(vcov(mobj)))["cond"],
         tval = estimate / stderr,
         pval = 2 * (1 - pnorm(abs(tval))))
}

#############################
## UTILITY FUNCTIONS

check_converged <- function(mobj) {
  ## warning: this is kind of a hack!
  ## see also performance::check_convergence()
  sm <- summary(mobj)
  is.null(sm$optinfo$conv$lme4$messages)
}

full_results <- function(x, alpha = .05) {
  ## after completing all the Monte Carlo runs for a set,
  ## calculate statistics
  x |>
    select(run_id, stats) |>
    unnest(stats) |>
    summarize(n_sing = sum(sing),
              n_unconv = sum(!conv),
              n_sig = sum(pval < alpha),
              N = n())
}

do_all <- function(eff, nsubj, nitem, nmc,
                   mu, iri_sd, sri_sd,
                   srs_sd, rcor, err_sd) {
  ## generate, analyze, and extract for a single parameter setting
  message("computing stats over ", nmc,
          " runs for nsubj=", nsubj, "; ",
          "nitem=", nitem, "; ",
          "eff=", eff)
  dat_full <- tibble(run_id = seq_len(nmc)) |>
    mutate(dat = map(run_id, generate_data,
                     ## change parameters below as needed
                     nsubj = nsubj, nitem = nitem,
                     eff = eff, mu = mu, iri_sd = iri_sd,
                     sri_sd = sri_sd, srs_sd = srs_sd,
                     rcor = rcor, err_sd = err_sd),
           mobj = map(dat, analyze_data),
           stats = map(mobj, extract_stats))
  
  bind_cols(tibble(fdat = list(dat_full)),
            full_results(dat_full))
}

#############################
## MAIN CODE STARTS HERE

set.seed(1451) # for deterministic output

## determine number of Monte Carlo runs.
nmc <- if (interactive()) {
         20L # small number just for testing things out
       } else {
         if (length(commandArgs(TRUE))) {
           as.integer(commandArgs(TRUE)[1]) # get value from command line
         } else {
           stop("need to specify number of Monte Carlo runs on commmand line")
         }
       }

params <- tibble(id = 1:5,
                 eff = seq(0, 1.5, length.out = 5))

allsets <- params |>
  mutate(result = map(eff, do_all,  # see also furrr::future_map()
                      nsubj = 20, nitem = 10, nmc = nmc,
                      mu = 800, iri_sd = 80, sri_sd = 100,
                      srs_sd = 40, rcor = .2, err_sd = 200))
                      

pow_result <- allsets |>
  unnest(result) |>
  mutate(power = n_sig / N) |>
  select(-fdat)

pow_result

outfile <- "power-simulation-results.rds"

saveRDS(pow_result, outfile)

message("results saved to '", outfile, "'")
```
