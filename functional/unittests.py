#!/usr/bin/python

import os
import argparse
import fileinput


def main(lava=False, files='-'):
    for line in fileinput.input(files):
        line = line.strip()
        print(line)
        if line.lower().startswith('test') or line.startswith('linaro_dashboard_bundle.tests'):
            line = line.replace('.', '_')
            line = line.replace(' ', '_')
            line = line.replace('\'', '_')
            line = line.replace('/', '_')
            line = line.replace('(', '')
            line = line.replace(')', '')
            if line.endswith('ok'):
                line = line.replace('_____ok', '')
                if lava:
                    os.system("lava-test-case %s --result pass" % line.split(':')[0])
                else:
                    print("lava-test-case %s --result pass" % line.split(':')[0])
            elif '_skipped_' in line:
                if lava:
                    os.system("lava-test-case %s --result skip" % line.split(':')[0])
                else:
                    print("lava-test-case %s --result skip" % line.split(':')[0])
            elif line.endswith('FAIL') or line.endswith('ERROR'):
                line = line.replace('_____FAIL', '')
                line = line.replace('_____ERROR', '')
                if lava:
                    os.system("lava-test-case %s --result fail" % line.split(':')[0])
                else:
                    print("lava-test-case %s --result fail" % line.split(':')[0])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--lava', dest='lava', action='store_true', help='call lava-test-case')
    parser.add_argument('files', metavar='FILE', nargs='*', help='files to read, if empty, stdin is used')
    args = parser.parse_args()
    main(lava=vars(args)['lava'], files=args.files)
