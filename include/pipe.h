#ifndef PIPE_H
#define PIPE_H

#include "types.h"
#include "spinlock.h"
#include "kalloc.h"
#include "file.h"

#define PIPESIZE 512

struct pipe {
  struct spinlock lock;
  char data[PIPESIZE];
  uint nread;     // number of bytes read
  uint nwrite;    // number of bytes written
  int readopen;   // read fd is still open
  int writeopen;  // write fd is still open
};

int pipe_alloc(struct file **ppf0, struct file **ppf1);
void pipe_close(struct pipe *p, int writable);
int pipe_write(struct pipe *p, char *addr, int n);
int pipe_read(struct pipe *p, char *addr, int n);


#endif