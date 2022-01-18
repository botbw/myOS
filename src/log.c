#include "log.h"

struct log log;

// write the data from cache (in memory) to log (on disk)
// the blocks should be cached since before modified them you have to call buffer_read() at least once.
static void log_write() {
  for (int i = 0; i < log.lh.n; i++) {
    struct buf *from = buffer_read(log.dev, log.lh.block[i]);
    struct buf *to = buffer_read(log.dev, log.start + 1 + i);
    memcpy(to->data, from->data, BSIZE);
    buffer_write(to);
    buffer_release(from);
    buffer_release(to);
  }
}

// Read the log header from disk into the in-memory log header
static void log_header_read(void)
{
  struct buf *buf = buffer_read(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
    log.lh.block[i] = lh->block[i];
  }
  buffer_release(buf);
}

// write the log (in memory) to the disk
static void log_header_write() {
  struct buf *b = buffer_read(log.dev, log.start);
  struct logheader *lh = (struct logheader *)b->data;
  lh->n = log.lh.n;
  for (int i = 0; i < lh->n; i++) {
    lh->block[i] = log.lh.block[i];
  }
  buffer_write(b);
  buffer_release(b);
}

// install data to where they should be on the disk
static void log_install() {
  for (int i = 0; i < log.lh.n; i++) {
    struct buf *from = buffer_read(log.dev, log.start + 1 + i);
    struct buf *to = buffer_read(log.dev, log.lh.block[i]);
    memcpy(to->data, from->data, BSIZE);
    buffer_write(to);
    buffer_release(to);
    buffer_release(from);
  }
}

static void commit() {
  if (log.lh.n > 0) {
    log_write();
    // the system cannot crash between these two lines
    log_header_write(); // real commit
    // the system cannot crash between these two lines, or the log itself could be incomplete
    // can be solved if we gurantee the atomicity of the sector (bitmap for instance)
    log_install();
    log.lh.n = 0;
    log_header_write();
  }
}

// actually a part of commit
static void
log_recover(void)
{
  log_header_read();
  log_install(); // if committed, copy from log to disk
  log.lh.n = 0;
  log_header_write(); // clear the log
}

// called at the start of each FS system call.
void log_begin() {
  acquire(&log.lock);
  while (1) {
    if (log.committing) {
      sleep(&log, &log.lock);
    } else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) {
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
}

// after modified each buffer, call it to record the modification
void log_record(struct buf *b) {
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
  if (i == log.lh.n)
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
  release(&log.lock);
}

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
log_end(void)
{
  int do_commit = 0;

  acquire(&log.lock);
  log.outstanding -= 1;
  if(log.committing)
    panic("log.committing");
  if(log.outstanding == 0){
    do_commit = 1;
    log.committing = 1;
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);

  if(do_commit){
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
    acquire(&log.lock);
    log.committing = 0;
    wakeup(&log);
    release(&log.lock);
  }
}

void log_init(int dev) {
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");
  struct superblock sb;
  initlock(&log.lock, "log");
  
  superblock_read(dev, &sb);
  log.start = sb.logstart;
  log.size = sb.nlog;
  log.dev = dev;
  log_recover();
}