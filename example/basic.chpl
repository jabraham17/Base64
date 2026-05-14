use Base64;

// Encode a simple message to Base64
const original = b"Hello, World!";
const encoded = b64Encode(original);
writeln("Encoded: ", encoded.decode());

// Decode it back
const decoded = b64Decode(encoded);
writeln("Decoded: ", decoded.decode());

// URL-safe encoding (uses - and _ instead of + and /)
const urlEncoded = b64Encode(original, urlSafe=true);
writeln("URL-safe: ", urlEncoded.decode());

assert(decoded == original);
