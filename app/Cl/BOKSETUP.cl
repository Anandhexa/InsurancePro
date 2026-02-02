PGM

  /* Step 1: Delete and recreate BROKER file                          */
  DLTF FILE(AXAINS/BROKER)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/BROKER) RCDLEN(69)
  SKIP1:

  /* Step 2: Copy broker data from load file to target                */
  /* Source: BROKIN load file - RGARCIA RGARCIA BROKER01...           */
  CPYF FROMFILE(AXAINS/BROKIN) TOFILE(AXAINS/BROKER) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
