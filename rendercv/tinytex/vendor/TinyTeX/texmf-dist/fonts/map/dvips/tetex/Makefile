# $Id: Makefile 31831 2013-10-04 18:33:49Z karl $
# Copyright 2013 Karl Berry.
# You may freely use, modify, and/or distribute this file.
#
# Makefile to help with the base35/base14 support in TL.  See ./README.

# The main texmf-dist directory.
xmf = $(shell cd ../../../.. && pwd)

# Pieces of the invocation.
tmpdir = /tmp/umap
umap_env  = TEXMFSYSVAR=$(tmpdir)
#
umap_prog = updmap-sys
umap_opts = --copy --nohash --quiet
umap_cnf  = --cnffile=$(xmf)/web2c/updmap.cfg
#
mapdir   = $(xmf)/fonts/map
umap_out = --dvipdfmxoutputdir=$(mapdir)/dvipdfmx/updmap \
  --dvipsoutputdir=$(mapdir)/dvips/updmap \
  --pdftexoutputdir=$(mapdir)/pdftex/updmap
#
umap_opts_all = $(umap_opts) $(umap_cnf) $(umap_out)

# Rerun updmap, diff results.
makemaps:
	rm -rf $(tmpdir)
	$(umap_env) $(umap_prog) $(umap_opts_all)
	svn status $(mapdir)  $(xmf)/web2c
	svn diff $(mapdir) $(xmf)/web2c \
	  >$(tmpdir)/sdiff

# Conveniently show the pdftex-generated fontflags; inserted the results
# (by hand) in pdftex35.map, 4oct13.  pdftex outputs the flag values in
# the midst of the two-line warning messages.  The sed/etc. nonsense is
# just to print the results nicely.  See $(base).tex for more.
base = base14flags
showflags:
	pdflatex '\nonstopmode\input $(base).tex' >$(base).trn
	sed -n -e 's,.*ded font ,,p' \
	       -e 's,I.m using ,,'  \
	       -e 's,: fix your map entry.,,p' \
	    $(base).log \
	| paste - - \
	| tr -d '	`()'"'" \
	| sort +1 \
	| tee $(base).flags

# Test with minimal LaTeX document.
check:
	pdflatex '\nonstopmode\input base14flags.ltx'
