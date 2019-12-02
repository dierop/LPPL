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
  char* ident;
  EXP exp;
}

%token STRUCT_     READ_     PRINT_     IF_      ELSE_    WHILE_   TRUE_ FALSE_
%token AND_        OR_       IGUAL_     DIST_    MAIGUAL_ MEIGUAL_ NOT_
%token INC_        DEC_      MASIG_     MENIG_   DIVIG_   PORIG_
%token MAY_        MEN_      ASIG_      MAS_     MENOS_   POR_     DIV_  MOD_ PARA_ 
%token PARC_       CORA_     CORC_      LLAVEA_  LLAVEC_
%token PUNTOCOMA_  PUNTO_ 

%token <cent> CTE_ INT_  BOOL_
%token <ident>   ID_

%type <cent> tSim opUn
%type <cent> opAsig opIn opLog opIg opRel opAd opUn opMul
%type <exp> expr expLog expIg expRel expMul expUn expSuf expAd
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
            if (!insTdS($2, T_ARRAY, dvar, refe))
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
          $$.tipo = ref;
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
          else if(simb.tipo !=T_ENTERO)
                yyerror(E_VAR_NO_TIPO_ESPERADO);
         }
       | PRINT_ PARA_ expr PARC_ PUNTOCOMA_ {
           if($3.tipo != T_ENTERO || $3.tipo != T_LOGICO) {
               yyerror(E_TIPOS);
           }
       }
       ;
insSel : IF_ PARA_ expr PARC_ ins ELSE_ ins
        { if ($3.tipo != T_LOGICO && $3.tipo != T_ERROR) yyerror(E_IF_LOGICO); }
       ;


insIt  : WHILE_ PARA_ expr PARC_ ins
        { if ($3.tipo != T_LOGICO && $3.tipo != T_ERROR) yyerror(E_WHILE_LOGICO); }
       ;
insExp : expr PUNTOCOMA_
       | PUNTOCOMA_
       ;
expr    : expLog
        {$$.tipo = $1.tipo;}
       | ID_ opAsig  expr{ $$.tipo = T_ERROR;
                     if ($3.tipo != T_ERROR) { //La expresion no es de tipo error, por tanto
                          SIMB simb = obtTdS($1); //tomamos los valores del ID_
                          if (simb.tipo == T_ERROR)  //Si no esta declarado
                              yyerror(E_VAR_NO_DEC);
                          else if (simb.tipo != $3.tipo)  //Si no tiene el mismo tipo las expresiones
                              yyerror(E_TIPOS);
                           else  //en otro caso, asumimos que es correcto y por tanto
                              $$.tipo = simb.tipo;   
                      } } 
       | ID_ CORA_  expr CORC_ opAsig expr{ $$.tipo = T_ERROR;
                                          if ($3.tipo != T_ERROR && $6.tipo != T_ERROR) { //Ninguna de las dos expresiones es de tipo error
                                               SIMB simb = obtTdS($1);
                                               $$.tipo = T_ERROR;
                                               if (simb.tipo == T_ERROR) {//La expresion principal tampoco es de tipo error
                                                   yyerror(E_VAR_NO_DEC);
                                               } else{ if (simb.tipo != T_ARRAY) {//Corchetes sobre una expresion que no es un array
                                                   yyerror(E_VAR_CON_INDICE);
                                               } else { if($3.tipo != T_ENTERO)
                                                            yyerror(E_INDICE_ARRAY);
                                                        else{
                                                            if(obtTdA(simb.ref).telem!=$6.tipo)
                                                                yyerror(E_TIPOS);
                                                            else
                                                                $$.tipo = $6.tipo;
                                                        }    
                                                 }}
                                            }}
       | ID_ PUNTO_ ID_ opAsig expr{ $$.tipo = T_ERROR;
                                    SIMB simb = obtTdS($1);
                                    if(simb.tipo == T_ERROR) 
                                            yyerror(E_VAR_NO_DEC);
                                    else{   if (simb.tipo !=T_RECORD)
                                                yyerror(E_TIPOS);
                                            else{  CAMP reg = obtTdR(simb.ref,$3);
                                                if (reg.tipo == T_ERROR)
                                                    yyerror(E_CAMPO_NO_DEC);
                                                else{ if(reg.tipo!= $5.tipo)
                                                        yyerror(E_TIPOS);
                                                    else
                                                        $$.tipo =reg.tipo;
                                                    }
                                                }
                                        }
                                    }
                                   
       ;
expLog : expIg { $$.tipo = $1.tipo;}
       | expLog opLog expIg {
           $$.tipo = T_ERROR;
           if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
               
            if($1.tipo != $3.tipo) 
               yyerror(E_TIPOS);
            else if($1.tipo != T_LOGICO ||$3.tipo != T_LOGICO ) 
               yyerror(E_IF_LOGICO);
            else $$.tipo = T_LOGICO;
        }}
       ;
expIg  : expRel { $$.tipo = $1.tipo;}
       | expIg opIg expRel {
           $$.tipo = T_ERROR;
            if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {   
                if ($1.tipo != $3.tipo) 
                    yyerror(E_TIPOS);
                else if($1.tipo != T_ENTERO|| $3.tipo != T_ENTERO) 
                        yyerror(E_EXP_IGUALDAD);
                      else $$.tipo = T_LOGICO;
            }}
       ;
