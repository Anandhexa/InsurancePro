**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// =================================
// Files
// =================================
dcl-f NEWGTM    workstn;
dcl-f AXASUBM  usage(*input) keyed;
dcl-f AXAGTM   usage(*update) keyed;

// =================================
// Scalars
// =================================
dcl-s SubmissionKey char(10);
dcl-s RfqId         char(10);

// =================================
// GTM Request (COPY GTMREQ)
// =================================
dcl-ds GtmReq qualified;
   GtmRfqId        char(10);
   GtmSubmissionId char(10);
   GtmDistribution char(15);
   GtmCarrierName  char(30);
   GtmCarrierType  char(20);
   GtmStatus       char(15);
   GtmCreatedDate  char(8);
end-ds;

// =================================
// Parameter (COMMAREA replacement)
// =================================
dcl-pi *n;
   pSubmissionKey char(10);
end-pi;

SubmissionKey = pSubmissionKey;

// =================================
// Read submission
// =================================
chain SubmissionKey AXASUBM;
if not %found;
   *inlr = *on;
   return;
endif;

// =================================
// Generate RFQ ID
// =================================
RfqId = 'RFQ' + %subst(%char(%timestamp():*ISO0):9:6);

// =================================
// Initial screen values
// =================================
SUBMID   = SUBMISSION_ID;
RFQID    = RfqId;
CARRTYPE = 'CARRIER';

// =================================
// Main loop
// =================================
dow *in03 = *off;

   exfmt NEWGTMMP;

   if *in12;                    // PF12 = Clear
      DISTTYPE = *blanks;
      CARRNAME = *blanks;
      iter;
   endif;

   if *in03;                    // PF3 = Cancel
      call 'SUBMISSN' (SubmissionKey);
      leave;
   endif;

   if *in01;                    // ENTER = Submit
      callp SubmitGtmRequest();
      leave;
   endif;

enddo;

*inlr = *on;
return;

// =======================================
// Submit GTM Request
// =======================================
dcl-proc SubmitGtmRequest;

   // Build GTM record
   GtmReq.GtmRfqId        = RfqId;
   GtmReq.GtmSubmissionId = SUBMISSION_ID;
   GtmReq.GtmDistribution = DISTTYPE;
   GtmReq.GtmCarrierName  = CARRNAME;
   GtmReq.GtmCarrierType  = 'CARRIER';
   GtmReq.GtmStatus       = 'CREATED';
   GtmReq.GtmCreatedDate  = %char(%date():*ISO0);

   // Persist request
   write AXAGTM GtmReq;

   // Go to GTM details
   call 'GTMDETAIL' (SubmissionKey);


end-proc;
