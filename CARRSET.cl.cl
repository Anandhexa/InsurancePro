PGM

  /* Step 1: Delete and recreate CARRIER file                         */
  DLTF FILE(AXAINS/CARRIER)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/CARRIER) RCDLEN(198)
  SKIP1:

  /* Step 2: Copy carrier data from load file to target               */
  /* Source: CARRIN - Lloyd's, Zurich, Allianz carrier records        */
  CPYF FROMFILE(AXAINS/CARRIN) TOFILE(AXAINS/CARRIER) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
