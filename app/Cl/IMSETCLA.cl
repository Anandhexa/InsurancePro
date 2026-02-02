PGM

  /* Step 1: Delete and recreate CLAIMS file                          */
  DLTF FILE(AXAINS/CLAIMS)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/CLAIMS) RCDLEN(450)
  SKIP1:

  /* Step 2: Delete and recreate CLAIMS INVESTIGATION file            */
  DLTF FILE(AXAINS/CLAIMINV)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP2))
  CRTPF FILE(AXAINS/CLAIMINV) RCDLEN(300)
  SKIP2:

  /* Step 3: Copy claims data from load file to target                */
  /* Source: CLAIMSIN - claim records                                 */
  CPYF FROMFILE(AXAINS/CLAIMSIN) TOFILE(AXAINS/CLAIMS) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
