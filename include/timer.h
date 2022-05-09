#ifndef TIMER_H
#define TIMER_H

#include "spinlock.h"

struct timer
{
    struct spinlock tickslock;
    uint ticks;
};


void timerinit(int freq);

#endif