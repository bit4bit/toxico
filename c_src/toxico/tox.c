#include <pthread.h>

#include "tox.h"

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

  state->tox = tox;
  state->env = env;

  return init_result_ok(env, state);
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  if (state->tox) {
    tox_kill(state->tox);
    state->tox = NULL;
  }
}
