**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXASUBM  usage(*input)  keyed;
dcl-f AXAGTM   usage(*output) keyed;

/*----------------------------------------------------------------*/
/* Copy books                                                     */
/*----------------------------------------------------------------*/
 /copy GTMREQ
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
dcl-s wsSubmissionKey char(10);
dcl-s wsRFQId          char(10);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsSubmissionKey = %subst(pCommArea:1:10);

readSubmissionData();
generateRFQId();
sendMap();

return;

/*----------------------------------------------------------------*/
/* Read submission data                                           */
/*----------------------------------------------------------------*/
dcl-proc readSubmissionData;

   chain wsSubmissionKey AXASUBM;
   // Error handling would map to MONITOR or %ERROR

end-proc;

/*----------------------------------------------------------------*/
/* Generate RFQ ID                                                */
/*----------------------------------------------------------------*/
dcl-proc generateRFQId;

   // Equivalent of 'RFQ' + CURRENT-DATE(9:6)
   wsRFQId = 'RFQ' + %subst(%char(%timestamp()):9:6);

end-proc;

/*----------------------------------------------------------------*/
/* ENTER – Submit GTM request                                     */
/*----------------------------------------------------------------*/
dcl-proc submitGtmRequest;

   // EXFMT NEWGTMMP

   buildGtmRequest();
   saveGtmRequest();
   gotoGtmDetails();

end-proc;

/*----------------------------------------------------------------*/
/* Build GTM request record                                       */
/*----------------------------------------------------------------*/
dcl-proc buildGtmRequest;

   Gtm_Rfq_Id         = wsRFQId;
   Gtm_Submission_Id = Submission_Id;
   Gtm_Distribution  = DistTypeI;
   Gtm_Carrier_Name  = CarrNameI;
   Gtm_Carrier_Type  = 'CARRIER';
   Gtm_Status        = 'CREATED';
   Gtm_Created_Date  = %char(%date():*ISO0);

end-proc;

/*----------------------------------------------------------------*/
/* Save GTM request                                               */
/*----------------------------------------------------------------*/
dcl-proc saveGtmRequest;

   write AXAGTM;

end-proc;

/*----------------------------------------------------------------*/
/* Go to GTM details                                              */
/*----------------------------------------------------------------*/
dcl-proc gotoGtmDetails;

   %subst(pCommArea:1:10) = Submission_Id;
   callp GTMDETAIL(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* Send map                                                       */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   SubmIdO = Submission_Id;
   RfqIdO  = wsRFQId;

   // EXFMT NEWGTMMP

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Return to submission                                     */
/*----------------------------------------------------------------*/
dcl-proc returnSubmission;

   %subst(pCommArea:1:10) = Submission_Id;
   callp SUBMISSN(pCommArea);

end-proc;

