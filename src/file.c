#include "file.h"

struct devsw devsw[NDEV];

struct {
  struct spinlock lk;
  struct file file[NFILE];
} file_table;

void file_table_init() {
  initlock(&file_table.lk, "filetable");
}

struct file* file_alloc() {
  acquire(&file_table.lk);
  for(int i = 0; i < NFILE; i++) {
    struct file *pf = &file_table.file[i];
    if(pf->ref == 0) {
      pf->ref++;
      release(&file_table.lk);
      return pf;
    }
  }
  release(&file_table.lk);
  return 0;
}

struct file* file_duplicate(struct file *pf) {
  acquire(&file_table.lk);
  if(pf->ref == 0) {
    panic("file_duplicate");
  }
  pf->ref++;
  release(&file_table.lk);
  return pf;
}

void file_close(struct file *pf) {
  acquire(&file_table.lk);
  if(pf->ref == 0) {
    panic("file_close");
  }
  pf->ref--;
  if(pf->ref > 0) {
    release(&file_table.lk);
    return;
  }
  struct file copy = *pf;
  pf->type = FD_NONE;
  pf->ref = 0;
  release(&file_table.lk);

  if(copy.type == FD_PIPE) {
    pipe_close(copy.pipe, copy.writable);
  } else {
    log_begin();
    inode_cache_release(copy.ip);
    log_end();
  }
}

int file_stat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    inode_lock(f->ip);
    inode_stat(f->ip, st);
    inode_unlock(f->ip);
    return 0;
  }
  return -1;
}

int file_read(struct file *f, char *addr, int n)
{
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipe_read(f->pipe, addr, n);
  if(f->type == FD_INODE){
    inode_lock(f->ip);
    if((r = inode_read(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    inode_unlock(f->ip);
    return r;
  }
  panic("file_read");
}

int file_write(struct file *f, char *addr, int n)
{
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipe_write(f->pipe, addr, n);
  if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      log_begin();
      inode_lock(f->ip);
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
        f->off += r;
      inode_unlock(f->ip);
      log_end();

      if(r < 0)
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
  }
  panic("file_write");
}
