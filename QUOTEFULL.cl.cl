PGM

  /* Copy quote data from load file to target                          */
  /* Source: QUOTEIN - full quote records with all fields              */
  /* Target: QUOTE file must already exist (run QUOTESET first)       */
  CPYF FROMFILE(AXAINS/QUOTEIN) TOFILE(AXAINS/QUOTE) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
