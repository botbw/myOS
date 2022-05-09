#ifndef VM_H
#define VM_H

struct proc;

void kvminit();
pde_t* setupkvm();
void inituvm(pde_t *pgdir, char *init, uint sz);
void switchkvm();
void switchuvm(struct proc* p);
pde_t *copyuvm(pde_t *pgdir, uint sz);
int allocuvm(pde_t *pgdir, uint oldsz, uint newsz);
int deallocuvm(pde_t *pgdir, uint oldsz, uint newsz);
void freeuvm(pde_t*);
int loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz);
void clearpteu(pde_t *pgdir, char *uva);
void freevm(pde_t *pgdir);
int copyout(pde_t *pgdir, uint va, void *p, uint len);

#endif