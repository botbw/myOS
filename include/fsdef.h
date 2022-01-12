#ifndef FSDEF_H
#define FSDEF_H

// file system function definition
#include "types.h"
#include "fs.h"
#include "file.h"
#include "stat.h"
#include "buf.h"
#include "log.h"
#include "console.h"


// fs.c
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
int inode_write(struct inode *ip, char *src, uint off, uint n);
int directory_link(struct inode *dp, char *name, uint inum);
struct inode* namei(char *path);
struct inode* nameiparent(char *path, char *name);

// buf.c
void buffers_init();
void buffer_release(struct buf*);
struct buf* buffer_read(uint, uint);
void buffer_write(struct buf*);

// file.c
void file_table_init();
struct file* file_alloc();
struct file* file_duplicate(struct file *pf);
void file_close(struct file *pf);
int file_stat(struct file *f, struct stat *st);
int file_read(struct file *f, char *addr, int n);
int file_write(struct file *f, char *addr, int n);

// pipe.c
int pipe_alloc(struct file **ppf0, struct file **ppf1);
void pipe_close(struct pipe *p, int writable);
int pipe_write(struct pipe *p, char *addr, int n);
int pipe_read(struct pipe *p, char *addr, int n);

#endif