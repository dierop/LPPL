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
%type <cent> opAsig opIn opLog opIg opRel opAd opUn opMul
%type <exp> exp expLog expIg expRel expMul expUn expSuf
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
       | ID_ opAsig  exp{ $$.tipo = T_ERROR;
                     if ($3.tipo != T_ERROR) { //La expresion no es de tipo error, por tanto
                          SIMB simb = obtenerTDS($1); //tomamos los valores del ID_
                          if (simb.tipo == T_ERROR) { //Si no esta declarado
                              yyerror(E_UNDECLARED);
                          else if (simb.tipo != $3.tipo) { //Si no tiene el mismo tipo las expresiones
                              yyerror(E_TIPOS);
                          } else { //en otro caso, asumimos que es correcto y por tanto
                              $$.tipo = simb.tipo;
                              $$.valid = FALSE;
                          }
                      } }
       | ID_ CORA_  exp CORC_ opAsig exp{ $$.tipo = T_ERROR;
                                          if ($3.tipo != T_ERROR && $6.tipo != T_ERROR) { //Ninguna de las dos expresiones es de tipo error
                                               SIMB simb = obtenerTDS($1);
                                               if (simb.tipo == T_ERROR) {//La expresion principal tampoco es de tipo error
                                                   yyerror(E_VAR_NO_DEC);
                                               } else if (simb.tipo != T_ARRAY) {//Corchetes sobre una expresion que no es un array
                                                   yyerror(E_VAR_WITH_INDEX);
                                               } else {
                                                   DIM dim = obtenerInfoArray(simb.ref); //Obtenemos la informacion del array
                                                   if (dim.telem != $6.tipo) { //El tipo de los elemntos del array coincide con el elemento que intentamos introducir
                                                       yyerror(E_TIPOS);
                                                   } else if (($3.valid == TRUE && $6.valid == TRUE) && ($3.valor < 0 || $3.valor >= dim.nelem)) {// Comprobamos tanto que el array y el elemento son validos como si el indice del array esta dentro de la talla
                                                       yyerror(E_INDICE_ARRAY);
                                                   } else { //Asignamos
                                                       $$.tipo = dim.telem;
                                                       $$.valid = TRUE;
                                                   }
                                               }
                                           } }
       | ID_ PUNTO_ ID_ opAsig exp{ $$.tipo = T_ERROR
                                   if($1.tipo != T_ERROR && $3.tipo != T_ERROR && $5.tipo == T_ERROR){// Comprobamos que ningun valor es de tipo error
                                          SIMB simb = obtenerTDS($5)
                                          if(simb.tipo == T_ERROR) {
                                                 yyerror(E_VAR_NO_DEC);
                                          } else if(simb.tipo != T_ARRAY){
                                                 yyerror(E_TIPOS);
                                          } else {
                                                 DIM dim = obtenerInfoArray(simb.ref);
                                                 if(dim.telem != $5.tipo){
                                                        yyerror(E_TIPOS);
                                                 } else if ($5.valid != TRUE && ($1.valor < 0 || $1.valor >= dim.nelem)){
                                                        yyerror(E_INDICE_ARRAY);
                                                 } else{
                                                        $$.tipo = dim.telem;
                                                        $$.valid = TRUE;
                                                 }
                                          }
                                    }
                                   }
       ;
expLog : expIg { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | expLog opLog expIg //{$$.tipo = T_LOGICO;}
       ;
expIg  : expRel { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | expIg opIg expRel
       ;
expRel : expAd { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | expRel opRel expAd
       ;
expAd  : expMul { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | expAd opAd expMul{ $$.tipo = T_ERROR;
                            if ($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                 if ($1.tipo != $3.tipo) {
                                     yyerror("Tipos no coinciden en operacion multiplicativa");
                                 } else if ($1.tipo != T_ENTERO) {
                                     yyerror("Operacion multiplicativa solo acepta argumentos enteros");
                                 } else { //Descartamos que los valores no sean validos
                                     $$.tipo = T_ENTERO;
                                     if ($1.valid == TRUE && $3.valid == TRUE) { //Descartamos expresiones invalidas
                                         if ($2 == OP_MULT) //Caso Multiplicacion
                                             $$.valor = $1.valor * $3.valor;
                                         else if ($2 == OP_DIV) { //Caso Division
                                             if ($3.valor == 0) { //Si el segundo valor es 0, error
                                                 $$.tipo = T_ERROR;
                                                 yyerror("Division entre 0");
                                             } else {
                                                 $$.valor = $1.valor / $3.valor;
                                             }
                                         } else if ($2 == OP_MOD) { //Caso Modulo
                                             if ($3.valor == 0) { //Si el segundo valor es 0, error
                                                 $$.tipo = T_ERROR;
                                                 yyerror("Modulo entre 0");
                                             } else {
                                                 $$.valor = $1.valor % $3.valor;
                                             }
                                         }
                                         $$.valid = TRUE;
                                     } else $$.valid = FALSE;
                                 }
                             } }
       ;
expMul : expUn { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | expMul opMul expUn{ $$.tipo = T_ERROR;
                      $$.valid = $2.valid;
                      $$.tipo = T_ENTERO
                      }
                      { $$.tipo = T_ERROR;
                      $$.valid = $2.valid;
                      $$.tipo = T_LOGICO}
       ;
expUn  : expSuf { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | opUn  expUn{ $$.tipo = T_ERROR;
                      $$.valid = $2.valid;
                      $$.tipo = T_ENTERO
                      }
                      { $$.tipo = T_ERROR;
                      $$.valid = $2.valid;
                      $$.tipo = T_ENTERO}
       | opIn  ID_
                     { SIMB simb = obtenerTDS($2);//Comprobamos que la variable ID_ ha sido declarada
                      $$.tipo = T_ERROR;
                      if (simb.tipo == T_ERROR)
                          yyerror(E_VAR_NO_DEC);
                      else
                          $$.tipo = simb.tipo;
                      $$.valid = FALSE; }
                     
expSuf : PARA_ exp     PARC_ { $$.tipo = $1.tipo; $$.valor = $1.valor; $$.valid = $1.valid; }
       | ID_    opIn
               { SIMB simb = obtenerTDS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               $$.valid = FALSE;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else
                   $$.tipo = simb.tipo; }
       | ID_    CORA_  exp CORC_
              { SIMB simb = obtenerTDS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               $$.valid = FALSE;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else
                     $$.tipo = simb.tipo;}
       | ID_
              { SIMB simb = obtenerTDS($1); //Comprobamos que la variable ID_ ha sido declarada
               $$.tipo = T_ERROR;
               $$.valid = FALSE;
               if (simb.tipo == T_ERROR)
                   yyerror(E_VAR_NO_DEC);
               else
                     $$.tipo = simb.tipo;}
       //| ID_    PUNTO_ ID_ no he visto que se necesite poder declarar una expresion tal que ID.ID en P2-ASemantico
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