expRel : expAd { $$.tipo = $1.tipo;}
       | expRel opRel expAd {
           $$.tipo = T_ERROR;
           if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
               
            if ($1.tipo != $3.tipo) {
               yyerror(E_TIPOS);
            } else if($1.tipo != T_ENTERO) {
               yyerror(E_TIPOS);
            } else $$.tipo = T_LOGICO;
       }}
       ;
expAd  : expMul { $$.tipo = $1.tipo;}
       | expAd opAd expMul{ 
           $$.tipo = T_ERROR;
            if ($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                if ($1.tipo != $3.tipo) {
                    yyerror("Tipos no coinciden en operacion aditiva");
                } else if ($1.tipo != T_ENTERO && $3.tipo != T_ENTERO) {
                    yyerror("Operacion aditiva solo acepta argumentos enteros");
                } else $$.tipo = T_ENTERO;
            }
        } 
       ;
expMul : expUn { $$.tipo = $1.tipo;}
       | expMul opMul expUn {
            $$.tipo = T_ERROR;
            if ($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                if ($1.tipo != $3.tipo) {
                    yyerror("Tipos no coinciden en operacion multiplicativa");
                } else if ($1.tipo != T_ENTERO && $3.tipo != T_ENTERO) {
                    yyerror("Operacion multiplicativa solo acepta argumentos enteros");
                } else $$.tipo = T_ENTERO;
            }
       }
       ;
expUn  : expSuf { $$.tipo = $1.tipo;}
       | opUn  expUn {
            
            $$.tipo = T_ERROR;
            if ($2.tipo != T_ERROR) {
                if ($1 == 1){
                    if ($2.tipo != T_LOGICO) 
                        yyerror(E_EXP_UNARIA);
                    else
                        $$.tipo = $2.tipo;
                } 
                else{  if ($2.tipo != T_ENTERO) 
                        yyerror(E_EXP_UNARIA);
                    else
                        $$.tipo = $2.tipo;
                }}
       }
       | opIn  ID_ {
            SIMB simb = obtTdS($2);//Comprobamos que la variable ID_ ha sido declarada
            $$.tipo = T_ERROR;
            if (simb.tipo == T_ERROR)
                yyerror(E_VAR_NO_DEC);
            else    if(simb.tipo !=T_ENTERO)
                        yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else
                        $$.tipo = simb.tipo;
        }
                     
expSuf : PARA_ expr  PARC_ { $$.tipo = $2.tipo;}//sea error o otra cosa se sube
       | ID_    opIn
               { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else if(simb.tipo !=T_ENTERO)
                        yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else
                        $$.tipo = simb.tipo; }
       | ID_    CORA_  expr CORC_
              { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else if(simb.tipo != T_ARRAY)
                    yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else
                     $$.tipo = obtTdA(simb.ref).telem;}
       | ID_
              { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else
                     $$.tipo = simb.tipo;}
       | ID_    PUNTO_ ID_{
            $$.tipo = T_ERROR;
            SIMB simb = obtTdS($1);
            if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
            else{   if (simb.tipo !=T_RECORD)
                        yyerror(E_TIPOS);
                    else{  CAMP reg = obtTdR(simb.ref,$3);
                            if (reg.tipo == T_ERROR)
                                    yyerror(E_CAMPO_NO_DEC);
                            else{
                                $$.tipo = reg.tipo;
                            }
                    }
            }}
       | con    {$$.tipo=$1.tipo;}
       ;
con    : CTE_   {$$.tipo=T_ENTERO;
                 $$.valor = $1;}
       | TRUE_  {$$.tipo=T_LOGICO;
                $$.valor = TRUE;}
       | FALSE_ {$$.tipo=T_LOGICO;
                $$.valor = FALSE;}
       ;
opAsig : ASIG_  {$$=EASIG;}
       | MASIG_ {$$=ESUM;}
       | MENIG_ {$$=EDIF;}
       | PORIG_ {$$=EMULT;}
       | DIVIG_ {$$=EDIVI;}
       ;
opLog  : AND_ 
       | OR_ 
       ;
opIg   : IGUAL_ {$$=EIGUAL;}
       | DIST_  {$$=EDIST;}
       ;
opRel  : MAY_       {$$=EMAY;}
       | MEN_       {$$=EMEN;}
       | MAIGUAL_   {$$=EMAYEQ;}
       | MEIGUAL_   {$$=EMENEQ;}
       ;
opAd   : MAS_  {$$=ESUM;}
       | MENOS_ {$$=EDIF;}
       ;
opMul  : POR_ {$$=EMULT;}
       | DIV_ {$$=EDIVI;}
       | MOD_ {$$=RESTO;}
       ;
opUn   : MAS_ {$$=;}
       | MENOS_ {$$=ESIG;}
       | NOT_ {$$=;}
       ;
opIn   : INC_ {$$=ESUM;}
       | DEC_ {$$=EDIF;}
       ;
%%