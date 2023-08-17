/* Thread-local storage descriptor handling in the ELF dynamic linker.
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
   License along with the GNU C Library.  If not, see
   <https://www.gnu.org/licenses/>.  */

#ifndef _DL_TLSDESC_H
# define _DL_TLSDESC_H 1

#include <dl-tls.h>

/* Type used to represent a TLS descriptor in the GOT.  */
struct tlsdesc
{
  unsigned long (*entry) (struct tlsdesc *);
  void *arg;
};

/* Type used as the argument in a TLS descriptor for a symbol that
   needs dynamic TLS offsets.  */
struct tlsdesc_dynamic_arg
{
  tls_index tlsinfo;
  size_t gen_count;
};

extern unsigned long _dl_tlsdesc_return (struct tlsdesc *) attribute_hidden;
extern unsigned long _dl_tlsdesc_undefweak (struct tlsdesc *) attribute_hidden;

# ifdef SHARED
extern void *_dl_make_tlsdesc_dynamic (struct link_map *, size_t);
extern unsigned long _dl_tlsdesc_dynamic (struct tlsdesc *) attribute_hidden;
# endif

#endif /* _DL_TLSDESC_H */
