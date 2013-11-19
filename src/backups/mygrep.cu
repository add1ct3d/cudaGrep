//
//  simpleGPUGrep.cu
//  simpleGPUGrep
//
//  Created by HaoJi on 10/29/13.
//  Copyright (c) 2013 HaoJi. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define CHECK_ERR(x)                                    \
  if (x != cudaSuccess) {                               \
    fprintf(stderr,"%s in %s at line %d\n",             \
            cudaGetErrorString(err),__FILE__,__LINE__); \
    exit(-1);                                           \
  }

#define BLOCKS 100
#define THREADS 1024
#define BUFSIZE 5000
#define FAILURE -1
#define SUCCESS 0

__device__ char *mystrstr(const char *s1, const char *s2) {

	int n;
	if (*s2) {
		while (*s1) {
			for (n = 0; *(s1 + n) == *(s2 + n); n++) {
				if (!*(s2 + n + 1))
					return (char *) s1;
			}
			s1++;
		}
		return NULL ;
	} else
		return (char *) s1;
}

__device__ char *mystrncpy(char *dest, char *source, size_t n) {

	int i;
	if (dest == NULL || source == NULL )
		return NULL ;
	for (i = 0; i < n && source[i] != '\0'; i++) {
		dest[i] = source[i];
	}
	dest[i] = '\0';
	return dest;
}

__device__ int mystrlen(char *str) {

	if (str == NULL )
		return 0;
	int len = 0;
	for (; *str++ != '\0';) {
		len++;
	}
	return len;
}

__global__ void match(char *d_pattern, char* d_lines) {

	//int i = threadIdx.x;
	int pos = blockIdx.x * blockDim.x + threadIdx.x;

	int offset = pos * BUFSIZE;
	char *line = d_lines + offset;
	char *pch = mystrstr(line, d_pattern) != NULL ? line : NULL;

	if (pch != NULL ) {

		//mystrncpy(d_buf + offset, pch, mystrlen(line));
		//mystrncpy(d_buf + offset, pch, mystrlen(line));
		printf("%s", pch);
	}
}

int main(int argc, char *argv[]) {

	cudaError_t err;

	char *line;
	char *lines;

	// Memory allocation for pattern, filename (in the host)
	char pattern[BUFSIZE];
	char file_name[BUFSIZE];
	char *d_pattern, *d_lines;

	// Obtain two argv: pattern and file_name
	strcpy(pattern, argv[1]);
	strcpy(file_name, argv[2]);

	// Memory allocation for d_pattern, d_lines (in the device)
	err = cudaMalloc((void **) &d_pattern, BUFSIZE);
	CHECK_ERR(err);
	err = cudaMalloc((void **) &d_lines, BLOCKS * THREADS * BUFSIZE);
	CHECK_ERR(err);

	// Copying memory to device
	err = cudaMemcpy(d_pattern, pattern, BUFSIZE, cudaMemcpyHostToDevice);
	CHECK_ERR(err);

	// Memory allocation for lines
	lines = (char*) calloc(BLOCKS * THREADS * BUFSIZE, sizeof(char));

	// Open file
	FILE *fp;
	fp = (FILE *) fopen(file_name, "r");
	if (fp == NULL ) {
		perror("fopen():");
		exit(1);
	}

	// Memory allocation for line
	line = (char*) calloc(BUFSIZE, sizeof(char));

	// n_lines to detect the number of lines in the file
	int n_lines = 0;
	while (fgets(line, BUFSIZE, fp) != NULL ) {

		if (n_lines <= BLOCKS * THREADS - 1) {

			// Copying line to lines
			int offset = n_lines * BUFSIZE;
			strncpy(lines + offset, line, strlen(line));
			memset(line, 0, BUFSIZE);
			n_lines++;

			// Situation that the number of liens in the file is 1024 times
			if (n_lines == BLOCKS * THREADS - 1) {

				// Copying memory to device
				err = cudaMemcpy(d_lines, lines, BLOCKS * THREADS * BUFSIZE,
						cudaMemcpyHostToDevice);
				CHECK_ERR(err);

				// Calling the kernel
				match<<<BLOCKS, THREADS>>>(d_pattern, d_lines);

				// Reset lines
				n_lines = 0;
				memset(lines, 0, BLOCKS * THREADS * BUFSIZE);
			}
		}
	}

	// Situation that the number of lines in the file not 1024 times
	if (n_lines != 0) {

		// Copying memory to device
		err = cudaMemcpy(d_lines, lines, BLOCKS * THREADS * BUFSIZE, cudaMemcpyHostToDevice);
		CHECK_ERR(err);

		// Calling the kernel
		match<<<BLOCKS, THREADS>>>(d_pattern, d_lines);
	}

	// Free memory and close file
	free(line);
	free(lines);
	cudaFree(d_pattern);
	cudaFree(d_lines);
	fclose(fp);

	return SUCCESS;
}
