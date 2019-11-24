/*****************************************************************************/
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H

/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0
#define TALLA_TIPO_SIMPLE 1
/************************************* definicion de errores */
#define E_VAR_DEC "Variable ya esta declarada"
#define E_TIPOS "Error de tipos"
#define E_TALLA_ARRAY "Talla inapropiada del array"
#define E_INDICE_ARRAY "Indice inapropiadado para el array"
#define E_CAMPO_DEC "Campo de STRUCT ya declarado"
#define E_VAR_NO_DEC "Variable no declarada antes de su uso"
#define E_IF_LOGICO "La expresion no es logica"
#define E_WHILE_LOGICO "La expresion no es logica"

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
