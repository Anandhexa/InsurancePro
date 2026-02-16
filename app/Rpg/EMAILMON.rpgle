**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// =======================
// Files
// =======================
dcl-f EMAILMON workstn;

// =======================
// Scalars
// =======================
dcl-s ExtractedCount packed(2:0) inz(0);

// =======================
// Email table (OCCURS 3)
// =======================
dcl-ds EmailEntry qualified dim(3);
   EmailFrom char(15);
   RfqId     char(10);
   Carrier   char(15);
   Status    char(15);
end-ds;

// =======================
// Main program
// =======================

// Load initial state
callp LoadEmailStatus();
callp SendMap();

// Main loop
dow *in03 = *off;

   exfmt EMAILMAP;

   if *in12;           // PF12 = Refresh
      callp SendMap();
      iter;
   endif;

   if *in02;           // PF2 = Extract emails
      callp ExtractEmails();
      iter;
   endif;

   if *in04;           // PF4 = Email processing
      call 'EMAILPROC';
      callp LoadEmailStatus();
      callp SendMap();
      iter;
   endif;

   if *in05;           // PF5 = Email analytics
      call 'EMAILANAL';
      callp SendMap();
      iter;
   endif;

   if *in03;           // PF3 = Back
      call 'QUOTEDASH';
      leave;
   endif;

enddo;

*inlr = *on;
return;

// =======================================
// Load initial / reset email status
// =======================================
dcl-proc LoadEmailStatus;

   EmailEntry(1).EmailFrom = 'uwb@axa.com';
   EmailEntry(1).RfqId     = 'RFQ001';
   EmailEntry(1).Carrier   = 'LLOYDS';
   EmailEntry(1).Status    = 'PENDING';

   EmailEntry(2).EmailFrom = 'quotes@zurich';
   EmailEntry(2).RfqId     = 'RFQ002';
   EmailEntry(2).Carrier   = 'ZURICH';
   EmailEntry(2).Status    = 'PENDING';

   EmailEntry(3).EmailFrom = 'uw@allianz';
   EmailEntry(3).RfqId     = 'RFQ003';
   EmailEntry(3).Carrier   = 'ALLIANZ';
   EmailEntry(3).Status    = 'PENDING';

   ExtractedCount = 0;

end-proc;

// =======================================
// Extract emails (PF2)
// =======================================
dcl-proc ExtractEmails;

   // Equivalent to EXEC CICS LINK EMAILEXT
   call 'EMAILEXT';

   for i = 1 to 3;
      EmailEntry(i).Status = 'EXTRACTED';
   endfor;

   ExtractedCount += 3;

   callp SendMap();

end-proc;

// =======================================
// Populate screen fields
// =======================================
dcl-proc SendMap;

   EMAILFROM1 = EmailEntry(1).EmailFrom;
   RFQID1     = EmailEntry(1).RfqId;
   CARRIER1   = EmailEntry(1).Carrier;
   STATUS1    = EmailEntry(1).Status;

   EMAILFROM2 = EmailEntry(2).EmailFrom;
   RFQID2     = EmailEntry(2).RfqId;
   CARRIER2   = EmailEntry(2).Carrier;
   STATUS2    = EmailEntry(2).Status;

   EMAILFROM3 = EmailEntry(3).EmailFrom;
   RFQID3     = EmailEntry(3).RfqId;
   CARRIER3   = EmailEntry(3).Carrier;
   STATUS3    = EmailEntry(3).Status;

   MONSTS =
      'EMAILS PROCESSED: ' +
      %char(ExtractedCount) +
      ' QUOTES EXTRACTED AND STORED';

end-proc;
