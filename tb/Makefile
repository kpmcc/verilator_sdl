SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS =  `sdl2-config --libs`
IDIR = ../rtl
ODIR = obj_dir

all: square

square: square.mk
	make -C ./obj_dir -f Vtop_$<

square.mk: ${IDIR}/top_square.sv
	verilator -I${IDIR} -cc $< --trace --exe main_square.cpp -o square \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

clean:
	rm -rf ./obj_dir

.PHONY: clean
