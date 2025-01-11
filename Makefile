CC = clang
CFLAGS = --target=riscv32 -ffreestanding -nostdlib -Wl,-Tkernel.ld -Wl,-Map=kernel.map

QEMU = qemu-system-riscv32
QEMUFLAGS = -machine virt -bios default -nographic -serial mon:stdio --no-reboot

run: kernel.elf

kernel.elf: kernel.S
	${CC} kernel.S -g ${CFLAGS} -o kernel.elf

kernel_.S: kernel.elf
	llvm-objdump -D kernel.elf > kernel_.S

clean:
	rm -f kernel.elf

run: kernel.elf kernel_.S
	${QEMU} ${QEMUFLAGS} -kernel kernel.elf

debug: kernel.elf kernel_.S
	${QEMU} ${QEMUFLAGS} -s -S -kernel kernel.elf

.PHONY: run
