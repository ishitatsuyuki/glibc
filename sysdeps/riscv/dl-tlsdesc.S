/* Thread-local storage handling in the ELF dynamic linker.
   RISC-V version.
   Copyright (C) 2023 Free Software Foundation, Inc.

   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */

#include <sysdep.h>
#include <tls.h>
#include <tlsdesc.h>

#define FRAME_SIZE_FAST (-((-3 * SZREG) & ALMASK))

#ifdef __riscv_float_abi_soft
# define FRAME_SIZE_SLOW (-((-12 * SZREG) & ALMASK))
#else
# define FRAME_SIZE_SLOW (-((-12 * SZREG - 20 * SZFREG) & ALMASK))
#endif

	.text

	/* Compute the thread pointer offset for symbols in the static
	   TLS block. The offset is the same for all threads.
	   Prototype:
	   _dl_tlsdesc_return (tlsdesc *) ;
	 */
ENTRY (_dl_tlsdesc_return)
	REG_L a0, TLSDESC_ARG(a0)
	jr t0
END (_dl_tlsdesc_return)

	/* Handler for undefined weak TLS symbols.
	   Prototype:
	   _dl_tlsdesc_undefweak (tlsdesc *);

	   The second word of the descriptor contains the addend.
	   Return the addend minus the thread pointer. This ensures
	   that when the caller adds on the thread pointer it gets back
	   the addend.  */

ENTRY (_dl_tlsdesc_undefweak)
	REG_L a0, TLSDESC_ARG(a0)
	sub a0, a0, tp
	jr t0
END (_dl_tlsdesc_undefweak)

#ifdef SHARED
	/* Handler for dynamic TLS symbols.
	   Prototype:
	   _dl_tlsdesc_dynamic (tlsdesc *) ;

	   The second word of the descriptor points to a
	   tlsdesc_dynamic_arg structure.

	   Returns the offset between the thread pointer and the
	   object referenced by the argument.

	   unsigned long
	   _dl_tlsdesc_dynamic (struct tlsdesc *tdp)
	   {
	     struct tlsdesc_dynamic_arg *td = tdp->arg;
	     dtv_t *dtv = *(dtv_t **)((char *)__thread_pointer + TCBHEAD_DTV);
	     if (__builtin_expect (td->gen_count <= dtv[0].counter
		&& (dtv[td->tlsinfo.ti_module].pointer.val
		    != TLS_DTV_UNALLOCATED),
		1))
	       return dtv[td->tlsinfo.ti_module].pointer.val
		+ td->tlsinfo.ti_offset
		- __thread_pointer;

	     return ___tls_get_addr (&td->tlsinfo) - __thread_pointer;
	   }
	 */

ENTRY (_dl_tlsdesc_dynamic)
	/* Save just enough registers to support fast path, if we fall
	   into slow path we will save additional registers.  */
	add	sp, sp, -FRAME_SIZE_FAST
	REG_S	t0, 0*SZREG(sp)
	REG_S	t1, 1*SZREG(sp)
	REG_S	t2, 2*SZREG(sp)

	/* t0 = dtv */
	REG_L	t0, TCBHEAD_DTV(tp)
	/* a0 = tdp->arg */
	REG_L	a0, TLSDESC_ARG(a0)
	/* t1 = td->gen_count */
	REG_L	t1, TLSDESC_GEN_COUNT(a0)
	/* t2 = dtv[0].counter */
	REG_L	t2, DTV_COUNTER(t0)
	bltu	t2, t1, .Lslow
	/* t1 = td->tlsinfo.ti_module */
	REG_L	t1, TLSDESC_MODID(a0)
	slli	t1, t1, PTRLOG + 1 /* sizeof(dtv_t) == sizeof(void*) * 2 */
	add	t1, t1, t0
	/* t1 = dtv[td->tlsinfo.ti_module].pointer.val  */
	REG_L	t1, 0(t1)
	li	t2, TLS_DTV_UNALLOCATED
	beq	t1, t2, .Lslow
	/* t2 = td->tlsinfo.ti_offset */
	REG_L	t2, TLSDESC_MODOFF(a0)
	add	a0, t1, t2
.Lret:
	sub	a0, a0, tp
	REG_L	t0, 0*SZREG(sp)
	REG_L	t1, 1*SZREG(sp)
	REG_L	t2, 2*SZREG(sp)
	add	sp, sp, FRAME_SIZE_FAST
	jr t0
