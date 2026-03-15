"""
DEOBFUSCATED AES DECRYPTION SCRIPT
===================================
This Python script was embedded (XOR-encoded) inside the modified bash binary.
It performs AES-256-CBC decryption with PBKDF2 key derivation.

Usage (as invoked by the bootstrap script):
    python3 decrypt_payload.py <key> <encrypted_file> <output_file>

Parameters:
    key             = "iDBx9XB7iHLfh0jV2AM7XR1B0OT1JIBL" (32 chars)
    encrypted_file  = path to base64-decoded data from __DATA_BELOW__
    output_file     = path to write decrypted ZIP archive

Encryption details:
    Algorithm:    AES-256-CBC
    Key derivation: PBKDF2-HMAC-SHA256
    PBKDF2 salt:  b'aiomodsalt'
    Iterations:   100,000
    Key length:   32 bytes (256 bits)
    IV:           First 16 bytes of encrypted data
    Padding:      PKCS7
"""

import sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import hashlib

key = sys.argv[1].encode()
data = open(sys.argv[2], 'rb').read()

dk = hashlib.pbkdf2_hmac('sha256', key, b'aiomodsalt', 100000, 32)

iv = data[:16]
enc = data[16:]

dec = unpad(AES.new(dk, AES.MODE_CBC, iv).decrypt(enc), AES.block_size)

open(sys.argv[3], 'wb').write(dec)
