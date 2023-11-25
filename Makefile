htarg := docs

VAR2=$(shell printf '%02d' $(VAR))
REGEX=$(shell printf "^\./%s.*\.Rmd$$" $(VAR2))
CFILE=$(shell find ./ -type f -regextype posix-extended -regex '$(REGEX)')

.PHONY : book
book : clean 
	Rscript -e 'bookdown::render_book("index.Rmd", output_dir = "$(htarg)")'
# cp -r ../slides/ docs/
	zip -r docs/amlap-asia-power-simulation.zip docs/

clean :
	Rscript -e 'bookdown::clean_book(TRUE)'
