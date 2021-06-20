#pragma once

#include <pthread.h>
#include <tox/tox.h>

#include <unifex/unifex.h>

typedef struct State State;

struct State {
  UnifexEnv *env;
  Tox *tox;
  int tox_done;
  pthread_t tox_tid;
  pthread_mutex_t lock;
};

#include "_generated/tox.h"
