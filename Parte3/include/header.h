/*****************************************************************************/
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H

/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0
#define TALLA_TIPO_SIMPLE 1
#define NOT_VAL -1

/************************************* definicion de errores */
#define E_VAR_DEC "Variable ya esta declarada"
#define E_TIPOS "Error de tipos"
#define E_TALLA_ARRAY "Talla inapropiada del array"
#define E_INDICE_ARRAY "Indice inapropiadado para el array"
#define E_VAR_CON_INDICE "La variable no es un array"
#define E_CAMPO_DEC "Campo de STRUCT ya declarado"
#define E_CAMPO_NO_DEC "Campo de STRUCT no declarada antes de su uso"
#define E_VAR_NO_DEC "Variable no declarada antes de su uso"
#define E_IF_LOGICO "La expresion no es logica"
#define E_WHILE_LOGICO "La expresion no es logica"
#define E_VAR_NO_TIPO_ESPERADO "La variable no es del tipo adecuado para su uso en la expresion"
#define E_EXP_UNARIA "Error en 'expresion unaria'"
#define E_EXP_IGUALDAD "Error en 'expresion de Igualdad'"
/************************************* Variables externas definidas en el AL */
extern int yylex();
extern int yyparse();

extern FILE *yyin;
extern int   yylineno;

extern int verTDS;
extern int dvar;
extern int si;
/********************************* Funciones y variables externas auxiliares */
extern int verbosidad;                   /* Flag si se desea una traza       */

extern void yyerror(const char * msg) ;   /* Tratamiento de errores          */


typedef struct exp {
 int valor;
 int tipo;
 int pos;

} EXP;
#endif  /* _HEADER_H */
/*****************************************************************************/
/*****************************************************************************/
