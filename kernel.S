#define POP(reg) c.lwsp reg, 0(sp); addi sp, sp, 4
#define PEEK(reg) 
#define PUSH(reg) addi sp, sp, -4; c.swsp reg, 0(sp)
#define PUSHI(lit) li t0, lit; PUSH(t0)
#define PUSHA(addr) la t0, addr; PUSH(t0)

#define CONCAT2(lhs, rhs) lhs ## rhs
#define CONCAT(lhs, rhs) CONCAT2(lhs, rhs)
#define TRACE li x31, 0xdead0000 + CONCAT(0x, __LINE__)

#define LOOP CONCAT(_loop_, __LINE__): j CONCAT(_loop_, __LINE__)

.bss
tib: .skip 512

.data
greeting: .string "Hello, world!\n"
prompt: .string "> "
tibdump: .string "TIB: "
newline: .string "\n"

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
    /*
     * REGISTER MAP:
     * s11: pointer to buffer start
     * s1: pointer to insertion point
     * s2: constant \r
     * s3: constant DEL
     * s4: constant SPC
     */
    POP(s1)
    mv s11, s1
    li a6, 0
    li s2, '\r'
    li s3, 0x7f // DEL
_readln_loop:
    li a7, 2; ecall
    bltz a0, _readln_loop
    beq a0, s2, _readln_end

    sb a0, 0(s1)
    bne a0, s3, _readln_not_backspace
    // BACKSPACE FOUND; reprint TIB
    sb zero, -1(s1)
    add s1, s1, -2
    li a7, 1; li a0, '\r'; ecall
    PUSHA(prompt); call puts
    PUSH(s11); call puts

_readln_not_backspace:
    li a7, 1; ecall
    add s1, s1, 1
    j _readln_loop
_readln_end:
    li a7, 1
    li a0, '\r'; ecall
    li a0, '\n'; ecall
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
    PUSHA(greeting)
    call puts

_main_loop:
    PUSHA(prompt)
    call puts
    PUSHA(tib)
    call readln

    PUSHA(tibdump)
    call puts
    PUSHA(tib)
    call puts
    PUSHA(newline)
    call puts
    LOOP
    j _main_loop
