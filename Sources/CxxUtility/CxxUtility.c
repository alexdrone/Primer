#include "CxxUtility.h"

#import <stdatomic.h>
#include <setjmp.h>

long __atomicExchange(_Atomic long* value, long desired) {
  return atomic_exchange(value, desired);
}

void __atomicStore(_Atomic long* value, long desired) {
  atomic_store(value, desired);
}

long __atomicFetchAdd(_Atomic long* value, long operand) {
  return atomic_fetch_add(value, operand);
}

int __atomicCompareExchange(_Atomic long* value, long* expected, long desired) {
  return atomic_compare_exchange_strong(value, expected, desired);
}

int __atomicIsLockFree(_Atomic long* value) {
  return atomic_is_lock_free(value);
}
