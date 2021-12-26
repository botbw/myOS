#include "pipe.h"

int pipe_alloc(struct file **ppf0, struct file **ppf1) {
  struct pipe *pipe;

  if((*ppf0 = file_alloc()) == 0 || (*ppf1 = file_alloc()) == 0) {
    goto fail;
  }
  if((pipe = kalloc()) == 0) {
    goto fail;
  }

  pipe->nread = 0;
  pipe->nwrite = 0;
  pipe->readopen = 1;
  pipe->writeopen = 1;
  initlock(&pipe->lock, "pipe");
  (*ppf0)->type = FD_PIPE;
  (*ppf0)->readable = 1;
  (*ppf0)->writable = 0;
  (*ppf0)->pipe = pipe;
  (*ppf1)->type = FD_PIPE;
  (*ppf1)->readable = 0;
  (*ppf1)->writable = 1;
  (*ppf1)->pipe = pipe;
  return 0;

fail:
  if(*ppf0) 
    file_close(*ppf0);
  if(*ppf1)
    file_close(*ppf1);
  if(pipe)
    kfree(pipe);
  return -1;
}

void pipe_close(struct pipe *p, int writable) {
  acquire(&p->lock);
  if(writable){
    p->writeopen = 0;
    wakeup(&p->nread);
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
}

int pipe_write(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || myproc()->killed){
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}

int pipe_read(struct pipe *p, char *addr, int n) {
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
    if(myproc()->killed){
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
  release(&p->lock);
  return i;
}