#!/bin/sh
# $Id: updmap-sys.sh 36962 2015-04-20 01:48:35Z preining $
# updmap-sys - arrange for updmap to affect system directories.
# Maintained in Master/texmf-dist/scripts/texlive/
# Public domain.  Originally written by Thomas Esser.

test -f /bin/ksh && test -z "$RUNNING_KSH" \
  && { UNAMES=`uname -s`; test "x$UNAMES" = xULTRIX; } 2>/dev/null \
  && { RUNNING_KSH=true; export RUNNING_KSH; exec /bin/ksh $0 ${1+"$@"}; }
unset RUNNING_KSH

test -f /bin/bsh && test -z "$RUNNING_BSH" \
  && { UNAMES=`uname -s`; test "x$UNAMES" = xAIX; } 2>/dev/null \
  && { RUNNING_BSH=true; export RUNNING_BSH; exec /bin/bsh $0 ${1+"$@"}; }
unset RUNNING_BSH

# preferentially use subprograms from our own directory.
mydir=`echo "$0" | sed 's,/[^/]*$,,'`
mydir=`cd "$mydir" && pwd`
PATH="$mydir:$PATH"; export PATH

# hack around a bug in zsh:
test -n "${ZSH_VERSION+set}" && alias -g '${1+"$@"}'='"$@"'

exec updmap --sys ${1+"$@"}
