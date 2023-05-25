#ifndef RISCV_DL_TLSDESC_H
# define RISCV_DL_TLSDESC_H 1

struct tlsdesc {
  unsigned long (*resolver) (struct tlsdesc *);
  union {
    struct {
      unsigned long ti_module;
      unsigned long ti_offset;
      unsigned long gen_count;
    };
    unsigned long static_offset;
    unsigned long data[3];
  };
};

extern unsigned long attribute_hidden
  _dl_tlsdesc_return(struct tlsdesc *),
  _dl_tlsdesc_undefweak(struct tlsdesc *);

# ifdef SHARED
extern unsigned long attribute_hidden _dl_tlsdesc_dynamic(struct tlsdesc *);
# endif

#endif