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

UNIFEX_TERM self_set_status(UnifexEnv *env, UserStatus status) {
  State *state = (State *)env->state;

  MUST_STATE(env);

  switch(status) {
  case USER_NONE:
    tox_self_set_status(state->tox, TOX_USER_STATUS_NONE);
    break;
  case USER_AWAY:
    tox_self_set_status(state->tox, TOX_USER_STATUS_AWAY);
    break;
  case USER_BUSY:
    tox_self_set_status(state->tox, TOX_USER_STATUS_BUSY);
    break;
  }

  return self_set_status_result(env);
}

UNIFEX_TERM self_get_status(UnifexEnv *env) {
  State *state = (State *)env->state;
  TOX_USER_STATUS status;

  MUST_STATE(env);

  status = tox_self_get_status(state->tox);
  switch(status) {
  case TOX_USER_STATUS_NONE:
    return self_get_status_result(env, USER_NONE);
  case TOX_USER_STATUS_AWAY:
    return self_get_status_result(env, USER_AWAY);
  case TOX_USER_STATUS_BUSY:
    return self_get_status_result(env, USER_BUSY);
  default:
    return unifex_raise(env, "unimplemented");
  }
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
    return self_get_name_result(env, "");

  name = (unsigned char *)malloc(sizeof(unsigned char) * name_size + 1);
  if (name == NULL) return unifex_raise(env, "malloc");

  tox_self_get_name(state->tox, name);
  name[name_size] = '\0';

  return self_get_name_result(env, name);
}

UNIFEX_TERM self_set_status_message(UnifexEnv *env, char *message) {
  State *state = (State *)env->state;
  TOX_ERR_SET_INFO error;
  size_t len = MIN(strlen(message), TOX_MAX_STATUS_MESSAGE_LENGTH - 1);

  MUST_STATE(env);

  tox_self_set_status_message(state->tox, message, len, &error);
  switch(error) {
  case TOX_ERR_SET_INFO_OK:
    return self_set_status_message_result(env);
  default:
    return unifex_raise(env, "fail set message");
  }
}

UNIFEX_TERM self_get_status_message(UnifexEnv *env) {
  State *state = (State *)env->state;
  unsigned char *message = NULL;
  size_t message_size = 0;

  MUST_STATE(env);

  message_size = tox_self_get_status_message_size(state->tox);
  if (message_size == 0)
    return self_get_status_message_result(env, "");

  message = (unsigned char *)malloc(sizeof(unsigned char) * message_size + 1);
  if (message == NULL) return unifex_raise(env, "malloc");

  tox_self_get_status_message(state->tox, message);
  message[message_size] = '\0';

  return self_get_status_message_result(env, message);
}

UNIFEX_TERM self_get_address(UnifexEnv *env) {
  State *state = (State *)env->state;

  char id_string[TOX_ADDRESS_SIZE * 2 + 1];
  char bin_id[TOX_ADDRESS_SIZE];
  MUST_STATE(env);

  tox_self_get_address(state->tox, bin_id);
  if (bin_id_to_string(bin_id, sizeof(bin_id), id_string, sizeof(id_string)) == -1) {
    return unifex_raise(env, "failed to encode ID");
  }

  return self_get_address_result(env, id_string);
}

