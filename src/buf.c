#include "buf.h"

void iderw(struct buf*);

struct {
  struct spinlock lk;
  struct buf bufs[NBUF];
  struct buf dump;
} cache;

void buffers_init() {
  initlock(&cache.lk, "cache");
  cache.dump.next = &cache.dump;
  cache.dump.prev = &cache.dump;
  // bidirect queue
  for(int i = 0; i < NBUF; i++) {
    init_sleeplock(&cache.bufs[i].lock, "buffer");
    cache.bufs[i].next = cache.dump.next;
    cache.bufs[i].next->prev = &cache.bufs[i];
    cache.bufs[i].prev = &cache.dump;
    cache.dump.next = &cache.bufs[i];
  }
}

static struct buf* buffer_alloc(uint dev, uint blkno) {
  acquire(&cache.lk);

  for(struct buf* b = cache.dump.next; b != &cache.dump; b = b->next) {
    if(b->dev == dev && b->blockno == blkno) {
      b->refcnt++;
      // the lock of the queue must be released before the sleeplock
      // or it might cause death lock.
      release(&cache.lk);

      acquire_sleeplock(&b->lock);
      return b;
    }
  }
  for(struct buf* b = cache.dump.prev; b != &cache.dump; b = b->prev) {
    if(b->refcnt == 0 && !(b->flags & B_DIRTY)) {
      b->refcnt = 1;
      b->dev = dev;
      b->blockno = blkno;
      b->flags = 0;
      release(&cache.lk);
      acquire_sleeplock(&b->lock);
      return b;
    }
  }
  panic("get_buffer");
  return 0; // to placate the compiler
}

void buffer_release(struct buf *b) {
  b->refcnt--;
  if(b->refcnt == 0) {
    acquire(&cache.lk);
    b->prev->next = b->next;
    b->next->prev = b->prev;
    b->next = cache.dump.next;
    b->next->prev = b;
    b->prev = &cache.dump;
    cache.dump.next = b;
    release(&cache.lk);
  }
  if(!holdingsleep(&b->lock)) panic("buffer_release");
  release_sleeplock(&b->lock);
}

struct buf* buffer_read(uint dev, uint blkno) {
  struct buf *b = buffer_alloc(dev, blkno);

  if(!(b->flags & B_VALID)) iderw(b);

  return b;
}

void buffer_write(struct buf *b) {
  if(!holdingsleep(&b->lock)) panic("buffer_write");

  b->flags |= B_DIRTY;

  iderw(b);
}