#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

#include "tox.h"

static void *tox_thread_loop(void *user_data);

UNIFEX_TERM version(UnifexEnv *env) {
  uint32_t major = tox_version_major();
  uint32_t minor = tox_version_minor();
  uint32_t patch = tox_version_patch();
  return version_result_ok(env, major, minor, patch);
}

UNIFEX_TERM init(UnifexEnv *env) {
  TOX_ERR_NEW tox_error;
  State *state = unifex_alloc_state(env);
  Tox *tox = tox_new(NULL, &tox_error);

  if (tox_error != TOX_ERR_NEW_OK) {
    switch(tox_error) {
    case TOX_ERR_NEW_NULL:
      return unifex_raise(env, "null");
      break;
    default:
      return unifex_raise(env, "unexpected: error not implemented");
    }
  }

  state->tox_done = 0;
  state->tox = tox;
  state->env = env;

  if (pthread_mutex_init(&state->lock, NULL) != 0) {
    return unifex_raise(env, "failed to create state mutex");
  }

  if (pthread_create(&state->tox_tid, NULL, tox_thread_loop, (void *)state) != 0) {
    return unifex_raise(env, "failed to create tox thread");
  }

  return init_result_ok(env, state);
}

static void *tox_thread_loop(void *user_data) {
  State *state = (State *)user_data;

  while(!state->tox_done) {
    tox_iterate(state->tox, (void *)state);
    usleep(tox_iteration_interval(state->tox));
  }

  state->tox_done = 0;
  return NULL;
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  state->tox_done = 1;
  while(state->tox_done != 0) {
    usleep(100);
  }

  pthread_kill(state->tox_tid, SIGKILL);
  pthread_mutex_destroy(&state->lock);

  if (state->tox) {
    tox_kill(state->tox);
    state->tox = NULL;
  }
}
