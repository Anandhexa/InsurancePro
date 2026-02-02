**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXASUBM  usage(*input)  keyed;
dcl-f AXAGTM   usage(*input)  keyed;
dcl-f GTMMAP   workstn;

/*----------------------------------------------------------------*/
/* Copy books (externally described data structures)              */
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
dcl-s wsGtmCount       int(5) inz(0);

/* GTM table (max 3 rows) */
dcl-ds wsGtmTable dim(3);
   wsRfqId     char(10);
   wsDistType  char(15);
   wsOrgName   char(20);
   wsStatus    char(10);
end-ds;

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsSubmissionKey = %subst(pCommArea:1:10);

readSubmission();
readGtmRequests();
sendMap();

return;

/*----------------------------------------------------------------*/
/* Read submission data                                           */
/*----------------------------------------------------------------*/
dcl-proc readSubmission;

   chain wsSubmissionKey AXASUBM;
   // NOTFND -> SEND-MAP equivalent behavior

end-proc;

/*----------------------------------------------------------------*/
/* Read GTM requests (STARTBR / READNEXT equivalent)              */
/*----------------------------------------------------------------*/
dcl-proc readGtmRequests;

   wsGtmCount = 0;

   /* Position to first GTM record for this submission */
   GTM_Submission_Id = Submission_Id;
   setll GTM_Submission_Id AXAGTM;

   read AXAGTM;
   dow not %eof(AXAGTM) and wsGtmCount < 3;

      if GTM_Submission_Id <> Submission_Id;
         leave;
      endif;

      wsGtmCount += 1;
      wsGtmTable(wsGtmCount).wsRfqId    = GTM_Rfq_Id;
      wsGtmTable(wsGtmCount).wsDistType = GTM_Distribution;
      wsGtmTable(wsGtmCount).wsOrgName  = GTM_Carrier_Name;
      wsGtmTable(wsGtmCount).wsStatus   = GTM_Status;

      read AXAGTM;
   enddo;

end-proc;

/*----------------------------------------------------------------*/
/* PF2 – New GTM request                                          */
/*----------------------------------------------------------------*/
dcl-proc newGtmRequest;

   %subst(pCommArea:1:10) = Submission_Id;
   callp NEWGTM(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* Send map                                                       */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   SubmIdO = Submission_Id;

   if wsGtmCount >= 1;
      RfqId1O     = wsGtmTable(1).wsRfqId;
      SubmId1O    = Submission_Id;
      DistType1O = wsGtmTable(1).wsDistType;
      OrgName1O  = wsGtmTable(1).wsOrgName;
      Status1O   = wsGtmTable(1).wsStatus;
   endif;

   if wsGtmCount >= 2;
      RfqId2O     = wsGtmTable(2).wsRfqId;
      SubmId2O    = Submission_Id;
      DistType2O = wsGtmTable(2).wsDistType;
      OrgName2O  = wsGtmTable(2).wsOrgName;
      Status2O   = wsGtmTable(2).wsStatus;
   endif;

   if wsGtmCount >= 3;
      RfqId3O     = wsGtmTable(3).wsRfqId;
      SubmId3O    = Submission_Id;
      DistType3O = wsGtmTable(3).wsDistType;
      OrgName3O  = wsGtmTable(3).wsOrgName;
      Status3O   = wsGtmTable(3).wsStatus;
   endif;

   GtmCountO = 'TOTAL GTM REQUESTS: ' + %char(wsGtmCount);

   exfmt GTMMAP;

end-proc;

/*----------------------------------------------------------------*/
/* ENTER – View GTM request                                       */
/*----------------------------------------------------------------*/
dcl-proc viewGtmRequest;

   if RfqId1I <> *blanks;
      %subst(pCommArea:1:10) = RfqId1I;
   elseif RfqId2I <> *blanks;
      %subst(pCommArea:1:10) = RfqId2I;
   elseif RfqId3I <> *blanks;
      %subst(pCommArea:1:10) = RfqId3I;
   endif;

   callp VIEWGTM(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Return to submission                                     */
/*----------------------------------------------------------------*/
dcl-proc returnSubmission;

   %subst(pCommArea:1:10) = Submission_Id;
   callp SUBMISSN(pCommArea);

end-proc;
