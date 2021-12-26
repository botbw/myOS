#ifndef FILE_H
#define FILE_H

#include "types.h"
#include "spinlock.h"
#include "fs.h"
#include "param.h"
#include "log.h"

struct file {
  enum { FD_NONE, FD_PIPE, FD_INODE } type;
  int ref; // reference count
  char readable;
  char writable;
  struct pipe *pipe;
  struct inode *ip;
  uint off;
};


// in-memory copy of an inode
struct inode {
  uint dev;           // Device number
  uint inum;          // Inode number
  int ref;            // Reference count
  struct spinlock lk; // protects everything below here
  int valid;          // inode has been read from disk?

  short type;         // copy of disk inode
  short major;
  short minor;
  short nlink;
  uint size;
  uint addrs[NDIRECT+1];
};

// table mapping major device number to
// device functions
struct devsw {
  int (*read)(struct inode*, char*, int);
  int (*write)(struct inode*, char*, int);
};

extern struct devsw devsw[];

#define CONSOLE 1

void file_table_init();
struct file* file_alloc();
struct file* file_duplicate(struct file *pf);
void file_close(struct file *pf);
int file_stat(struct file *f, struct stat *st);
int file_read(struct file *f, char *addr, int n);
int file_write(struct file *f, char *addr, int n);

#endif