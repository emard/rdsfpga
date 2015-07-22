BINARY=diamond/project/project_project.jed

all: $(BINARY)

$(BINARY):
	cd diamond; ./build.sh

upload: program

program: $(BINARY)
	ujprog $<
	
copy: $(BINARY)
	cp $(BINARY) blinkled_LFXP2-8E-5TN144C.jed

clean:
	lattice/clean-lattice.sh
	altera/clean-altera.sh
	rm -f DEADJOE *~
