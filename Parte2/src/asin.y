/*****************************************************************************/
/**  Ejemplo de BISON-I: S E M - 2          2019-2020 <jbenedi@dsic.upv.es> **/
/**  V. 19                                                                  **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"
%}

%union {
  int   cent;
  char* id;
}

%token STRUCT_     READ_       PRINT_      IF_      ELSE_   WHILE_  TRUE_   FALSE_
%token AND_        OR_       IGUAL_     DIST_       MAIGUAL_    MEIGUAL_ NOT_
%token INC_        DEC_      MASIG_     MENIG_      DIVIG_      PORIG_
%token MAY_        MEN_      ASIG_      MAS_        MENOS_      POR_    DIV_    MOD_    PARA_ 
%token PARC_       CORA_     CORC_      LLAVEA_     LLAVEC_
%token PUNTOCOMA_  PUNTO_ 
%token <cent> CTE_ INT_      BOOL_
%token <id>   ID_

%%

prog   : LLAVEA_ sse LLAVEC_
       ;
sse    : se
       | sse se
       ;
se     : dec
       | ins
       ;
dec    : tSim    ID_      PUNTOCOMA_
       | tSim    ID_      ASIG_  con      PUNTOCOMA_ {
           int numelem = $4;
           if($4 <= 0) {
               yyerror("Talla inapropiada del array");
               numelem = 0;
            }
            int refe = insTdA($1, numelem);
            if (!instdS($2, T_ARRAY, dvar, refe))
                yyerror("identificador repetido");
            else dvar += numelem * TALLA_TIPO_SIMPLE;
       }
       | tSim    ID_      CORA_ CTE_     CORC_ PUNTOCOMA_
       | STRUCT_ LLAVEA_ lCamp  LLAVEC_ ID_    PUNTOCOMA_
       ;
tSim   : INT_
       | BOOL_
       ;
lCamp  : tSim  ID_  PUNTOCOMA_
       | lCamp tSim ID_ PUNTOCOMA_
       ;
ins    : LLAVEA_ LLAVEC_
       | LLAVEA_ lIns LLAVEC_
       |insES
       |insSel
       |insIt
       |insExp
       ;
lIns   : ins
       | lIns ins
       ;
insES  : READ_  PARA_ ID_ PARC_ PUNTOCOMA_
       | PRINT_ PARA_ exp PARC_ PUNTOCOMA_
       ;
insSel : IF_ PARA_ exp PARC_ ins ELSE_ ins
       ;
insIt  : WHILE_ PARA_ exp PARC_ ins
       ;
insExp : exp PUNTOCOMA_
       | PUNTOCOMA_
       ;
exp    : expLog
       | ID_ opAsig  exp
       | ID_ CORA_  exp CORC_ opAsig exp
       | ID_ PUNTO_ ID_ opAsig exp
       ;
expLog : expIg
       | expLog opLog expIg
       ;
expIg  : expRel
       | expIg opIg expRel
       ;
expRel : expAd
       | expRel opRel expAd
       ;
expAd  : expMul
       | expAd opAd expMul
       ;
expMul : expUn
       | expMul opMul expUn
       ;
expUn  : expSuf
       | opUn  expUn
       | opIn  ID_
       ;
expSuf : PARA_ exp     PARC_
       | ID_    opIn
       | ID_    CORA_  exp CORC_
       | ID_
       | ID_    PUNTO_ ID_
       | con
       ;
con    : CTE_
       | TRUE_
       | FALSE_
       ;
opAsig : ASIG_
       | MASIG_
       | MENIG_
       | PORIG_
       | DIVIG_
       ;
opLog  : AND_
       | OR_
       ;
opIg   : IGUAL_
       | DIST_
       ;
opRel  : MAY_
       | MEN_
       | MAIGUAL_
       | MEIGUAL_
       ;
opAd   : MAS_
       | MENOS_
       ;
opMul  : POR_
       | DIV_
       | MOD_
       ;
opUn   : MAS_
       | MENOS_
       | NOT_
       ;
opIn   : INC_
       | DEC_
       ;
%%


/*****************************************************************************/

/*****************************************************************************/

/*****************************************************************************/
