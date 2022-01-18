#include "fs.h"
#include "string.h"


// blocks manipulation

struct superblock sb;

void superblock_read(int dev, struct superblock *sb) {
  struct buf *b = buffer_read(dev, 1);
  memcpy(sb, b->data, sizeof(struct superblock));
  buffer_release(b);
}

static void zero_block(int dev, int blk_no) {
  struct buf *b;
  b = buffer_read(dev, blk_no);
  memset(b->data, 0, BSIZE);
  log_record(b);
  buffer_release(b);
}

static uint block_alloc(uint dev) {
  for(int b = 0; b < sb.size; b += BPB) {
    struct buf *bf = buffer_read(dev, BBLOCK(b, sb));
    for(int bi = 0; bi < BPB && b + bi < sb.size; bi++) {
      int bits = 1 << (bi%8);
      if((bf->data[bi/8] & bits) == 0) {
        bf->data[bi/8] |= bits;
        log_record(bf);
        buffer_release(bf);
        zero_block(dev, b+bi);
        return b+bi;
      }
    }
    buffer_release(bf);
  }
  panic("block_alloc");
  return 0;
}

static void block_release(uint dev, uint blk_no) {
  int b = blk_no;
  int bi = blk_no & BPB;
  struct buf *bf = buffer_read(dev, BBLOCK(b, sb));
  int bits = 1 << (bi%8);
  if((bf->data[bi/8] & bits) == 0) panic("block_release");
  bf->data[bi/8] &= ~bits;
  log_record(bf);
  buffer_release(bf);
}

// inodes manipulation

struct {
  struct spinlock lk;
  struct inode inodes[NINODE];
} icache;

void inode_init(int dev) {
  int i = 0;
  
  initlock(&icache.lk, "icache");
  for(i = 0; i < NINODE; i++) {
    init_sleeplock(&icache.inodes[i].lk, "inode");
  }

  superblock_read(dev, &sb);
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
 inodestart %d bmap start %d\n", sb.size, sb.nblocks,
          sb.ninodes, sb.nlog, sb.logstart, sb.inodestart,
          sb.bmapstart);
}

static struct inode* inode_cache_get(uint dev, uint i_no) {
  acquire(&icache.lk);

  struct inode* found = 0;

  for(int id = 0; id < NINODE; id++) {
    struct inode *pi = &icache.inodes[id];
    if(pi->ref > 0 && pi->dev == dev && pi->inum == i_no) {
      pi->ref++;
      release(&icache.lk);
      return pi;
    }
    if(found == 0 && pi->ref == 0) {
      found = pi;
    }
  }

  if(found == 0) panic("inode_cache_get");

  found->dev = dev;
  found->inum = i_no;
  found->ref = 1;
  found->valid = 0;
  
  release(&icache.lk);

  return found;
}

static void
inode_truncate(struct inode *ip);

void inode_cache_release(struct inode* ip) {
  acquire_sleeplock(&ip->lk);
  if(ip->valid && ip->nlink == 0) {
    acquire(&icache.lk);
    int r = ip->ref;
    release(&icache.lk);
    if(r == 1) {
      inode_truncate(ip);
      ip->type = 0;
      inode_update(ip);
      ip->valid = 0;
    }
  }
  release_sleeplock(&ip->lk);

  acquire(&icache.lk);
  ip->ref--;
  release(&icache.lk);
}

struct inode* inode_alloc(uint dev, short type) {
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
    bp = buffer_read(dev, IBLOCK(inum, sb));
    dip = (struct dinode*)bp->data + inum%IPB;
    if(dip->type == 0) {
      memset(dip, 0, sizeof(*dip));
      dip->type = type;
      log_record(bp);
      buffer_release(bp);
      return inode_cache_get(dev, inum);
    }
    buffer_release(bp);
  }
  panic("inode_alloc");
  return 0;
}

struct inode* inode_duplicate(struct inode *i) {
  acquire(&icache.lk);
  i->ref++;
  release(&icache.lk);
  return i;
}

void inode_lock(struct inode *ip) {
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
    panic("inode_lock");

  acquire_sleeplock(&ip->lk);

  if(ip->valid == 0){
    bp = buffer_read(ip->dev, IBLOCK(ip->inum, sb));
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    ip->type = dip->type;
    ip->major = dip->major;
    ip->minor = dip->minor;
    ip->nlink = dip->nlink;
    ip->size = dip->size;
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    buffer_release(bp);
    ip->valid = 1;
    if(ip->type == 0)
      panic("inode_lock: no type");
  }
}