UNIFEX_TERM self_get_nospam(UnifexEnv *env) {
  State *state = (State *)env->state;
  unsigned int nospam = 0;

  MUST_STATE(env);

  nospam = tox_self_get_nospam(state->tox);
  self_get_nospam_result(env, nospam);
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

void on_connection_status_cb(Tox *tox, TOX_CONNECTION connection_status, void *user_data) {
  UnifexEnv *env = (UnifexEnv *)user_data;
  ConnectionStatus status;

  switch(connection_status) {
  case TOX_CONNECTION_NONE:
    status = CONNECTION_NONE;
    break;
  case TOX_CONNECTION_UDP:
    status = CONNECTION_UDP;
    break;
  case TOX_CONNECTION_TCP:
    status = CONNECTION_TCP;
    break;
  default:
    return;
  }

  send_connection_status(env, *(env->reply_to), 0, status);
}

void on_friend_request_cb(Tox *tox, const uint8_t *public_key, const uint8_t *message, size_t length, void *user_data) {
  UnifexEnv *env = (UnifexEnv *)user_data;
  State *state = (State *)env->state;
  char public_key_id[TOX_PUBLIC_KEY_SIZE * 2 + 1];

  if (bin_pubkey_to_string(public_key, TOX_PUBLIC_KEY_SIZE, public_key_id, sizeof(public_key_id)) < 0) {
    send_friend_request_error(env, *(env->reply_to), 0, "fail to encode public key");
    return;
  }

  send_friend_request(env, *(env->reply_to), 0, public_key_id, message);
}

UNIFEX_TERM friend_add(UnifexEnv *env, char *hex_address, char *message) {
  State *state = (State *)env->state;
  unsigned char address[TOX_ADDRESS_SIZE];
  TOX_ERR_FRIEND_ADD error;

  MUST_STATE(env);

  if (hex_string_to_bin(hex_address, strlen(hex_address), &address, sizeof(address)) < 0) {
    return unifex_raise(env, "failed to convert hex public key to binary");
  }

  tox_friend_add(state->tox, address, message, strlen(message), &error);
  switch(error) {
  case TOX_ERR_FRIEND_ADD_OK:
    return friend_add_result(env);
  case TOX_ERR_FRIEND_ADD_NULL:
    return friend_add_result_error(env, "null");
  case TOX_ERR_FRIEND_ADD_TOO_LONG:
    return friend_add_result_error(env, "too_long");
  case TOX_ERR_FRIEND_ADD_NO_MESSAGE:
    return friend_add_result_error(env, "no_message");
  case TOX_ERR_FRIEND_ADD_OWN_KEY:
    return friend_add_result_error(env, "own_key");
  case TOX_ERR_FRIEND_ADD_ALREADY_SENT:
    return friend_add_result_error(env, "already_sent");
  case TOX_ERR_FRIEND_ADD_BAD_CHECKSUM:
    return friend_add_result_error(env, "bad_checksum");
  case TOX_ERR_FRIEND_ADD_SET_NEW_NOSPAM:
    return friend_add_result_error(env, "set_new_nospaw");
  case TOX_ERR_FRIEND_ADD_MALLOC:
    return friend_add_result_error(env, "malloc");
  default:
    return unifex_raise(env, "unimplemented");
  }
}

UNIFEX_TERM friend_add_norequest(UnifexEnv *env, char *hex_public_key) {
  State *state = (State *)env->state;
  char public_key[TOX_PUBLIC_KEY_SIZE];
  TOX_ERR_FRIEND_ADD error;
  uint32_t friend_number = 0;

  MUST_STATE(env);

  if (hex_string_to_bin(hex_public_key, strlen(hex_public_key), &public_key, TOX_PUBLIC_KEY_SIZE) < 0) {
    return unifex_raise(env, "failed to convert hex public key to binary");
  }

  friend_number = tox_friend_add_norequest(state->tox, public_key, &error);
  switch(error) {
  case TOX_ERR_FRIEND_ADD_OK:
    return friend_add_norequest_result(env, friend_number);
  case TOX_ERR_FRIEND_ADD_NULL:
    return friend_add_norequest_result_error(env, "null");
  case TOX_ERR_FRIEND_ADD_TOO_LONG:
    return friend_add_norequest_result_error(env, "too_long");
  case TOX_ERR_FRIEND_ADD_NO_MESSAGE:
    return friend_add_norequest_result_error(env, "no_message");
  case TOX_ERR_FRIEND_ADD_OWN_KEY:
    return friend_add_norequest_result_error(env, "own_key");
  case TOX_ERR_FRIEND_ADD_ALREADY_SENT:
    return friend_add_norequest_result_error(env, "already_sent");
  case TOX_ERR_FRIEND_ADD_BAD_CHECKSUM:
    return friend_add_norequest_result_error(env, "bad_checksum");
  case TOX_ERR_FRIEND_ADD_SET_NEW_NOSPAM:
    return friend_add_norequest_result_error(env, "set_new_nospaw");
  case TOX_ERR_FRIEND_ADD_MALLOC:
    return friend_add_norequest_result_error(env, "malloc");
  default:
    return unifex_raise(env, "unimplemented");
  }
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

  tox_callback_friend_request(tox, on_friend_request_cb);
  tox_callback_self_connection_status(tox, on_connection_status_cb);

  state->tox_done = 0;
  state->tox = tox;
  state->env = env;

  if (pthread_mutex_init(&state->lock, NULL) != 0) {
    return unifex_raise(env, "failed to create state mutex");
  }

  if (pthread_create(&state->tox_tid, NULL, tox_thread_loop, (void *)env) != 0) {
    return unifex_raise(env, "failed to create tox thread");
  }

  return init_result_ok(env, state);
}

static void *tox_thread_loop(void *user_data) {
  UnifexEnv *env = (UnifexEnv *)user_data;
  State *state = (State *)env->state;

  while(!state->tox_done) {
    tox_iterate(state->tox, (void *)env);
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
