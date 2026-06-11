# Profile B: switch-controlled PWM duty cycle
# MMIO: switches=0x90, duty=0x98, enable=0x9c

        addi $t0, $zero, 0x9c
        addi $t1, $zero, 1
        sw   $t1, 0($t0)

        addi $t0, $zero, 0x90
        addi $t2, $zero, 0x98

loop:
        lw   $t1, 0($t0)
        sw   $t1, 0($t2)
        j    loop
        nop
