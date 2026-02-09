**--------------------------------------------------------------
** Program : WSAPIPRDP
** Purpose : WSAPI Product List Printer
** Style   : RPGLE Free Format
**--------------------------------------------------------------

ctl-opt dftactgrp(*no) actgrp('INSURANCE');

**--------------------------------------------------------------
** Files
**--------------------------------------------------------------
dcl-f PRODUCT    usage(*input);
dcl-f WSAPICFG   usage(*input);
dcl-f WSAPIPRTF  printer;

**--------------------------------------------------------------
** Working Variables
**--------------------------------------------------------------
dcl-s PrintDate      char(8);
dcl-s PrintTime      char(6);
dcl-s EndProd        ind inz(*off);

dcl-s ApiEnabled     char(3);
dcl-s ApiStatus      char(12);
dcl-s ApiLastUpdate  char(8);

**--------------------------------------------------------------
** Main Flow
**--------------------------------------------------------------
exsr Initialize;
exsr PrintHeader;
exsr ProcessProducts;
exsr PrintFooter;

*inlr = *on;
return;

**==============================================================
** Initialize
**==============================================================
begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

**==============================================================
** Print Header
**==============================================================
begsr PrintHeader;

   PRNDATE = PrintDate;
   PRNTIME = PrintTime;

   write HEADER;
   write COLHDR;

endsr;

**==============================================================
** Process Products
**==============================================================
begsr ProcessProducts;

   setll *loval PRODUCT;

   dow EndProd = *off;

      read PRODUCT;
      if %eof(PRODUCT);
         EndProd = *on;
      else;

         exsr ReadApiConfig;

         if ApiEnabled = 'YES';

            PRODID   = PRODUCT.PRODUCT_ID;
            PRODNAME = PRODUCT.PRODUCT_NAME;
            APIENB   = ApiEnabled;
            APISTS   = ApiStatus;
            LASTUPD  = ApiLastUpdate;

            write DETAIL;

         endif;

      endif;

   enddo;

endsr;

**==============================================================
** Read WSAPI Configuration
**==============================================================
begsr ReadApiConfig;

   clear ApiEnabled;
   clear ApiStatus;
   clear ApiLastUpdate;

   chain PRODUCT.PRODUCT_ID WSAPICFG;
   if %found(WSAPICFG);

      ApiEnabled    = 'YES';
      ApiStatus     = WSAPICFG.API_STATUS;
      ApiLastUpdate = WSAPICFG.LAST_UPDATE_DATE;

   else;

      ApiEnabled = 'NO';

   endif;

endsr;

**==============================================================
** Print Footer
**==============================================================
begsr PrintFooter;

   write FOOTER;

endsr;
