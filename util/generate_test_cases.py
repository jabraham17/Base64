#!/usr/bin/env python3

import argparse
import base64
import csv
import os
import random
import sys

def generate_random_bytes(max_len=128):
    length = random.randint(0, max_len)
    return os.urandom(length)

def main():
    parser = argparse.ArgumentParser(description="Generate Base64 test cases as CSV")
    parser.add_argument("-c", "--count", type=int, default=100, help="Number of test cases to generate")
    parser.add_argument(
        "-o", "--output", default="-", help="Output CSV file path (default: stdout)"
    )
    parser.add_argument("--max-len", type=int, default=128, help="Maximum length of random byte sequences")
    args = parser.parse_args()

    if args.output == "-":
        f = sys.stdout
    else:
        f = open(args.output, "w", newline="")

    try:
        writer = csv.writer(f)
        writer.writerow(["original_hex", "base64_standard", "base64_urlsafe"])

        for _ in range(args.count):
            raw = generate_random_bytes(args.max_len)
            original_hex = raw.hex()
            b64_standard = base64.b64encode(raw).decode("ascii")
            b64_urlsafe = base64.urlsafe_b64encode(raw).decode("ascii")
            writer.writerow([original_hex, b64_standard, b64_urlsafe])
    finally:
        if f is not sys.stdout:
            f.close()
            print(f"Wrote {args.count} test cases to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
