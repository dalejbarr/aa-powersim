--- 
title: "Simulating power for mixed-effects models"
author: "Dale J. Barr"
date: "2023-11-29"
site: bookdown::bookdown_site
documentclass: book
bibliography: [refs.bib, packages.bib]
biblio-style: apa
csl: include/apa.csl
link-citations: yes
description: "Workshop at AMLaP Asia, November 30, 2023."
url: "https://dalejbarr.github.io/aa-powersim"
github-repo: "dalejbarr/basel-longitudinal"
---



# Workshop: Simulating power for mixed-effects models {-}

*Dale J. Barr*

**[AMLaP Asia](http://ling.cuhk.edu.hk/amlap.asia/), November 30, 2023**

## Background {-}

Materials for a practical one-day workshop aimed at conference attendees who are interested in utilizing linear mixed-effects models in their research. Led by Dr. Dale Barr from the University of Glasgow, this workshop provides an introduction to simulating power in linear mixed-effects models.

Two pre-requisites for the workshop are: (1) basic understanding of linear regression and (2) some familiarity with the R statistical programming environment (https://cran.r-project.org). Please have R and RStudio installed on your laptop prior to the start of the workshop, including the packages **`{tidyverse}`** and **`lme4`**. 

## Workshop plan {-}

- *Part 1* (9:00-12:00): **Building blocks of simulation**

  Provides an overview of critical programming skills for Monte Carlo simulation.

- *Part 2* (14:00-17:00): **Simulating power in linear mixed-effects models**

  Conceptual introduction to the data generating process (DGP) behind many models in psycholinguistics, and instructions on how to adapt the script generated in Part 1 to a multilevel context.

## Notes on these materials {-}

These materials comprise an **interactive textbook**. Each "chapter" contains embedded exercises as well as web applications to help participants better understand the content. The interactive content will only work if you access this material through a web browser. Printing out the material is not recommended. 

It would be good to keep a local copy of these materials in case the website eventually disappears. You can [download an offline version](amlap-asia-power-simulation.zip){target="_download"} of these materials. It contains the current snapshot. Because things are likely to change while the workshop is ongoing, it would be best to wait until the end of the workshop before downloading a permanent version.

Once you've downloaded the archive, just extract the files, locate the file `index.html` in the `docs` directory, and open this file using a web browser.

You are free to re-use and modify the material in this textbook for your own purposes, with the stipulation that you cite the original work. Please note additional terms of the [Creative Commons CC-BY-SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/) governing re-use of this material.

The book was built using the R [**`bookdown`**](https://bookdown.org) package. The source files are available at [github](https://github.com/dalejbarr/aa-powersim).

## Found an issue? {-}

If you find errors or typos, have questions or suggestions, please file an issue at <https://github.com/dalejbarr/aa-powersim/issues>. Thanks!
