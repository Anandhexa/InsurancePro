**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// ===========================
// Files
// ===========================
dcl-f LOGINSCR workstn;

// ===========================
// State
// ===========================
dcl-s LoginFlag char(1) inz('N');

// ===========================
// Main loop
// ===========================
dow '1' = '1';

   exfmt LOGINMAP;

   // Validate login
   if %trim(USERID) = 'RGARCIA'
      and %trim(PASSWORD) = 'BROKER01';

      LoginFlag = 'Y';
   else;
      LoginFlag = 'N';
   endif;

   if LoginFlag = 'Y';
      // Equivalent of EXEC CICS XCTL PROGRAM('BROKPIPE')
      *inlr = *on;
      call 'BROKPIPE';
      return;
   endif;

   // Otherwise redisplay screen (same as SEND MAP)
enddo;

*inlr = *on;
return;
