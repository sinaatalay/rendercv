@echo off
rem
rem Public domain. Originally written by A. Kakuto, 2021.
rem Run XeLaTeX unsafely, for pstricks/transparency. See man page for more.
if x%1 == x--help (
echo Usage: xelatex-unsafe [XETEX-ARGUMENT]...
echo Run XeLaTeX unsafely, that is, using dvipdfmx-unsafe.cfg.  All
echo command-line arguments, except --help and --version, are passed as-is to
echo XeLaTeX.
echo. 
echo As of TeX Live 2022, doing this is needed only when running XeLaTeX on
echo documents using PSTricks features which require transparency. We
echo recommend using LuaLaTeX with PSTricks instead of XeLaTeX in this case.
echo.
echo At all costs, avoid using this, or any, unsafe invocation with documents
echo off the net or that are otherwise untrusted in any way.
echo.
echo For more details on this, please see the xetex-unsafe man page,
echo or "texdoc xetex-unsafe".
echo.
echo For more about XeTeX: https://tug.org/xetex
echo For more about PSTricks: https://tug.org/PSTricks
echo Email for xelatex-unsafe specifically: https://lists.tug.org/dvipdfmx
exit 0
) else if x%1 == x--version (
echo 0.001
exit 0
)
xelatex -output-driver="xdvipdfmx -i dvipdfmx-unsafe.cfg -q -E" %*
