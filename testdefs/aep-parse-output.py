#!/usr/bin/env python
# -*- coding: utf-8 -*-
#

def isfloat(value):
  try:
    float(value)
    return True
  except ValueError:
    return False

def main(args):
    values = []
    with open('/tmp/aep-data.log', 'r') as log:
        data = log.read()
    for line in data.split('\n'):
        value_list = line.split(' ')
        if not isfloat(value_list[0]):
            continue
        values.append(value_list)
    if len(values) == 0:
        return 1
    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main(sys.argv))
