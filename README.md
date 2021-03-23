# cat_asm
A simple clone of the `cat` tool, written in x86\_64 assembler using system calls.

The program currently supports printing multiple files to stdout and copying stdin to stdout if no file is specified. An output for `--help` is not yet implemented.

Be aware that the code is not portable, as it is written in x86\_64 assembler only, following the Sys V ABI. Furthermore, constants such as `O_RDONLY` might differ, depending on the platform. The code uses directives from `gnu as`.
