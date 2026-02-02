PGM

  /* Step 1: Delete and recreate GTM file                              */
  DLTF FILE(AXAINS/GTM)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/GTM) RCDLEN(107)
  SKIP1:

ENDPGM
