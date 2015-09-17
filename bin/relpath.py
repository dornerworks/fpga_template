#! /usr/bin/env python

import sys
import os.path

def main():
    p = os.path.relpath(sys.argv[1], sys.argv[2])
    print '/'.join(p.split('\\'))

if __name__ == '__main__':
    main()
