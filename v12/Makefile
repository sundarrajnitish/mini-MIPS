# mini-MIPS v12 -- verification & site build
# Requirements: GHDL (VHDL-2008), Python 3, Node >= 18
GHDL  ?= ghdl
FLAGS  = --std=08 --workdir=.

.PHONY: all compile alu test regress jscheck mutation site clean

all: alu regress jscheck mutation site

compile:
	@mkdir -p build
	@for f in $$(cat scripts/files.txt); do $(GHDL) -a --std=08 --workdir=build $$f || exit 1; done

alu: compile                      ## ALU unit test (120k vectors)
	cd build && $(GHDL) -e $(FLAGS) tb_alu && $(GHDL) -r $(FLAGS) tb_alu | tee alu.log | grep TB_RESULT

test: alu                         ## quick: directed programs + 200 random
	python3 sw/run_regression.py --random 200

regress:                          ## full: directed + 1000 random programs (writes build/regression.json)
	python3 sw/run_regression.py --random 1000 --length 60 --seed 5000 --json build/regression.json

jscheck:                          ## website model vs RTL, cycle by cycle (needs a regression run first)
	node sw/check_js_model.js | tee build/jscheck.log | tail -1

mutation:                         ## inject 20 bugs, each must be caught
	python3 sw/mutation_test.py --json build/mutation.json

site:                             ## rebuild ../docs (GitHub Pages)
	python3 scripts/export_verification.py
	python3 scripts/build_site.py

clean:
	rm -rf build
