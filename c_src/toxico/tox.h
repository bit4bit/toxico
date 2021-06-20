#pragma once

#include <pthread.h>

#include <tox/tox.h>
#include <unifex/unifex.h>

typedef struct State State;

struct State {
  UnifexEnv *env;
  Tox *tox;
  pthread_t tox_tid;
};

#include "_generated/tox.h"
