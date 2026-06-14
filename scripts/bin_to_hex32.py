#!/usr/bin/env python3
import sys


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print("Usage: bin_to_hex32.py <input.bin> <output.hex> [depth_words]")
        return 1

    in_path = sys.argv[1]
    out_path = sys.argv[2]
    depth_words = int(sys.argv[3]) if len(sys.argv) == 4 else None

    with open(in_path, "rb") as f:
        data = f.read()

    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    with open(out_path, "w", encoding="ascii") as f:
        for i in range(0, len(data), 4):
            word = data[i:i + 4]
            value = int.from_bytes(word, byteorder="little", signed=False)
            f.write(f"{value:08x}\n")

        if depth_words is not None:
            used_words = len(data) // 4
            if depth_words < used_words:
                print(
                    f"[ERROR] depth_words={depth_words} is smaller than used_words={used_words}",
                    file=sys.stderr,
                )
                return 1
            for _ in range(depth_words - used_words):
                f.write("00000013\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
