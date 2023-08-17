ifeq ($(subdir),misc)
sysdep_headers += sys/asm.h
endif

ifeq ($(subdir),elf)
sysdep-dl-routines += \
  dl-tlsdesc \
  tlsdesc \
  # routines
endif

ifeq ($(subdir),csu)
gen-as-const-headers += \
  tlsdesc.sym \
  # gen-as-const-headers
endif

# RISC-V's assembler also needs to know about PIC as it changes the definition
# of some assembler macros.
ASFLAGS-.os += $(pic-ccflag)

ifeq (no,$(riscv-r-align))
ASFLAGS-.os += -Wa,-mno-relax
ASFLAGS-.o += -Wa,-mno-relax
sysdep-CFLAGS += -mno-relax
endif
