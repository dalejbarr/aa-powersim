#############################
## ADD-ON PACKAGES

suppressPackageStartupMessages({
  library("dplyr")
  library("tibble")
  library("purrr")
  library("tidyr")

  library("lme4")
})

#############################
## CUSTOM FUNCTIONS

generate_data <- function(id, eff, nsubj, ntrials) {
  ## TODO: replace with something more interesting
  tibble(sub_id = rep(seq_len(nsubj), each = ntrials),
         rand_int = rep(rnorm(nsubj), each = ntrials),
         err = rnorm(nsubj * ntrials),
         dv = eff + rand_int + err)
}

analyze_data <- function(dat) {
  ## TODO: replace with something more interesting
  suppressWarnings( # ignore non-convergence
    suppressMessages({ # ignore 'singular fit'
      lmer(dv ~ 1 + (1 | sub_id), dat)
    }))
}

extract_stats <- function(mobj) {
  ## TODO: replace with something more interesting
  tibble(sing = isSingular(mobj),
         conv = check_converged(mobj),
         estimate = fixef(mobj)[1],
         stderr = sqrt(diag(vcov(mobj))),
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

full_results <- function(x) {
  x |>
    select(run_id, stats) |>
    unnest(stats) |>
    summarize(n_sing = sum(sing),
              n_unconv = sum(!conv),
              n_sig = sum(pval < .05),
              N = n())
}

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

## or if you want to save *EVERYTHING* (and have a very large file):
## saveRDS(allsets, outfile)
