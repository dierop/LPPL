/*****************************************************************************/
/**  Ejemplo de BISON-I: S E M - 2          2019-2020 <jbenedi@dsic.upv.es> **/
/**  V. 19                                                                  **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"
#include "libgci.h"
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

%type <cent> tSim 
%type <cent> opAsig opIn opLog opIg opRel opAd opUn opMul
%type <exp> expr expLog expIg expRel expMul expUn expSuf expAd
%type <exp> con lCamp
%%

prog   : LLAVEA_ sse LLAVEC_
        { emite(FIN,crArgNul(), crArgNul(), crArgNul()); }
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
            else{
                emite(EASIG,crArgPos($4.pos),crArgNul(),crArgPos(dvar)); 
                dvar += TALLA_TIPO_SIMPLE;
           }}}
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
          else emite(EREAD, crArgNul(), crArgNul(), crArgPos(simb.desp));
         }
       | PRINT_ PARA_ expr PARC_ PUNTOCOMA_ {
           if($3.tipo != T_ENTERO && $3.tipo != T_LOGICO) {
               yyerror(E_TIPOS);
           }
           else emite(EWRITE, crArgNul(), crArgNul(), crArgPos($3.pos));
       }
       ;
insSel : IF_ PARA_ expr PARC_ ins ELSE_ ins
        { if ($3.tipo != T_LOGICO && $3.tipo != T_ERROR) yyerror(E_IF_LOGICO);
        else {
            emite(EIGUAL, crArgPos($3.pos), crArgEnt(FALSE),crArgEtq(si+2));
        } }
       ;


insIt  : WHILE_ PARA_ expr PARC_ ins
        { if ($3.tipo != T_LOGICO && $3.tipo != T_ERROR) yyerror(E_WHILE_LOGICO);
        else {
            emite(EIGUAL, crArgPos($3.pos), crArgEnt(FALSE),crArgEtq(si+2));
            emite(GOTOS, crArgNul(), crArgNul(), crArgEtq(si));
        } }
       ;
insExp : expr PUNTOCOMA_
       | PUNTOCOMA_
       ;
expr    : expLog
        {$$.tipo = $1.tipo; $$.valor = $1.valor; $$.pos = $1.pos;}
       | ID_ opAsig  expr{ $$.tipo = T_ERROR;
                    SIMB simb;
                     if ($3.tipo != T_ERROR) { //La expresion no es de tipo error, por tanto
                          simb = obtTdS($1); //tomamos los valores del ID_
                          if (simb.tipo == T_ERROR)  //Si no esta declarado
                              yyerror(E_VAR_NO_DEC);
                          else if (simb.tipo != $3.tipo)  //Si no tiene el mismo tipo las expresiones
                              yyerror(E_TIPOS);
                           else  //en otro caso, asumimos que es correcto y por tanto
                              $$.tipo = simb.tipo;   
                      }
                      $$.pos = creaVarTemp();
                      if($2 == EASIG)
                        emite(EASIG, crArgPos($3.pos),crArgNul(),crArgPos($$.pos));
                      else {
                            emite($2, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                        }
                        emite(EASIG, crArgPos($$.pos), crArgNul(), crArgPos(simb.desp));  } 

       | ID_ CORA_  expr CORC_ opAsig expr{ $$.tipo = T_ERROR;
                                        SIMB simb;
                                          if ($3.tipo != T_ERROR && $6.tipo != T_ERROR) { //Ninguna de las dos expresiones es de tipo error
                                               simb = obtTdS($1);
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
                                            }
                                        $$.pos = creaVarTemp();
                                        if($5 != EASIG) {
                                            emite(EAV, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                            emite($5, crArgPos($$.pos), crArgPos($6.pos), crArgPos($$.pos));
                                        } else {
                                            emite($5, crArgPos($6.pos), crArgNul(), crArgPos($$.pos));
                                        }
                                        emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                        }
    
       | ID_ PUNTO_ ID_ opAsig expr{ $$.tipo = T_ERROR;
                                    SIMB simb = obtTdS($1);
                                    if(simb.tipo == T_ERROR) 
                                            yyerror(E_VAR_NO_DEC);
                                    else{   if (simb.tipo !=T_RECORD)
                                                yyerror(E_TIPOS);
                                            else{  
                                                CAMP reg = obtTdR(simb.ref,$3);
                                                if (reg.tipo == T_ERROR)
                                                    yyerror(E_CAMPO_NO_DEC);
                                                else{ if(reg.tipo!= $5.tipo)
                                                        yyerror(E_TIPOS);
                                                    else{
                                                        $$.tipo =reg.tipo;
                                                        int d=simb.desp+reg.desp;
                                                        if($4==EASIG)
                                                            emite(EASIG,crArgPos($5.pos),crArgNul(),crArgPos(d));
                                                        else{
                                                            $$.pos=creaVarTemp();
                                                            emite($4,crArgPos($5.pos),crArgPos(d),crArgPos($$.pos));
                                                            emite(EASIG,crArgPos($$.pos),crArgNul(),crArgPos(d));
                                                        }

                                                    
                                                    }
                                                    }
                                                }
                                        }
                                    }
                                   
       ;
expLog : expIg { $$.tipo = $1.tipo;
                 $$.pos = $1.pos;
                }
       | expLog opLog expIg {
           $$.tipo = T_ERROR;
           if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
               
            if($1.tipo != $3.tipo) 
               yyerror(E_TIPOS);
            else if($1.tipo != T_LOGICO ||$3.tipo != T_LOGICO ) 
               yyerror(E_IF_LOGICO);
            else{ 
            $$.tipo = T_LOGICO;
            $$.pos=creaVarTemp();

            emite($2, crArgPos($1.pos), crArgPos($3.pos),crArgPos($$.pos));
            emite(EIGUAL, crArgEnt(FALSE), crArgPos($$.pos), crArgEtq( si + 2));
            emite(EASIG, crArgEnt(TRUE), crArgNul(),crArgPos($$.pos));            
            }
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
                      else {
                        $$.tipo = T_LOGICO;
                        $$.pos=creaVarTemp();

                        emite(EASIG, crArgEnt(TRUE), crArgNul(), crArgPos($$.pos));
                        emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos(si + 2));
                        emite(EASIG, crArgEnt(FALSE), crArgNul(), crArgPos($$.pos));
                      }
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
            } else {
              $$.tipo = T_LOGICO;
              $$.pos = creaVarTemp();

              emite(EASIG, crArgEnt(TRUE), crArgNul(), crArgPos($$.pos));
              emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos(si + 2));
              emite(EASIG, crArgEnt(FALSE), crArgNul(), crArgPos($$.pos));
            }
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
                } else {
                  $$.tipo = T_ENTERO;
                  $$.pos = creaVarTemp();

                  emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                }
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
                } else {
                  $$.tipo = T_ENTERO;
                  $$.pos = creaVarTemp();

                  emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                }
            }
       }
       ;
expUn  : expSuf { $$.tipo = $1.tipo;$$.pos=$1.pos;}
       | opUn  expUn {
            
            $$.tipo = T_ERROR;
            if ($2.tipo != T_ERROR) {
                $$.pos=creaVarTemp();
                if ($1 == NOT_VAL){
                    if ($2.tipo != T_LOGICO) 
                        yyerror(E_EXP_UNARIA);
                    else{
                        $$.tipo = $2.tipo;
                        emite(EASIG,crArgEnt(TRUE),crArgNul(),crArgPos($$.pos));
                        emite(EIGUAL,crArgPos($2.pos),crArgEnt(TRUE),crArgEtq(si+2));
                        emite(EASIG,crArgEnt(FALSE),crArgNul(),crArgPos($$.pos));
                    }
                } 
                else{  if ($2.tipo != T_ENTERO) 
                        yyerror(E_EXP_UNARIA);
                    else{
                        $$.tipo = $2.tipo;
                        emite($1,crArgPos($2.pos),crArgNul(),crArgPos($$.pos));
                    }
                }}
       }
       | opIn  ID_ {
            SIMB simb = obtTdS($2);//Comprobamos que la variable ID_ ha sido declarada
            $$.tipo = T_ERROR;
            if (simb.tipo == T_ERROR)
                yyerror(E_VAR_NO_DEC);
            else    if(simb.tipo !=T_ENTERO)
                        yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else{
                        $$.tipo = simb.tipo;
                        $$.pos=creaVarTemp();
                        emite($1,crArgEnt(1),crArgPos(simb.desp),crArgPos($$.pos));
                        emite(EASIG,crArgPos($$.pos),crArgNul(),crArgPos(simb.desp));
                    }
        }
        ;           
expSuf : PARA_ expr  PARC_ { $$.tipo = $2.tipo;}//sea error o otra cosa se sube
       | ID_    opIn
               { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else if(simb.tipo !=T_ENTERO)
                   yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else {
                        $$.tipo = simb.tipo;
                        $$.pos=creaVarTemp();
                        emite($2,crArgEnt(1),crArgPos(simb.desp),crArgPos($$.pos));
                        emite(EASIG,crArgPos($$.pos),crArgNul(),crArgPos(simb.desp));
                        }
                    }
       | ID_    CORA_  expr CORC_
              { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else if(simb.tipo != T_ARRAY || $3.tipo != T_ENTERO)
                    yyerror(E_VAR_NO_TIPO_ESPERADO);
                    else {
                     $$.tipo = obtTdA(simb.ref).telem;
                     $$.pos=creaVarTemp();
                     emite(EAV,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($$.pos));
                     }
                }
       | ID_
              { SIMB simb = obtTdS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else{
                     $$.tipo = simb.tipo;
                     $$.pos=creaVarTemp();
                      emite(EASIG,crArgPos(simb.desp),crArgNul(),crArgPos($$.pos));
                     }
                     }
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
                                $$.pos=creaVarTemp();
                                emite(EASIG,crArgPos(reg.desp),crArgNul(),crArgPos($$.pos));
                            }
                    }
            }}
       | con    {$$.tipo=$1.tipo;
                $$.pos=creaVarTemp();
                emite(EASIG,crArgPos($1.pos),crArgNul(),crArgPos($$.pos));
       }
       ;
con    : CTE_   {$$.tipo=T_ENTERO;
                 $$.valor = $1;
                 $$.pos=creaVarTemp();
                 emite(EASIG, crArgEnt($$.valor), crArgNul(), crArgPos($$.pos)); 
                 }
       | TRUE_  {$$.tipo=T_LOGICO;
                $$.valor = TRUE;
                $$.pos=creaVarTemp();
                emite(EASIG, crArgEnt(TRUE), crArgNul(), crArgPos($$.pos)); 
                }
       | FALSE_ {$$.tipo=T_LOGICO;
                $$.valor = FALSE;
                $$.pos=creaVarTemp();
                emite(EASIG, crArgEnt(FALSE), crArgNul(), crArgPos($$.pos));
                }
       ;
opAsig : ASIG_  {$$=EASIG;}
       | MASIG_ {$$=ESUM;}
       | MENIG_ {$$=EDIF;}
       | PORIG_ {$$=EMULT;}
       | DIVIG_ {$$=EDIVI;}
       ;
opLog  : AND_  {$$ = EMULT;}
       | OR_   {$$ = ESUM;}
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
opUn   : MAS_ {$$=EASIG;}
       | MENOS_ {$$=ESIG;}
       | NOT_ {$$=NOT_VAL;}
       ;
opIn   : INC_ {$$=ESUM;}
       | DEC_ {$$=EDIF;}
       ;
%%
