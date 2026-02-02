PGM

  /* Step 1: Delete and recreate QUOTE file                           */
  DLTF FILE(AXAINS/QUOTE)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/QUOTE) RCDLEN(117)
  SKIP1:

  /* Step 2: Copy quote data from load file to target                  */
  /* Source: QUOTEIN - QTE001, QTE002, QTE003 quote records            */
  CPYF FROMFILE(AXAINS/QUOTEIN) TOFILE(AXAINS/QUOTE) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
