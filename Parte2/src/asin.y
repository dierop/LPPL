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
  EXP exp;
}

%token STRUCT_     READ_     PRINT_     IF_      ELSE_    WHILE_   TRUE_ FALSE_
%token AND_        OR_       IGUAL_     DIST_    MAIGUAL_ MEIGUAL_ NOT_
%token INC_        DEC_      MASIG_     MENIG_   DIVIG_   PORIG_
%token MAY_        MEN_      ASIG_      MAS_     MENOS_   POR_     DIV_  MOD_ PARA_ 
%token PARC_       CORA_     CORC_      LLAVEA_  LLAVEC_
%token PUNTOCOMA_  PUNTO_ 

%token <cent> CTE_ INT_  BOOL_
%token <id>   ID_

%type <cent> tSim
%type <exp> con lCamp
%%

prog   : LLAVEA_ sse LLAVEC_
       ;
sse    : se
       | sse se
       ;
se     : dec
       | ins
       ;
dec    : tSim    ID_      PUNTOCOMA_ {
          if(!insTdS($2,$1,dvar,-1))
            yyerror(E_VAR_DEC);
          else  dvar+=TALLA_TIPO_SIMPLE;
          }
       | tSim    ID_      ASIG_  con  PUNTOCOMA_ {
           if($1 != $4.tipo) 
               yyerror(E_TIPOS);
           else{
            if (!insTdS($2, $1, dvar, -1))
                yyerror(E_VAR_DEC);
            else dvar += TALLA_TIPO_SIMPLE;
           }}
       | tSim    ID_      CORA_ CTE_     CORC_ PUNTOCOMA_{
           int numelem = $4;
           if($4 <= 0) {
               yyerror(E_TALLA_ARRAY);
               numelem = 0;
            }
            int refe = insTdA($1, numelem);
            if (!instdS($2, T_ARRAY, dvar, refe))
                yyerror(E_VAR_DEC);
            else dvar += numelem * TALLA_TIPO_SIMPLE;
       }
       | STRUCT_ LLAVEA_ lCamp  LLAVEC_ ID_  PUNTOCOMA_{
           if(!insTdS($5, T_RECORD,dvar,$3.tipo))
            yyerror(E_VAR_DEC);
          else  dvar+=$3.valor ;
       }
       ;
tSim   : INT_   {$$=T_ENTERO;}
       | BOOL_  {$$=T_LOGICO;}
       ;
lCamp  : tSim  ID_  PUNTOCOMA_ {
          int ref = insTdR(-1,$2,$1,0);
          $$.valor = TALLA_TIPO_SIMPLE;
          $$.tipo = ref
          }
       | lCamp tSim ID_ PUNTOCOMA_ {
          int ref = $1.tipo;
          int desp = $1.valor;
          if(insTdR(ref,$3,$2,desp)==-1)
            yyerror(E_CAMPO_DEC);
          else{  $$.valor =TALLA_TIPO_SIMPLE + desp;
                 $$.tipo = ref;
          }
          }
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
insES  : READ_  PARA_ ID_ PARC_ PUNTOCOMA_ {
          SIMB simb = obtTdS($3);
          if (simb.tipo == T_ERROR) 
              yyerror(E_VAR_NO_DEC);  
        }
       | PRINT_ PARA_ exp PARC_ PUNTOCOMA_ 
       ;
insSel : IF_ PARA_ exp PARC_ 
        { if ($3.tipo != T_ERROR && $3.tipo != T_LOGICO) yyerror(E_IF_LOGICO); }
        ELSE_ ins
       ;


insIt  : WHILE_ PARA_ exp PARC_
        { if ($3.tipo != T_ERROR && $3.tipo != T_LOGICO) yyerror(E_WHILE_LOGICO); }
        ins
       ;
insExp : exp PUNTOCOMA_
       | PUNTOCOMA_
       ;
exp    : expLog
        {$$.tipo = $1.tipo;}
       | ID_ opAsig  exp
       | ID_ CORA_  exp CORC_ opAsig exp
       | ID_ PUNTO_ ID_ opAsig exp
       ;
expLog : expIg
       | expLog opLog expIg 
       {$$.tipo = T_LOGICO;}
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
con    : CTE_   {$$.tipo=T_ENTERO;
                 $$.valor = $1}
       | TRUE_  {$$=T_LOGICO;
                $$.valor = TRUE}
       | FALSE_ {$$=T_LOGICO;
                $$.valor = FALSE}
       ;
opAsig : ASIG_ {$$ = OP_ASIG;}
       | MASIG_ {$$ = OP_ASIG_SUMA;}
       | MENIG_ {$$ = OP_ASIG_RESTA;}
       | PORIG_ {$$ = OP_ASIG_MULT;}
       | DIVIG_ {$$ = OP_ASIG_DIV;}
       ;
opLog  : AND_ {$$ = OP_AND;}
       | OR_ {$$ = OP_OR;}
       ;
opIg   : IGUAL_ {$$ = OP_IGUAL;}
       | DIST_ {$$ = OP_DISTINTO;}
       ;
opRel  : MAY_ {$$ = OP_MAYOR;}
       | MEN_ {$$ = OP_MENOR;}
       | MAIGUAL_ {$$ = OP_MAYORIG;}
       | MEIGUAL_ {$$ = OP_MENORIG;}
       ;
opAd   : MAS_ {$$ = OP_SUMA;}
       | MENOS_ {$$ = OP_RESTA;}
       ;
opMul  : POR_ {$$ = OP_MULT;}
       | DIV_ {$$ = OP_DIV;}
       | MOD_ {$$ = OP_MOD;}
       ;
opUn   : MAS_ {$$ = OP_MAS;}
       | MENOS_ {$$ = OP_MENOS;}
       | NOT_ {$$ = OP_NOT;}
       ;
opIn   : INC_ {$$ = OP_INC;}
       | DEC_ {$$ = OP_DEC;}
       ;
%%


/*****************************************************************************/

/*****************************************************************************/

/*****************************************************************************/
