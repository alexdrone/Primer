#include "CxxUtility.h"

#import <stdatomic.h>
#include <setjmp.h>

long std_atomic_exchange(_Atomic long* value, long desired) {
  return atomic_exchange(value, desired);
}

void std_atomic_store(_Atomic long* value, long desired) {
  atomic_store(value, desired);
}

long std_atomic_fetch_add(_Atomic long* value, long operand) {
  return atomic_fetch_add(value, operand);
}

int std_atomic_compare_exchange_strong(_Atomic long* value, long* expected, long desired) {
  return atomic_compare_exchange_strong(value, expected, desired);
}

int std_atomic_is_lock_free(_Atomic long* value) {
  return atomic_is_lock_free(value);
}

long std_atomic_fetch_xor(_Atomic long* value) {
  return atomic_fetch_xor(value, 1);
}
