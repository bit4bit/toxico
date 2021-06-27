#include <stdio.h>
#include <tox/tox.h>

#include "tools.h"

//TOMADO DE https://github.com/JFreegman/toxic/blob/0fc1d9e9944ba1e7598b7039974fc26f1b0b63cb/src/misc_tools.c

/*
 * Converts a hexidecimal string of length hex_len to binary format and puts the result in output.
 * output_size must be exactly half of hex_len.
 *
 * Returns 0 on success.
 * Returns -1 on failure.
 */
int hex_string_to_bin(const char *hex_string, size_t hex_len, char *output, size_t output_size)
{
    if (output_size == 0 || hex_len != output_size * 2) {
        return -1;
    }

    for (size_t i = 0; i < output_size; ++i) {
        sscanf(hex_string, "%2hhx", (unsigned char *)&output[i]);
        hex_string += 2;
    }

    return 0;
}

//TOMADO DE https://github.com/JFreegman/toxic/blob/0fc1d9e9944ba1e7598b7039974fc26f1b0b63cb/src/misc_tools.c
/* Converts a binary representation of a Tox ID into a string.
 *
 * Returns 0 on success.
 * Returns -1 on failure.
 */
int bin_id_to_string(const char *bin_id, size_t bin_id_size, char *output, size_t output_size)
{
    if (bin_id_size != TOX_ADDRESS_SIZE || output_size < (TOX_ADDRESS_SIZE * 2 + 1)) {
        return -1;
    }

    for (size_t i = 0; i < TOX_ADDRESS_SIZE; ++i) {
        snprintf(&output[i * 2], output_size - (i * 2), "%02X", bin_id[i] & 0xff);
    }

    return 0;
}


/* Converts a binary representation of a Tox public key into a string.
 *
 * Returns 0 on success.
 * Returns -1 on failure.
 */
int bin_pubkey_to_string(const uint8_t *bin_pubkey, size_t bin_pubkey_size, char *output, size_t output_size)
{
    if (bin_pubkey_size != TOX_PUBLIC_KEY_SIZE || output_size < (TOX_PUBLIC_KEY_SIZE * 2 + 1)) {
        return -1;
    }

    for (size_t i = 0; i < TOX_PUBLIC_KEY_SIZE; ++i) {
        snprintf(&output[i * 2], output_size - (i * 2), "%02X", bin_pubkey[i] & 0xff);
    }

    return 0;
}
