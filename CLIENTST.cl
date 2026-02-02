PGM

  /* Step 1: Delete and recreate CLIENT file                          */
  DLTF FILE(AXAINS/CLIENT)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/CLIENT) RCDLEN(138)
  SKIP1:

  /* Step 2: Copy client data from load file to target                */
  /* Source: CLNTIN - CLIENT01 ACME CORPORATION...                   */
  CPYF FROMFILE(AXAINS/CLNTIN) TOFILE(AXAINS/CLIENT) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
