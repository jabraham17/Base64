
/*
  Encoding and decoding of Base64, supporting both standard
  (`RFC 4648 §4 <https://datatracker.ietf.org/doc/html/rfc4648#section-4>`_)
  and URL-safe
  (`RFC 4648 §5 <https://datatracker.ietf.org/doc/html/rfc4648#section-5>`_)
  alphabets. All functions operate on :type:`bytes` values.
*/
@chpldoc.noUsage
@chpldoc.noAutoInclude
module Base64 {

  /*
    Encode binary data to a Base64 string.

    When ``urlSafe`` is ``false`` (the default), uses the standard alphabet
    (``+``, ``/``). When ``true``, uses the URL-safe alphabet (``-``, ``_``).
  */
  proc b64Encode(x: bytes, param urlSafe=false): bytes do
    return if urlSafe then b64UrlSafeEncode(x)
                      else b64StandardEncode(x);

  /*
    Decode a Base64 string to binary data.

    When ``urlSafe`` is ``false`` (the default), expects the standard
    alphabet. When ``true``, expects the URL-safe alphabet.
  */
  proc b64Decode(x: bytes, param urlSafe=false): bytes do
    return if urlSafe then b64UrlSafeDecode(x)
                      else b64StandardDecode(x);

  /* Encode binary data using the standard Base64 alphabet (``+``, ``/``). */
  proc b64StandardEncode(x: bytes): bytes do
    return b64EncodeImpl(x);

  /* Decode a Base64 string using the standard alphabet (``+``, ``/``). */
  proc b64StandardDecode(x: bytes): bytes do
    return b64DecodeImpl(x);

  /* Encode binary data using the URL-safe Base64 alphabet (``-``, ``_``). */
  proc b64UrlSafeEncode(x: bytes): bytes do
    return b64EncodeImpl(x, b"-", b"_");

  /* Decode a Base64 string using the URL-safe alphabet (``-``, ``_``). */
  proc b64UrlSafeDecode(x: bytes): bytes do
    return b64DecodeImpl(x, b"-", b"_");




  private param alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  private param padding = b"=";

  private proc b64EncodeImpl(x: bytes, param plus = b"+", param slash = b"/"): bytes {
    const len = x.size;
    if len == 0 then return b"";

    const outLen = ((len + 2) / 3) * 4;
    var result: bytes;

    var i = 0;
    while i < len - 2 {
      const a = x[i];
      const b = x[i+1];
      const c = x[i+2];

      result += encodeChar((a >> 2): int, plus, slash);
      result += encodeChar((((a & 0x03) << 4) | (b >> 4)): int, plus, slash);
      result += encodeChar((((b & 0x0F) << 2) | (c >> 6)): int, plus, slash);
      result += encodeChar((c & 0x3F): int, plus, slash);

      i += 3;
    }

    // Handle remaining bytes
    if len - i == 2 {
      const a = x[i];
      const b = x[i+1];
      result += encodeChar((a >> 2): int, plus, slash);
      result += encodeChar((((a & 0x03) << 4) | (b >> 4)): int, plus, slash);
      result += encodeChar(((b & 0x0F) << 2): int, plus, slash);
      result += padding;
    } else if len - i == 1 {
      const a = x[i];
      result += encodeChar((a >> 2): int, plus, slash);
      result += encodeChar(((a & 0x03) << 4): int, plus, slash);
      result += padding;
      result += padding;
    }

    return result;
  }

  private proc encodeChar(idx: int, param plus: bytes, param slash: bytes): bytes {
    if idx < 62 then return alphabet.item[idx];
    else if idx == 62 then return plus;
    else return slash;
  }

  private proc decodeChar(ch: uint(8), param plus: bytes, param slash: bytes): int {
    if ch >= 0x41 && ch <= 0x5A then return (ch - 0x41): int;        // A-Z
    else if ch >= 0x61 && ch <= 0x7A then return (ch - 0x61 + 26): int; // a-z
    else if ch >= 0x30 && ch <= 0x39 then return (ch - 0x30 + 52): int; // 0-9
    else if ch == plus.toByte() then return 62;
    else if ch == slash.toByte() then return 63;
    else return -1; // padding or invalid
  }

  private proc b64DecodeImpl(x: bytes, param plus = b"+", param slash = b"/"): bytes {
    const len = x.size;
    if len == 0 then return b"";

    var result: bytes;
    var i = 0;

    while i < len {
      // Skip whitespace/newlines
      if x[i] == 0x0A || x[i] == 0x0D ||
         x[i] == 0x20 || x[i] == 0x09 {
        i += 1;
        continue;
      }

      // Need at least 2 valid chars for a group
      const a = decodeChar(x[i], plus, slash);
      const b = if i+1 < len then decodeChar(x[i+1], plus, slash) else 0;
      const c = if i+2 < len then decodeChar(x[i+2], plus, slash) else 0;
      const d = if i+3 < len then decodeChar(x[i+3], plus, slash) else 0;

      param mask = 0xFF:uint(8);
      result.appendByteValues((((a << 2) | (b >> 4)) & mask):uint(8));

      if i+2 < len && x[i+2] != padding.toByte() {
        result.appendByteValues((((b << 4) | (c >> 2)) & mask):uint(8));
      }
      if i+3 < len && x[i+3] != padding.toByte() {
        result.appendByteValues((((c << 6) | d) & mask):uint(8));
      }

      i += 4;
    }

    return result;
  }

}
