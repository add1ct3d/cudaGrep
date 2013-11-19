all:
	nvcc -o simpleGPUGrep simpleGPUGrep.cu -arch=sm_20
	gcc -o simpleCGrep simpleCGrep.c
clean:
	rm simpleGPUGrep simpleCGrep
