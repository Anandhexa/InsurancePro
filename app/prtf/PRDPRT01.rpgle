ctl-opt dftactgrp(*no) actgrp('INSURANCE');

dcl-f AXAPROD  usage(*input);
dcl-f PRDPRTF  printer;

dcl-s PrintDate   char(8);
dcl-s PrintTime   char(6);
dcl-s EndOfFile   ind inz(*off);

exsr Initialize;
exsr PrintHeader;
exsr ReadAndPrintProducts;
exsr PrintFooter;

*inlr = *on;
return;

begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

begsr PrintHeader;

   RPTDATE = PrintDate;
   RPTTIME = PrintTime;
   write RPTHEADER;
   write COLHEADER;

endsr;

begsr ReadAndPrintProducts;

   setll *loval AXAPROD;

   dow EndOfFile = *off;

      read AXAPROD;
      if %eof(AXAPROD);
         EndOfFile = *on;
      else;

         PRODID     = AXAPROD.PRODUCT_ID;
         PRODNAME   = AXAPROD.PRODUCT_NAME;
         PRODTYPE   = AXAPROD.PRODUCT_TYPE;
         PRODSTATUS = AXAPROD.PRODUCT_STATUS;

         write DETAIL;

      endif;

   enddo;

endsr;

begsr PrintFooter;

   write FOOTER;

endsr;
