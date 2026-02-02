PGM

  /* Step 1: Delete and recreate POLICY file                          */
  DLTF FILE(AXAINS/POLICY)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/POLICY) RCDLEN(350)
  SKIP1:

  /* Step 2: Delete and recreate POLICY AMENDMENT file                */
  DLTF FILE(AXAINS/POLICYAM)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP2))
  CRTPF FILE(AXAINS/POLICYAM) RCDLEN(200)
  SKIP2:

  /* Step 3: Copy policy data from load file to target                 */
  /* Source: POLICYIN - policy records                                 */
  CPYF FROMFILE(AXAINS/POLICYIN) TOFILE(AXAINS/POLICY) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
