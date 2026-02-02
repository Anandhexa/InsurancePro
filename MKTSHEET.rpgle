**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXARFQ   usage(*input)  keyed;
dcl-f AXASUBM  usage(*input)  keyed;
dcl-f MKTMAP  workstn;

/*----------------------------------------------------------------*/
/* Copy books (externally described data structures)              */
/*----------------------------------------------------------------*/
 /copy RFQCARR
 /copy SUBMISSN

/*----------------------------------------------------------------*/
/* Program parameter (DFHCOMMAREA equivalent)                      */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsRfqKey       char(10);
dcl-s wsCurrentDate char(8);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsRfqKey = %subst(pCommArea:1:10);

readRfqData();
sendMap();

return;

/*----------------------------------------------------------------*/
/* Read RFQ and Submission data                                   */
/*----------------------------------------------------------------*/
dcl-proc readRfqData;

   chain wsRfqKey AXARFQ;
   // If not found, SEND-MAP equivalent logic would occur

   chain Submission_Id AXASUBM;

end-proc;

/*----------------------------------------------------------------*/
/* Send map                                                       */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   wsCurrentDate = %char(%date():*ISO0);

   RfqIdO     = Rfq_Id;
   SubmIdO    = Submission_Id;
   RfqStsO    = Rfq_Status;
   DistMethO = Distribution_Method;
   SentDtO   = wsCurrentDate;
   SentDt2O  = wsCurrentDate;

   exfmt MKTMAP;

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Return to submission                                     */
/*----------------------------------------------------------------*/
dcl-proc returnSubmission;

   %subst(pCommArea:1:10) = Submission_Id;
   callp SUBMISSN(pCommArea);

end-proc;
