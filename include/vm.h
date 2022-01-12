#ifndef VM_H
#define VM_H

void kvminit();
pde_t* setupkvm();
void inituvm(pde_t *pgdir, char *init, uint sz);

#endif