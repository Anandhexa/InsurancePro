
PGM

  /* Step 1: Delete and recreate BIND file                            */
  DLTF FILE(AXAINS/BIND)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/BIND) RCDLEN(237)
  SKIP1:

ENDPGM
