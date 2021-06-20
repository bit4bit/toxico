#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

#include "tox.h"
#include "tools.h"

static void *tox_thread_loop(void *user_data);

#define MUST_STATE(env) if(env->state == NULL) return unifex_raise(env, "not initialize state, please call `init` first")

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

UNIFEX_TERM version(UnifexEnv *env) {
  uint32_t major = tox_version_major();
  uint32_t minor = tox_version_minor();
  uint32_t patch = tox_version_patch();
  return version_result_ok(env, major, minor, patch);
}

UNIFEX_TERM self_set_name(UnifexEnv *env, char *name) {
  State *state = (State *)env->state;
  TOX_ERR_SET_INFO error;
  size_t len = MIN(strlen(name), TOX_MAX_NAME_LENGTH - 1);

  MUST_STATE(env);

  tox_self_set_name(state->tox, name, len, &error);
  switch(error) {
  case TOX_ERR_SET_INFO_OK:
    return self_set_name_result(env);
  default:
    return unifex_raise(env, "fail set name");
  }
}

UNIFEX_TERM self_get_name(UnifexEnv *env) {
  State *state = (State *)env->state;
  unsigned char *name = NULL;
  size_t name_size = 0;

  MUST_STATE(env);

  name_size = tox_self_get_name_size(state->tox);
  if (name_size == 0)
    return self_get_name_result_ok(env, "");

  name = (unsigned char *)malloc(sizeof(unsigned char) * name_size + 1);
  if (name == NULL) return unifex_raise(env, "malloc");

  tox_self_get_name(state->tox, name);
  name[name_size] = '\0';

  return self_get_name_result_ok(env, name);
}

UNIFEX_TERM bootstrap(UnifexEnv *env, char *host, unsigned int port, char *hex_public_key) {
  State *state = (State *)env->state;
  char public_key[TOX_PUBLIC_KEY_SIZE];
  TOX_ERR_BOOTSTRAP error;

  MUST_STATE(env);

  if (hex_string_to_bin(hex_public_key, strlen(hex_public_key), &public_key, TOX_PUBLIC_KEY_SIZE) < 0) {
    return unifex_raise(env, "failed to convert hex public key to binary");
  }

  tox_bootstrap(state->tox, host, port, public_key, &error);
  switch(error) {
  case TOX_ERR_BOOTSTRAP_OK:
    break;
  case TOX_ERR_BOOTSTRAP_NULL:
    return bootstrap_result_error(env, "null");
  case TOX_ERR_BOOTSTRAP_BAD_HOST:
    return bootstrap_result_error(env, "bad_host");
  case TOX_ERR_BOOTSTRAP_BAD_PORT:
    return bootstrap_result_error(env, "bad_port");
  }

  return bootstrap_result(env);
}

UNIFEX_TERM init(UnifexEnv *env) {
  TOX_ERR_NEW tox_error;
  State *state = (State *)unifex_alloc_state(env);
  struct Tox_Options tox_opts;
  Tox *tox = NULL;

  tox_options_default(&tox_opts);
  tox = tox_new(&tox_opts, &tox_error);
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
