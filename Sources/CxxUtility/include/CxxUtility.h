#ifndef CxxUtility_h
#define CxxUtility_h

#include <stdio.h>

long __atomicExchange(_Atomic long* value, long desired);

void __atomicStore(_Atomic long* value, long desired);

long __atomicFetchAdd(_Atomic long* value, long operand);

int __atomicCompareExchange(_Atomic long* value, long* expected, long desired);

int __atomicIsLockFree(_Atomic long* value);

#endif /*CxxUtility_h */
