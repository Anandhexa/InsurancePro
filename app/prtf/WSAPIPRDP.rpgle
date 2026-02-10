ctl-opt dftactgrp(*no) actgrp('INSURANCE');

dcl-f AXAPROD    usage(*input);
dcl-f WSAPICFG   usage(*input);
dcl-f WSAPIPRTF  printer;

dcl-s PrintDate      char(8);
dcl-s PrintTime      char(6);
dcl-s EndProd        ind inz(*off);

dcl-s ApiEnabled     char(3);
dcl-s ApiStatus      char(12);
dcl-s ApiLastUpdate  char(8);

exsr Initialize;
exsr PrintHeader;
exsr ProcessProducts;
exsr PrintFooter;

*inlr = *on;
return;

begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

begsr PrintHeader;

   PRNDATE = PrintDate;
   PRNTIME = PrintTime;

   write HEADER;
   write COLHDR;

endsr;

begsr ProcessProducts;

   setll *loval AXAPROD;

   dow EndProd = *off;

      read AXAPROD;
      if %eof(AXAPROD);
         EndProd = *on;
      else;

         exsr ReadApiConfig;

         if ApiEnabled = 'YES';

            PRODID   = AXAPROD.PRODUCT_ID;
            PRODNAME = AXAPROD.PRODUCT_NAME;
            APIENB   = ApiEnabled;
            APISTS   = ApiStatus;
            LASTUPD  = ApiLastUpdate;

            write DETAIL;

         endif;

      endif;

   enddo;

endsr;

begsr ReadApiConfig;

   clear ApiEnabled;
   clear ApiStatus;
   clear ApiLastUpdate;

   chain AXAPROD.PRODUCT_ID WSAPICFG;
   if %found(WSAPICFG);

      ApiEnabled    = 'YES';
      ApiStatus     = WSAPICFG.API_STATUS;
      ApiLastUpdate = WSAPICFG.LAST_UPDATE_DATE;

   else;

      ApiEnabled = 'NO';

   endif;

endsr;

begsr PrintFooter;

   write FOOTER;

endsr;
