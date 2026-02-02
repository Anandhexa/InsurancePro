 PGM

  /* Step 1: Delete and recreate ANALYTICS file                       */
  DLTF FILE(AXAINS/ANALYTICS)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP1))
  CRTPF FILE(AXAINS/ANALYTICS) RCDLEN(300)
  SKIP1:

  /* Step 2: Delete and recreate METRICS file                         */
  DLTF FILE(AXAINS/METRICS)
  MONMSG MSGID(CPF2105) EXEC(GOTO CMDLBL(SKIP2))
  CRTPF FILE(AXAINS/METRICS) RCDLEN(150)
  SKIP2:

  /* Step 3: Call ANALYTICS program - Generate daily report           */
  CALL PGM(AXAINS/ANALYTICS)
  /* Parameters: GENERATE DAILY REPORT FOR 2024-01-15                 */
  /*            CALCULATE KPI METRICS                                 */
  /*            UPDATE PERFORMANCE DASHBOARD                           */

  /* Step 4: Copy analytics data from staging to target file          */
  /* Source: ANALYTICSIN staging file with report data                */
  CPYF FROMFILE(AXAINS/ANALYTICSIN) TOFILE(AXAINS/ANALYTICS) +
       MBROPT(*REPLACE) CRTFILE(*YES)

ENDPGM
