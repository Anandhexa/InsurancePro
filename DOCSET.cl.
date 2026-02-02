PGM

  /* Step 1: Delete and recreate DOCUMENT file                         */
  DLTF FILE(AXAINS/DOCUMENT)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/DOCUMENT) RCDLEN(283)
  SKIP1:

  /* Step 2: Copy document data from load file to target              */
  /* Source: DOCIN - Policy, Quote, Binder document records            */
  CPYF FROMFILE(AXAINS/DOCIN) TOFILE(AXAINS/DOCUMENT) +
       MBROPT(*REPLACE) CRTFILE(*NO)

ENDPGM
