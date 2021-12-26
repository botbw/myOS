#ifndef FS_H
#define FS_H

#include "types.h"
#include "stat.h"
#include "string.h"


// On-disk file system format.
// Both the kernel and user programs use this header file.


#define ROOTINO 1  // root i-number
#define BSIZE 512  // block size

// Disk layout:
// [ boot block | super block | log | inode blocks |
//                                          free bit map | data blocks]
//
// mkfs computes the super block and builds an initial file system. The
// super block describes the disk layout:
struct superblock {
  uint size;         // Size of file system image (blocks)
  uint nblocks;      // Number of data blocks
  uint ninodes;      // Number of inodes.
  uint nlog;         // Number of log blocks
  uint logstart;     // Block number of first log block
  uint inodestart;   // Block number of first inode block
  uint bmapstart;    // Block number of first free map block
};

#define NDIRECT 12
#define NINDIRECT (BSIZE / sizeof(uint))
#define MAXFILE (NDIRECT + NINDIRECT)

// On-disk inode structure
struct dinode {
  short type;           // File type
  short major;          // Major device number (T_DEV only)
  short minor;          // Minor device number (T_DEV only)
  short nlink;          // Number of links to inode in file system
  uint size;            // Size of file (bytes)
  uint addrs[NDIRECT+1];   // Data block addresses
};

// Inodes per block.
#define IPB           (BSIZE / sizeof(struct dinode))

// Block containing inode i
#define IBLOCK(i, sb)     ((i) / IPB + sb.inodestart)

// Bitmap bits per block
#define BPB           (BSIZE*8)

// Block of free map containing bit for block b
#define BBLOCK(b, sb) (b/BPB + sb.bmapstart)

// Directory is a file containing a sequence of dirent structures.
#define DIRSIZ 14

struct dirent {
  ushort inum;
  char name[DIRSIZ];
};

void superblock_read(int dev, struct superblock *sb);
void inode_init(int dev);
void inode_cache_release(struct inode* ip);
struct inode* inode_alloc(uint dev, short type);
struct inode* inode_duplicate(struct inode *i);
void inode_lock(struct inode *ip);
void inode_unlock(struct inode *ip);
void inode_cache_release_unlock(struct inode *ip);
void inode_update(struct inode *ip);
void inode_stat(struct inode *ip, struct stat *st);
int inode_read(struct inode *ip, char *dst, uint off, uint n);
int inode_write(struct inode *ip, const char *src, uint off, uint n);
int directory_link(struct inode *dp, char *name, uint inum);


#endif