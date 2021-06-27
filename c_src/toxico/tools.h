#pragma once

// TOMADO DE https://github.com/JFreegman/toxic/blob/0fc1d9e9944ba1e7598b7039974fc26f1b0b63cb/src/misc_tools.h

/*
 * Converts a hexidecimal string of length hex_len to binary format and puts the result in output.
 * output_size must be exactly half of hex_len.
 *
 * Returns 0 on success.
 * Returns -1 on failure.
 */
int hex_string_to_bin(const char *hex_string, size_t hex_len, char *output, size_t output_size);

// TOMADO DE https://github.com/JFreegman/toxic/blob/0fc1d9e9944ba1e7598b7039974fc26f1b0b63cb/src/misc_tools.h

/* Converts a binary representation of a Tox ID into a string.
 *
 * Returns 0 on success.
 * Returns -1 on failure.
 */
int bin_id_to_string(const char *bin_id, size_t bin_id_size, char *output, size_t output_size);
