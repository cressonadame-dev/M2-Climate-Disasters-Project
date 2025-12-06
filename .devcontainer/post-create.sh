#!/bin/bash

echo "Installation des paquets R..."

sudo Rscript -e "install.packages(c(
    'jsonlite', 
    'languageserver', 
    'data.table', 
    'rmarkdown', 
    'R.utils', 
    'bit64'
), repos='https://packagemanager.posit.co/cran/__linux__/jammy/latest', Ncpus = parallel::detectCores())"
