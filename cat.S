#define PATH_MAX 4096
#define O_RDONLY 0
#define O_DIRECTORY 65536

.intel_syntax noprefix

.section .bss
.lcomm buffer, PATH_MAX


.section .rodata
str_getcwd:
    .asciz "Cannot get current working directory\n"
str_opencwd:
    .asciz "Cannot open current working directory\n"
str_openfile:
    .asciz "Cannot open file \'"
str_newline:
    .asciz "\'\n"


.section .text
.global _start

# void _start(int argc, char* argv[], char* envp[])
# -----------------------------------------------------------------------
# callee saved registers do not need to saved, since _start has no caller
# -----------------------------------------------------------------------
# the stack looks like this:
#  |   ...       |
#  |   0         | 
#  |   ...       |
#  |   envp[1]   |
#  |   envp[0]   | <- rsp + 8 * argc + 16
#  |   0         |
#  |   ...       |
#  |   argv[1]   |
#  |   argv[0]   | <- rsp + 8
#  |   argc      | <- rsp
_start:
    # store argc
    mov r12, qword ptr [rsp]
    # store argv[1]
    lea r13, [rsp + 16]
    # envp not used

    # align rsp to 16 byte
    and rsp, -16

    # PATH_MAX bytes for buffer
    lea r14, [rip + buffer]

    # check if argument has been provided
    cmp r12, 2
    jge .Lget_cwd

    # copy stdin to stdout
    mov rdi, 0
    call print_file

    xor rdi, rdi
    call _exit

.Lget_cwd:
    # store current working directory in buffer
    mov rdi, r14
    mov rsi, PATH_MAX
    call getcwd
    test rax, rax
    jnz .Lopen_cwd

    # print error message
    mov rdi, 1
    lea rsi, [rip + str_getcwd]
    mov rdx, 37
    call write
    mov rdi, 1
    call _exit

    # open cwd, path is at [r14]
.Lopen_cwd:
    mov rdi, r14
    mov rsi, O_DIRECTORY
    xor rdx, rdx
    call open
    # return value >= 0 means success
    mov r15, rax
    cmp rax, 0
    jge .Lfile_loop_check

    # print error message
    mov rdi, 1
    lea rsi, [rip + str_opencwd]
    mov rdx, 38
    call write
    mov rdi, 1
    call _exit

    # open file, path is stored at [r13]
.Lfile_loop:
    # fd of cwd is stored in r15
    mov rdi, r15
    mov rsi, qword ptr [r13]
    xor rdx, rdx
    call openat
    cmp rax, 0
    jge .Lprint_file

    # print first part of error message
    mov rdi, 1
    lea rsi, [rip + str_openfile]
    mov rdx, 18
    call write
    # print the file name
    mov rdi, qword ptr [r13]
    call strlen
    mov rdi, 1
    mov rsi, qword ptr [r13]
    mov rdx, rax
    call write
    # print the end of the message
    mov rdi, 1
    lea rsi, [rip + str_newline]
    mov rdx, 2
    call write
    mov rdi, 1
    call _exit

.Lprint_file:
    # read from file and output to stdout
    mov rdi, rax
    call print_file

    # close file
    mov rdi, rbx
    call close
    # let r13 point to the next element in argv
    add r13, 8
.Lfile_loop_check:
    # break if no files are left
    cmp qword ptr [r13], 0
    jne .Lfile_loop

    xor rdi, rdi
    call _exit


# void print_file(int fd)
# -----------------------------------------------------------------------
# prints file to stdout, using the buffer at 'buffer'
# not sure if syscall changes rdi and rsi, they are saved just to be sure
print_file:
    push r12
    push r13
    mov r12, rdi
    lea r13, [rip + buffer]

    # align rsp to 16 bytes
    sub rsp, 8

    # read once, then loop
    mov rsi, r13
    mov rdx, PATH_MAX
    call read
    jmp .Lprint_loop_check

.Lprint_loop:
    mov rdi, 1
    mov rsi, r13
    # amount of bytes read (rax) is the amount of bytes to be printed
    mov rdx, rax
    call write

    # read again
    mov rdi, r12
    mov rsi, r13
    mov rdx, PATH_MAX
    call read

.Lprint_loop_check:
    cmp rax, 0
    jg .Lprint_loop

    add rsp, 8
    pop r13
    pop r12
    ret


# size_t strlen(char* str)
# -----------------------------
# str is assumed to be non-NULL
strlen:
    lea rax, [rdi - 1]
.Lstrlen_loop:
    inc rax
    cmp byte ptr [rax], 0
    jne .Lstrlen_loop
    # length = end - start
    sub rax, rdi
    ret


# int read(int fd, char* buffer, int count)
read:
    # read is syscall nr. 0
    mov rax, 0
    syscall
    ret


# int write(int fd, char* buffer, int count)
write:
    # write is syscall nr. 1
    mov rax, 1
    syscall
    ret


# int open(char* file, int flags, int mode)
open:
    # open is syscall nr. 2
    mov rax, 2
    syscall
    ret


# int close(int fd)
close:
    # close is syscall nr. 3
    mov rax, 3
    syscall
    ret


# void _exit(int status)
_exit:
    # exit is syscall nr. 60
    mov rax, 60
    syscall


# char* getcwd(char* buffer, long size)
getcwd:
    # getcwd is syscall nr. 79
    mov rax, 79
    syscall
    ret


# int openat(int dfd, char* file, int flags, int mode)
openat:
    # openat is syscall nr. 257
    mov rax, 257
    syscall
    ret