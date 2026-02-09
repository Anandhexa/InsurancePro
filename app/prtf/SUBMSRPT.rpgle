ctl-opt dftactgrp(*no) actgrp(*new);

dcl-f SUBMSRPTF printer(132) oflind(*inof);

dcl-s SubmissionId     char(15) inz('SUB300001');
dcl-s ClientId         char(15) inz('CLIENT001');
dcl-s ProcessingStatus char(15) inz('SUBMITTED');
dcl-s SubmissionRef    char(20) inz('SUB-REF-99887');

dcl-s ReportDate       char(8);
dcl-s ReportTime       char(6);

exsr Initialize;
exsr PrintHeader;
exsr PrintDetail;
exsr PrintFooter;

*inlr = *on;
return;

begsr Initialize;

   ReportDate = %char(%date():*iso0);
   ReportTime = %char(%time():*hms0);

endsr;

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

begsr PrintDetail;

   SUBMID   = SubmissionId;
   CLIENTID = ClientId;
   STATUS   = ProcessingStatus;
   SUBREF   = SubmissionRef;

   write SUBDTL;

endsr;

begsr PrintFooter;

   FOOTER1 = 'END OF SUBMISSION REPORT';

   write SUBFTR;

endsr;