void inode_unlock(struct inode *ip) {
  if(ip == 0 || !holdingsleep(&ip->lk) || ip->ref < 1)
    panic("inode_unlock");

  release_sleeplock(&ip->lk);
}

void inode_cache_release_unlock(struct inode *ip) {
  inode_unlock(ip);
  inode_cache_release(ip);
}

void inode_update(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  bp = buffer_read(ip->dev, IBLOCK(ip->inum, sb));
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  dip->type = ip->type;
  dip->major = ip->major;
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  log_record(bp);
  buffer_release(bp);
}

static void
inode_truncate(struct inode *ip)
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    if(ip->addrs[i]){
      block_release(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }

  if(ip->addrs[NDIRECT]){
    bp = buffer_read(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
      if(a[j])
        block_release(ip->dev, a[j]);
    }
    buffer_release(bp);
    block_release(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
  inode_update(ip);
}

static uint block_map(struct inode *ip, uint bn)
{
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = block_alloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = block_alloc(ip->dev);
    bp = buffer_read(ip->dev, addr);
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
      a[bn] = addr = block_alloc(ip->dev);
      log_record(bp);
    }
    buffer_release(bp);
    return addr;
  }

  panic("block_map: out of range");

  return 0;
}

void inode_stat(struct inode *ip, struct stat *st) {
  st->dev = ip->dev;
  st->ino = ip->inum;
  st->type = ip->type;
  st->nlink = ip->nlink;
  st->size = ip->size;
}

static int min(int a, int b) {
  return a < b ? a : b;
}

// file manipulation

int inode_read(struct inode *ip, char *dst, uint off, uint n) {
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  }

  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = buffer_read(ip->dev, block_map(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memcpy(dst, bp->data + off%BSIZE, m);
    buffer_release(bp);
  }
  return n;
}

int inode_write(struct inode *ip, char *src, uint off, uint n) {
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
      return -1;
    return devsw[ip->major].write(ip, src, n);
  }

  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = buffer_read(ip->dev, block_map(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memcpy(bp->data + off%BSIZE, src, m);
    log_record(bp);
    buffer_release(bp);
  }

  if(n > 0 && off > ip->size){
    ip->size = off;
    inode_update(ip);
  }
  return n;
}

// directory manipulation

int namecmp(const char *s, const char *t)
{
  return strncmp(s, t, DIRSIZ);
}

struct inode* directory_lookup(struct inode *dp, char *name, uint *poff) {
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    panic("directory_lookup: not T_DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(inode_read(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("directory_lookup: inode_read");
    if(de.inum == 0)
      continue;
    if(namecmp(name, de.name) == 0){
      // entry matches path element
      if(poff)
        *poff = off;
      inum = de.inum;
      return inode_cache_get(dp->dev, inum);
    }
  }

  return 0;
}

int directory_link(struct inode *dp, char *name, uint inum)
{
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = directory_lookup(dp, name, 0)) != 0){
    inode_cache_release(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
    if(inode_read(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("directory_link: inode_read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  if(inode_write(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("directory_link: inode_write");

  return 0;
}

static char*
pathname_parser(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
    path++;
  return path;
}

static struct inode*
namex(char *path, int nameiparent, char *name)
{
  struct inode *ip, *next;

  if(*path == '/')
    ip = inode_cache_get(ROOTDEV, ROOTINO);
  else
    ip = inode_duplicate(myproc()->cwd);

  while((path = pathname_parser(path, name)) != 0){
    inode_lock(ip);
    if(ip->type != T_DIR){
      inode_cache_release_unlock(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
      // Stop one level early.
      inode_cache_release_unlock(ip);
      return ip;
    }
    if((next = directory_lookup(ip, name, 0)) == 0){
      inode_cache_release_unlock(ip);
      return 0;
    }
    inode_cache_release_unlock(ip);
    ip = next;
  }
  if(nameiparent){
    inode_cache_release(ip);
    return 0;
  }
  return ip;
}

struct inode*
namei(char *path)
{
  char name[DIRSIZ];
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  return namex(path, 1, name);
}
