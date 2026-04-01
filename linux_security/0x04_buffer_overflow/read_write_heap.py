#!/usr/bin/python3
import sys


def error():
    print("Usage: read_write_heap.py pid search_string replace_string")
    sys.exit(1)


# Check arguments
if len(sys.argv) != 4:
    error()

pid = sys.argv[1]
search = sys.argv[2].encode()
replace = sys.argv[3].encode()

if len(replace) > len(search):
    print("Error: replace_string must not be longer than search_string")
    sys.exit(1)


# Step 1: Find heap addresses
heap_start = None
heap_end = None

try:
    with open("/proc/{}/maps".format(pid), "r") as maps:
        for line in maps:
            if "[heap]" in line:
                parts = line.split()
                addresses = parts[0]
                heap_start, heap_end = [
                    int(x, 16) for x in addresses.split('-')
                ]
                break
except Exception:
    print("Error: Cannot read maps")
    sys.exit(1)

if heap_start is None:
    print("Error: Heap not found")
    sys.exit(1)


# Step 2: Read and write memory
try:
    with open("/proc/{}/mem".format(pid), "rb+") as mem:
        mem.seek(heap_start)
        heap = mem.read(heap_end - heap_start)

        index = heap.find(search)

        while index != -1:
            mem.seek(heap_start + index)
            mem.write(replace + b'\x00' * (len(search) - len(replace)))

            index = heap.find(search, index + 1)

except Exception:
    print("Error:", e)
    sys.exit(1)
