%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "asin.h"

#define  retornar(x) {if (verbosidad) ECHO; return(x);}
%}
/*-----------------------------------------------------------------------------
  Estas opciones evitan "warnings" innecesarios y permiten obtener el
  numero de linea actual en la variable global "yylineno".
-----------------------------------------------------------------------------*/
%option noinput       
%option nounput       
%option yylineno  

delimitador    [ \t\n]+
digito         [0-9]
entero         {digito}+
letra          [a-zA-Z]

%%
{delimitador}  { if (verbosidad) ECHO; }

"//".*                               {}
"struct"                            {retornar (STRUCT_);  }
"int"                               {retornar (INT_);  }
"bool"                              {retornar (BOOL_);  }
"read"                              {retornar (READ_);  }
"print"                             {retornar (PRINT_);  }
"if"                                {retornar (IF_);  }
"else"                              {retornar (ELSE_);  }
"while"                             {retornar (WHILE_);  }
"true"                              {retornar (TRUE_);  }
"false"                             {retornar (FALSE_);  }

"&&"                                {retornar (AND_);  }
"||"                                {retornar (OR_);  }
"=="                                {retornar (IGUAL_);  }
"!="                                {retornar (DIST_);  }
">="                                {retornar (MAIGUAL_);  }
"<="                                {retornar (MEIGUAL_);  }
"!"                                 { retornar (NOT_);   }

"++"                                {retornar (INC_);  }
"--"                                {retornar (DEC_);  }
"+="                                {retornar (MASIG_);  }
"-="                                {retornar (MENIG_);  }
"/="                                {retornar (DIVIG_);  }
"*="                                {retornar (PORIG_);  }

">"                                 {retornar (MAY_);  }
"<"                                 {retornar (MEN_);  }
"="                                 {retornar (ASIG_);  }
"+"	                                { retornar (MAS_);   }
"-"                                 { retornar (MENOS_); }
"*"                                 { retornar (POR_);   }
"/"                                 { retornar (DIV_);   }
"%"                                 {retornar (MOD_);  }
"("                                 { retornar (PARA_);  }
")"                                 { retornar (PARC_);   }
"["                                 { retornar (CORA_);  }
"]"                                 { retornar (CORC_);   }
"{"                                 { retornar (LLAVEA_);  }
"}"                                 { retornar (LLAVEC_);   }

";"                                 {retornar (PUNTOCOMA_);  }

{letra}({letra}|{digito})*\_?       { yylval.ident = strdup(yytext); retornar(ID_); }
{entero}("."{digito}*)?             { yylval.cent = atoi(yytext); retornar(CTE_); }
"."{entero}                         { yylval.cent = atoi(yytext); retornar(CTE_); }
"."                                 { retornar (PUNTO_);  }

.	       { yyerror("Caracter desconocido"); }

%%
/*****************************************************************************/

/*****************************************************************************/
