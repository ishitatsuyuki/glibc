struct link_map_machine
  {
    ElfW(Addr) plt; /* Address of .plt.  */
    void *tlsdesc_table; /* Address of TLS descriptor hash table.  */
  };
