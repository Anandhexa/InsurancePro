**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPROD usage(*input) keyed;
dcl-f AXASUBM usage(*input) keyed;
dcl-f PRODDET workstn;

/*----------------------------------------------------------------*/
/* Copy books (COBOL COPY PRODUCT / SUBMISSN)                      */
/*----------------------------------------------------------------*/
 /copy PRODUCT
 /copy SUBMISSN

/*----------------------------------------------------------------*/
/* Entry parameter (DFHCOMMAREA)                                   */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsProductKey char(10);
dcl-s wsSubmCount  packed(3:0) inz(0);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsProductKey = %subst(pCommArea:1:10);

readProduct();
readSubmissions();
sendMap();

return;

/*----------------------------------------------------------------*/
/* Read product                                                   */
/*----------------------------------------------------------------*/
dcl-proc readProduct;

   chain wsProductKey AXAPROD;

   if not %found(AXAPROD);
      sendMap();
      return;
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Read submissions for product                                   */
/*----------------------------------------------------------------*/
dcl-proc readSubmissions;

   Product_ID = wsProductKey;

   chain Product_ID AXASUBM;

   if %found(AXASUBM);
      wsSubmCount += 1;
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* PF2 – Create new submission                                    */
/*----------------------------------------------------------------*/
dcl-proc newSubmission;

   pCommArea = wsProductKey + %subst(pCommArea:11);
   callp SUBMISSN(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* PF5 – Generate document                                        */
/*----------------------------------------------------------------*/
dcl-proc generateDocument;

   pCommArea = Submission_ID + %subst(pCommArea:11);
   callp DOCGEN(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* Send display                                                   */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   PRODNMO = Product_Name;

   /* Typically EXFMT PRODMAP2 would occur here */

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Exit                                                     */
/*----------------------------------------------------------------*/
dcl-proc exitProgram;
   return;
end-proc;