.Lslow:
	/* This is the slow path. We need to call __tls_get_addr() which
	   means we need to save and restore all the register that the
	   callee will trash.  */

	/* Save the remaining registers that we must treat as caller save.  */
	addi	sp, sp, -FRAME_SIZE_SLOW
	REG_S	ra, 0*SZREG(sp)
	REG_S	a1, 1*SZREG(sp)
	REG_S	a2, 2*SZREG(sp)
	REG_S	a3, 3*SZREG(sp)
	REG_S	a4, 4*SZREG(sp)
	REG_S	a5, 5*SZREG(sp)
	REG_S	a6, 6*SZREG(sp)
	REG_S	a7, 7*SZREG(sp)
	REG_S	t3, 8*SZREG(sp)
	REG_S	t4, 9*SZREG(sp)
	REG_S	t5, 10*SZREG(sp)
	REG_S	t6, 11*SZREG(sp)
#ifndef __riscv_float_abi_soft
	FREG_S	ft0, (12*SZREG + 0*SZFREG)(sp)
	FREG_S	ft1, (12*SZREG + 1*SZFREG)(sp)
	FREG_S	ft2, (12*SZREG + 2*SZFREG)(sp)
	FREG_S	ft3, (12*SZREG + 3*SZFREG)(sp)
	FREG_S	ft4, (12*SZREG + 4*SZFREG)(sp)
	FREG_S	ft5, (12*SZREG + 5*SZFREG)(sp)
	FREG_S	ft6, (12*SZREG + 6*SZFREG)(sp)
	FREG_S	ft7, (12*SZREG + 7*SZFREG)(sp)
	FREG_S	fa0, (12*SZREG + 8*SZFREG)(sp)
	FREG_S	fa1, (12*SZREG + 9*SZFREG)(sp)
	FREG_S	fa2, (12*SZREG + 10*SZFREG)(sp)
	FREG_S	fa3, (12*SZREG + 11*SZFREG)(sp)
	FREG_S	fa4, (12*SZREG + 12*SZFREG)(sp)
	FREG_S	fa5, (12*SZREG + 13*SZFREG)(sp)
	FREG_S	fa6, (12*SZREG + 14*SZFREG)(sp)
	FREG_S	fa7, (12*SZREG + 15*SZFREG)(sp)
	FREG_S	ft8, (12*SZREG + 16*SZFREG)(sp)
	FREG_S	ft9, (12*SZREG + 17*SZFREG)(sp)
	FREG_S	ft10, (12*SZREG + 18*SZFREG)(sp)
	FREG_S	ft11, (12*SZREG + 19*SZFREG)(sp)
#endif

	call	__tls_get_addr
	addi	a0, a0, -TLS_DTV_OFFSET

	REG_L	ra, 0*SZREG(sp)
	REG_L	a1, 1*SZREG(sp)
	REG_L	a2, 2*SZREG(sp)
	REG_L	a3, 3*SZREG(sp)
	REG_L	a4, 4*SZREG(sp)
	REG_L	a5, 5*SZREG(sp)
	REG_L	a6, 6*SZREG(sp)
	REG_L	a7, 7*SZREG(sp)
	REG_L	t3, 8*SZREG(sp)
	REG_L	t4, 9*SZREG(sp)
	REG_L	t5, 10*SZREG(sp)
	REG_L	t6, 11*SZREG(sp)
#ifndef __riscv_float_abi_soft
	FREG_L	ft0, (12*SZREG + 0*SZFREG)(sp)
	FREG_L	ft1, (12*SZREG + 1*SZFREG)(sp)
	FREG_L	ft2, (12*SZREG + 2*SZFREG)(sp)
	FREG_L	ft3, (12*SZREG + 3*SZFREG)(sp)
	FREG_L	ft4, (12*SZREG + 4*SZFREG)(sp)
	FREG_L	ft5, (12*SZREG + 5*SZFREG)(sp)
	FREG_L	ft6, (12*SZREG + 6*SZFREG)(sp)
	FREG_L	ft7, (12*SZREG + 7*SZFREG)(sp)
	FREG_L	fa0, (12*SZREG + 8*SZFREG)(sp)
	FREG_L	fa1, (12*SZREG + 9*SZFREG)(sp)
	FREG_L	fa2, (12*SZREG + 10*SZFREG)(sp)
	FREG_L	fa3, (12*SZREG + 11*SZFREG)(sp)
	FREG_L	fa4, (12*SZREG + 12*SZFREG)(sp)
	FREG_L	fa5, (12*SZREG + 13*SZFREG)(sp)
	FREG_L	fa6, (12*SZREG + 14*SZFREG)(sp)
	FREG_L	fa7, (12*SZREG + 15*SZFREG)(sp)
	FREG_L	ft8, (12*SZREG + 16*SZFREG)(sp)
	FREG_L	ft9, (12*SZREG + 17*SZFREG)(sp)
	FREG_L	ft10, (12*SZREG + 18*SZFREG)(sp)
	FREG_L	ft11, (12*SZREG + 19*SZFREG)(sp)
#endif
	addi	sp, sp, FRAME_SIZE_SLOW
	j	.Lret
END (_dl_tlsdesc_dynamic)
#endif
