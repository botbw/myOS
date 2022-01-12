#ifndef VM_H
#define VM_H

struct proc;

void kvminit();
pde_t* setupkvm();
void inituvm(pde_t *pgdir, char *init, uint sz);
void switchkvm();
void switchuvm(struct proc* p);

#endif