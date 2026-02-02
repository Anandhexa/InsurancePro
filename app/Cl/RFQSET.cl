PGM

  /* Step 1: Delete and recreate RFQ file                             */
  DLTF FILE(AXAINS/RFQ)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/RFQ) RCDLEN(58)
  SKIP1:

ENDPGM
