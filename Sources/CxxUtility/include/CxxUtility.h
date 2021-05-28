#ifndef CxxUtility_h
#define CxxUtility_h

#include <stdio.h>

long std_atomic_exchange(_Atomic long* value, long desired);

void std_atomic_store(_Atomic long* value, long desired);

long std_atomic_fetch_add(_Atomic long* value, long operand);

int std_atomic_compare_exchange_strong(_Atomic long* value, long* expected, long desired);

int std_atomic_is_lock_free(_Atomic long* value);

long std_atomic_fetch_xor(_Atomic long* value);

#endif /*CxxUtility_h */
