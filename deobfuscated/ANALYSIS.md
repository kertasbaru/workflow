# Deobfuscation Analysis: willstore69/toolkit

## Overview

Repository analyzed: https://github.com/willstore69/toolkit  
File analyzed: `aio-mod` (sole file in repository)

The repository contains a single file `aio-mod` which is a heavily obfuscated
self-extracting archive targeting **Android (aarch64) devices running Termux**.
It uses **5 layers of obfuscation** to hide its payload.

---

## Obfuscation Layers

### Layer 1: Outer Shell Script (`aio-mod`)

The file is a bash script that:
1. Detects the CPU architecture and requires `aarch64`
2. Contains a **UU-encoded ELF binary** (modified bash shell) between
   `begin 755 /dev/null` and `end` markers
3. Decodes the binary using `uudecode` to a temp file
4. Executes the decoded binary with `_OUTER` environment variable pointing
   back to the original script (for extracting embedded data later)
5. Contains **base64-encoded AES-encrypted data** after a `__DATA_BELOW__` marker

### Layer 2: Modified Bash Binary (ELF aarch64)

The extracted binary is a **patched version of GNU Bash** with:
- Added functions: `xbash_decode()` and `execute_code()`
- Embedded data arrays: `xbash_word` (1326 bytes) and `xbash_salt` (16 bytes)
- `execute_code()` is called during `bash_main()` startup
- Anti-debugging: checks for ptrace/debugger attachment

### Layer 3: XOR-Encoded Bootstrap Script

The `xbash_word` array contains a bash script encoded with multi-segment XOR:
- Different portions use different bytes from the 16-byte `xbash_salt` as XOR keys
- The `execute_code()` function (15,436 bytes of ARM64 code) decodes each
  segment and assembles the final script
- 223 XOR operations decode individual characters and segments

**Recovered XOR Salt (hex):**
```
b4 35 80 07 ab 01 ad 68 03 29 25 b1 9a 7f f5 3c
```

### Layer 4: AES-256-CBC Encryption

The bootstrap script:
1. Reconstructs an AES key from 4 obfuscated fragments:
   - `_a` via hex escapes: `iDBx9XB7`
   - `_b` via base64: `iHLfh0jV`
   - `_c` via ROT13: `2AM7XR1B`
   - `_d` via hex escapes: `0OT1JIBL`
   - **Combined key:** `iDBx9XB7iHLfh0jV2AM7XR1B0OT1JIBL`
2. Extracts base64 data from after `__DATA_BELOW__` in the original script
3. Decrypts using **AES-256-CBC** with **PBKDF2-HMAC-SHA256** key derivation:
   - Salt: `aiomodsalt`
   - Iterations: 100,000
   - Key length: 32 bytes

### Layer 5: ZIP Archive with Nuitka-Compiled Binary

The decrypted payload is a **ZIP archive** (~13.5 MB) containing:
- `aio-mod_encoded_ready.bin` — the main executable (18 MB, ELF aarch64)
- Python 3.13 runtime libraries (`libpython3.13.so`)
- PyCryptodome (Crypto) library modules
- OpenSSL libraries (`libcrypto.so.3`, `libssl.so.3`)
- Various Python extension modules (`.so` files)
- CA certificates (`certifi/cacert.pem`)

---

## Payload Analysis

### Main Binary: `aio-mod_encoded_ready.bin`

| Property | Value |
|----------|-------|
| Format | ELF 64-bit LSB shared object, aarch64 |
| Target | Android (interpreter: `/system/bin/linker64`) |
| Compiler | Nuitka (Python-to-native compiler) |
| Source | `aio-mod_encoded_ready.py` (compiled, not recoverable) |
| Python | 3.13 |
| Size | ~18 MB |
| Build env | Termux on Android |

### Dependencies Used

The binary imports these Python packages (detected via string analysis):

| Package | Purpose |
|---------|---------|
| `asyncio` | Asynchronous I/O framework |
| `requests` | HTTP client library |
| `urllib3` | HTTP connection pooling |
| `Crypto` (PyCryptodome) | Cryptographic operations |
| `charset_normalizer` | Character encoding detection |
| `socket` | Low-level network sockets |
| `ssl` | TLS/SSL connections |
| `certifi` | CA certificate bundle |
| `json` | JSON parsing |
| `hashlib` | Hashing algorithms |
| `multiprocessing` | Process management |
| `sqlite3` | Database operations |

### Build Environment

Built using **Termux** (terminal emulator for Android):
- Build path: `/home/builder/.termux-build/python/`
- Install prefix: `/data/data/com.termux/files/usr/`
- Compiler: `aarch64-linux-android-clang`
- SDK: Android NDK r29, API level 24

---

## Execution Flow Summary

```
aio-mod (bash script)
  │
  ├─ uudecode → modified bash binary (aarch64 ELF)
  │                │
  │                └─ execute_code() → XOR-decode bootstrap script
  │                                      │
  │                                      ├─ Reconstruct AES key from 4 fragments
  │                                      ├─ Extract base64 data from __DATA_BELOW__
  │                                      ├─ AES-256-CBC decrypt → ZIP archive
  │                                      ├─ Unzip to /dev/shm or ~/.cache
  │                                      └─ Execute aio-mod_encoded_ready.bin
  │
  └─ __DATA_BELOW__
       └─ base64-encoded AES-encrypted ZIP payload
```

---

## Files in This Directory

| File | Description |
|------|-------------|
| `bootstrap_script.sh` | Deobfuscated version of the XOR-encoded bootstrap script |
| `decrypt_payload.py` | Deobfuscated Python AES decryption script |
| `payload_file_listing.txt` | Complete listing of files inside the decrypted ZIP |
| `encryption_parameters.json` | All recovered encryption parameters |

---

## Security Notes

1. The binary targets **Android/Termux (aarch64)** — it is designed to run
   on mobile devices
2. The payload uses **asyncio + requests + sockets** — indicating network
   communication capabilities
3. The original Python source (`aio-mod_encoded_ready.py`) is compiled to
   native code via Nuitka and **cannot be trivially recovered**
4. The multiple obfuscation layers (UU-encode → XOR → key fragmentation →
   AES-256 → Nuitka compilation) demonstrate significant effort to prevent
   analysis
5. The binary clears decryption key variables after use and uses random
   temporary directory names
