/*****************************************************************************/
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H

/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0
#define TALLA_TIPO_SIMPLE 1
/************************************* Variables externas definidas en el AL */
extern int yylex();
extern int yyparse();

extern FILE *yyin;
extern int   yylineno;

extern int verTDS;
extern int dvar;
/********************************* Funciones y variables externas auxiliares */
extern int verbosidad;                   /* Flag si se desea una traza       */

extern void yyerror(const char * msg) ;   /* Tratamiento de errores          */

struct exp {
 int valor;
 int tipo;

} EXP
#endif  /* _HEADER_H */
/*****************************************************************************/
/*****************************************************************************/
