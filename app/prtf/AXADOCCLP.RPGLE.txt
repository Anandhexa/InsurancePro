**FREE
ctl-opt dftactgrp(*no)
        actgrp(*new)
        option(*srcstmt);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXACLIENT   usage(*input) keyed;
dcl-f AXADOC      usage(*input) keyed;
dcl-f AXADOCCLP   printer;

/*----------------------------------------------------------------*/
/* Constants                                                      */
/*----------------------------------------------------------------*/
TITLE     = 'AXA DOCUMENT AND CLIENT DETAIL REPORT';
DOCHDRTXT = 'DOCUMENT DETAILS';
ENDMSG    = '*** END OF REPORT ***';

/*----------------------------------------------------------------*/
/* Main Logic                                                     */
/*----------------------------------------------------------------*/
read AXACLIENT;
dow not %eof(AXACLIENT);

   /* Client Labels */
   CLIDLBL   = 'Client ID:';
   CLNMLBL   = 'Client Name:';
   CADDLBL   = 'Address:';
   CCITYLBL  = 'City:';
   CCNTRYLBL = 'Country:';
   CPSTLBL   = 'Postal Code:';

   write RPTHEADER;
   write CLIENTREC;

   /* Read Documents for Client */
   setll CLIENTID AXADOC;
   reade CLIENTID AXADOC;

   if %found(AXADOC);
      write DOCHDR;

      dow %found(AXADOC);
         write DOCREC;
         reade CLIENTID AXADOC;
      enddo;
   endif;

   read AXACLIENT;
enddo;

write RPTFOOT;

*inlr = *on;
return;
