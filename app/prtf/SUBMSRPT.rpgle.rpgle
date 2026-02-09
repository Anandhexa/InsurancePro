**--------------------------------------------------------------
** Program : SUBMSRPT
** Purpose : Submission Processing Printer Report
** Author  : SUBMISSN/APISUBM
** Style   : RPGLE Free Format
**--------------------------------------------------------------

ctl-opt dftactgrp(*no) actgrp(*new);

**--------------------------------------------------------------
** Printer File
**--------------------------------------------------------------
dcl-f SUBMSRPTF printer(132) oflind(*inof);

**--------------------------------------------------------------
** Working Variables
**--------------------------------------------------------------
dcl-s SubmissionId     char(15) inz('SUB300001');
dcl-s ClientId         char(15) inz('CLIENT001');
dcl-s ProcessingStatus char(15) inz('SUBMITTED');
dcl-s SubmissionRef    char(20) inz('SUB-REF-99887');

dcl-s ReportDate       char(8);
dcl-s ReportTime       char(6);

**--------------------------------------------------------------
** Main Logic
**--------------------------------------------------------------
exsr Initialize;
exsr PrintHeader;
exsr PrintDetail;
exsr PrintFooter;

*inlr = *on;
return;

**==============================================================
** Initialize
**==============================================================
begsr Initialize;

   ReportDate = %char(%date():*iso0);
   ReportTime = %char(%time():*hms0);

endsr;

**==============================================================
** Print Report Header
**==============================================================
begsr PrintHeader;

   COMPANY     = 'AXA INSURANCE';
   REPORTTITLE = 'SUBMISSION PROCESSING REPORT';
   RPTDATE     = ReportDate;
   RPTTIME     = ReportTime;

   write SUBHDR;

   HD1 = 'SUBMISSION ID';
   HD2 = 'CLIENT ID';
   HD3 = 'STATUS';
   HD4 = 'REFERENCE';

   write SUBCOL;

endsr;

**==============================================================
** Print Detail Line
**==============================================================
begsr PrintDetail;

   SUBMID   = SubmissionId;
   CLIENTID = ClientId;
   STATUS   = ProcessingStatus;
   SUBREF   = SubmissionRef;

   write SUBDTL;

endsr;

**==============================================================
** Print Footer
**==============================================================
begsr PrintFooter;

   FOOTER = '--- END OF SUBMISSION REPORT ---';

   write SUBFTR;

endsr;
