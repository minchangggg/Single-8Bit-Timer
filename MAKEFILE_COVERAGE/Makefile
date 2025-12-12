##################################################################################################
# This file created by Huy Nguyen (Modified for Linux by Minh Trang)
# Example run string:  make [target] TESTNAME={name_of_testcase}
#                      make all TESTNAME=REG      (chạy test REG)
#                      make all TESTNAME=FUNC     (chạy test FUNC)
#                      make all TESTNAME=ALL      (chạy cả 2)
##################################################################################################
# Define variables
export PATH := /home/meynchan/questasim/questa_fse/bin:$(PATH)

TESTNAME      ?= ALL              # Truyền xuống TB qua +TEST=$(TESTNAME)
TB_NAME       ?= tb_ip_TIMER
RADIX         ?= hexadecimal
REGRESS_LIST  ?= regress.list
SRCLIST_V_T   ?= compile          # Nếu muốn vẫn dùng SRCLIST_V_T.f = compile.f
#macro_en     ?= +define+write_enable
macro_en      ?=

#================================================================================================
all: build run

regression:      build create_test_list regress      report
regression_cov:  build create_test_list regress_cov gen_cov

#-----------------------------------------------------------------------------------------------
# BUILD: compile toàn bộ design + TB dùng file list compile.f
#-----------------------------------------------------------------------------------------------
build:
	mkdir -p log
	touch run_test.vt
	vlib work
	vmap work work
	# Compile có coverage + visibility tốt để debug
	# compile.f: +incdir+rtl +incdir+tb +incdir+tb/VIP +incdir+tb/TestCase  +  tb/tb_ip_TIMER.sv
	vlog -coveropt 3 +cover +acc +access+rwc -f compile.f

#-----------------------------------------------------------------------------------------------
# RUN: chỉ chạy mô phỏng, không compile lại
#      TESTNAME sẽ được truyền vào TB bằng +TEST=$(TESTNAME)
#      Ví dụ:
#          make run TESTNAME=REG
#          make run TESTNAME=FUNC
#          make run TESTNAME=ALL
#-----------------------------------------------------------------------------------------------
run:
	# Dùng -voptargs="+acc" cho visibility; tránh +acc+rwc, -access, -novopt ở đây
	vsim -l $(TESTNAME).log -voptargs="+acc" -assertdebug \
	     -c $(TB_NAME) \
	     +TEST=$(TESTNAME) \
	     -do "log -r /*; run -all; quit"
	mv $(TESTNAME).log ./log
	cp -rf vsim.wlf $(TESTNAME).wlf
	mv $(TESTNAME).wlf ./log
	ln -sf ./log/$(TESTNAME).log sim.log

find:
	find tb

create_test_list:
	find tb -type f -printf "%f\n" | sed 's/.vt//' | tee $(REGRESS_LIST) | wc -l

regress:
	./run_all.sh run

regress_cov:
	./run_all.sh run_cov

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)"

#-----------------------------------------------------------------------------------------------
# RUN WITH COVERAGE (nếu sau này cậu cần)
# Ở đây vẫn dùng compile.f và +TEST=$(TESTNAME)
#-----------------------------------------------------------------------------------------------
run_cov:
	# Compile với coverage (nếu cần tách khỏi build ở trên)
	vlog +cover=sbceftx -f compile.f
	vsim -coverage -l $(TESTNAME).log -c $(TB_NAME) \
	     -voptargs="+cover=bcesfx" -assertdebug \
	     +TEST=$(TESTNAME) \
	     -do "coverage save -onexit $(TESTNAME).ucdb; log -r -d 6 /*; run -all; quit"
	mv $(TESTNAME).log ./log

gen_cov:
	mkdir -p coverage
	vcover merge IP.ucdb *.ucdb
	vcover report IP.ucdb -file coverage/summary_report.txt
	vcover report -zeros -details -code bcefsx -All -codeAll IP.ucdb -file coverage/detail_report.txt

clean:
	rm -rf work
	rm -rf log
	rm -rf *.ini
	rm -rf *.log
	rm -rf *.wlf
	rm -rf transcript
	rm -rf coverage
	rm -rf *.ucdb
	rm -rf *.list
	rm -rf *.vt

report:
	grep "passed" ./log/*.log -R
