ctl-opt dftactgrp(*no) actgrp(*new);

dcl-f WSPLATFORM workstn;

dcl-s PlatformRequestId    char(12);
dcl-s PlatformPayload      char(1000);
dcl-s PlatformResponse     char(1000);
dcl-s PlatformStatusCode   int(5);
dcl-s PlatformStatus       char(15);
dcl-s ReferenceNumber      char(20);
dcl-s RequestSequence      int(6) inz(500001);

exsr Initialize;
exsr BuildPlatformRequest;
exsr SendPlatformRequest;
exsr EvaluatePlatformResponse;
exsr DisplayPlatformResult;

*inlr = *on;
return;

begsr Initialize;

   PlatformStatus     = 'NEW';
   PlatformStatusCode = 0;
   PlatformPayload    = *blanks;
   PlatformResponse   = *blanks;
   ReferenceNumber    = *blanks;

endsr;

begsr BuildPlatformRequest;

   PlatformRequestId = 'PLT' + %char(RequestSequence);
   RequestSequence += 1;

   PlatformPayload =
      '{ "requestId": "' + PlatformRequestId +
      '", "action": "SUBMIT", "channel": "PLATFORM" }';

endsr;

begsr SendPlatformRequest;

   if %len(%trim(PlatformPayload)) > 0;

      PlatformStatusCode = 200;
      PlatformResponse =
         '{ "result": "ACCEPTED", "reference": "PLT-REF-78901" }';

   else;

      PlatformStatusCode = 400;
      PlatformResponse =
         '{ "result": "REJECTED", "reference": "" }';

   endif;

endsr;

begsr EvaluatePlatformResponse;

   if PlatformStatusCode = 200;

      PlatformStatus  = 'SUCCESS';
      ReferenceNumber = 'PLT-' + %char(%timestamp():7:6);

   else;

      PlatformStatus  = 'FAILED';
      ReferenceNumber = 'N/A';

   endif;

endsr;

begsr DisplayPlatformResult;

   dsply ('--------------------------------------');
   dsply ('PLATFORM REQUEST ID : ' + PlatformRequestId);
   dsply ('STATUS              : ' + PlatformStatus);
   dsply ('REFERENCE NUMBER    : ' + ReferenceNumber);
   dsply ('--------------------------------------');

endsr;
