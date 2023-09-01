#!/bin/sh
# $Id: xelatex-unsafe.sh 61114 2021-11-21 22:13:13Z karl $
# Public domain. Originally written by Karl Berry, 2021.
# Run Xe(La)TeX unsafely, for pstricks/transparency. See man page for more.

if test "x$1" = x--help; then
  mydir=`dirname $0`
  if test -r "$mydir"/xetex-unsafe; then
    xu="$mydir"/xetex-unsafe
  elif test -r "$mydir"/xetex-unsafe.sh; then
    xu="$mydir"/xetex-unsafe.sh
  else
    echo "$0: can't find companion xetex-unsafe[.sh] for help msg?" >&2
    exit 1
  fi
  exec "$xu" --help # don't want to duplicate help message.

elif test "x$1" = x--version; then
  echo "$Id: xelatex-unsafe.sh 61114 2021-11-21 22:13:13Z karl $"
  exit 0
fi
  
cmd=`echo "$0" | sed s/-unsafe//`
exec "$cmd" -output-driver="xdvipdfmx -i dvipdfmx-unsafe.cfg -q -E" "$@"
