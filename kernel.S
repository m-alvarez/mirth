#define POP(reg) c.lwsp reg, 0(sp); addi sp, sp, 4
#define PEEK(reg) 
#define PUSH(reg) addi sp, sp, -4; c.swsp reg, 0(sp)

#define TRACENUM2(base) 0x ## base
#define TRACENUM(base) TRACENUM2(base)
#define TRACE li x31, 0xdead0000 + TRACENUM(__LINE__)

.bss
tib: .skip 512

.data
greeting: .string "Hello, world!\n"
prompt: .string "> "
got_str: .string "Got a string!\n"

#define BEGIN_WORD(w) \
    .int _##w##_name_end - .; \
    .int #w; \
    _##w##_name_end: \
    .int 0; \
    .int _##w##_code_end; \
    .int _##w##_data_end; \
    w:
#define END_WORD(w) \
    _##w##_code_end: \
    _##w##_data_end:

.section .dictionary, "ax"

BEGIN_WORD(puts)
    // ( str_ptr -- )
    POP(s1)
    li a6, 0
    li a7, 1
_puts_loop:
    lb a0, 0(s1)
    beqz a0, _puts_loop_end
    ecall
    addi s1, s1, 1
    j _puts_loop
    c.lwsp a0, 0(sp) ; addi sp, sp, 4
_puts_loop_end:
    ret
END_WORD(puts)

BEGIN_WORD(readln)
    // ( buf_ptr -- )
    POP(s1)
    li a6, 0
    li s2, '\n'
_readln_loop:
    li a7, 2
    ecall
    beqz a0, _readln_loop
    li a7, 1
    //ecall
    li a7, 2
    beq a0, s2, _readln_end
    sb a0, 0(s1)
    add s1, s1, 1
    j _readln_loop
_readln_end:
    sb zero, 0(s1)
    ret
END_WORD(readln)

.text

.global boot
boot:
    la sp, __stack_top
    la t0, __bss
    la t1, __bss_end
_zero_loop:
    sb zero, 0(t0)
    addi t0, t0, 1
    blt t0, t1, _zero_loop
    la a0, greeting
    PUSH(a0)
    call puts

    la a0, prompt
    PUSH(a0)
    call puts
    la a0, tib
    PUSH(a0)
    call readln
_main_loop:
    j _main_loop
