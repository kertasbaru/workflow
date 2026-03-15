# Deobfuscation: willstore69/toolkit

Deobfuscation analysis of the obfuscated `aio-mod` script from
[willstore69/toolkit](https://github.com/willstore69/toolkit).

## Summary

The `aio-mod` file uses **5 layers of obfuscation**:

1. **UU-encoded ELF binary** — A modified bash shell for aarch64 embedded in the script
2. **XOR-encoded bootstrap script** — Bash code hidden inside the binary using a 16-byte
   XOR salt with multi-segment encoding (223 XOR operations)
3. **Fragmented AES key** — The decryption key split into 4 parts, each using a different
   encoding (hex escapes, base64, ROT13)
4. **AES-256-CBC encryption** — PBKDF2 key derivation (100K iterations) protecting a ZIP
   payload
5. **Nuitka compilation** — The final Python program compiled to native aarch64 machine
   code, preventing source recovery

## Deobfuscated Files

All recovered artifacts are in the [`deobfuscated/`](deobfuscated/) directory:

| File | Description |
|------|-------------|
| [ANALYSIS.md](deobfuscated/ANALYSIS.md) | Detailed technical analysis of all obfuscation layers |
| [bootstrap_script.sh](deobfuscated/bootstrap_script.sh) | Reconstructed bootstrap script (was XOR-encoded in binary) |
| [decrypt_payload.py](deobfuscated/decrypt_payload.py) | AES decryption script (was embedded in bootstrap) |
| [encryption_parameters.json](deobfuscated/encryption_parameters.json) | All recovered encryption keys and parameters |
| [payload_file_listing.txt](deobfuscated/payload_file_listing.txt) | Contents of the decrypted ZIP payload |

## Key Findings

- **Target platform**: Android aarch64 (Termux)
- **AES key recovered**: `iDBx9XB7iHLfh0jV2AM7XR1B0OT1JIBL`
- **Payload**: Nuitka-compiled Python app using asyncio, requests, Crypto, and socket
- **Original source** (`aio-mod_encoded_ready.py`): Not recoverable (compiled to native code)

See [deobfuscated/ANALYSIS.md](deobfuscated/ANALYSIS.md) for the complete technical
analysis.
