#ifndef LOG_H
#define LOG_H

#include "param.h"
#include "spinlock.h"
#include "buf.h"
#include "string.h"
#include "fs.h"

// Contents of the header block, used for both the on-disk header block
// and to keep track in memory of logged block# before commit.
struct logheader {
  int n;
  int block[LOGSIZE];
};

struct log {
  struct spinlock lock;
  int start;
  int size;
  int outstanding; // how many FS sys calls are executing.
  int committing;  // in commit(), please wait.
  int dev;
  struct logheader lh;
};

#endif