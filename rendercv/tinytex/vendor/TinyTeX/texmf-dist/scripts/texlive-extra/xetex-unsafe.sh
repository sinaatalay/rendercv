#!/bin/sh
# $Id: xetex-unsafe.sh 61101 2021-11-20 23:01:11Z karl $
# Public domain. Originally written by Karl Berry, 2021.
# Run Xe(La)TeX unsafely, for pstricks/transparency. See man page for more.

if test "x$1" = x--help; then
  cat <<END_USAGE
Usage: $0 [XETEX-ARGUMENT]...

Run Xe(La)TeX unsafely, that is, using dvipdfmx-unsafe.cfg.  All
command-line arguments, except --help and --version, are passed as-is to
Xe(La)TeX.

As of TeX Live 2022, doing this is needed only when running XeTeX on
documents using PSTricks features which require transparency. We
recommend using Lua(La)TeX with PSTricks instead of XeTeX in this case.

At all costs, avoid using this, or any, unsafe invocation with documents
off the net or that are otherwise untrusted in any way.

For more details on this, please see the xetex-unsafe(1) man page,
or "texdoc xetex-unsafe".

For more about XeTeX: https://tug.org/xetex
For more about PSTricks: https://tug.org/PSTricks
Email for xe(la)tex-unsafe specifically: https://lists.tug.org/dvipdfmx
END_USAGE
  echo '$Id: xetex-unsafe.sh 61101 2021-11-20 23:01:11Z karl $'
  exit 0

elif test "x$1" = x--version; then
  echo '$Id: xetex-unsafe.sh 61101 2021-11-20 23:01:11Z karl $'
  exit 0
fi
  
cmd=`echo "$0" | sed s/-unsafe//`
exec "$cmd" -output-driver="xdvipdfmx -i dvipdfmx-unsafe.cfg -q -E" "$@"
