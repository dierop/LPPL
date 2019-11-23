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
#define E_CAMPO_DEC "Campo de STUCT ya declarado"
#define E_VAR_NO_DEC "Variable no declarada antes de su uso"
#define E_IF_LOGICO "La expresion no es logica"
#define E_WHILE_LOGICO "La expresion no es logica"

/************************************* Operadores */
/*Asignacion */
#define OP_ASIG       0
#define OP_ASIG_SUMA  1
#define OP_ASIG_RESTA 2
#define OP_ASIG_MULT  3
#define OP_ASIG_DIV   4

/*Logico*/
#define OP_AND 0
#define OP_OR  1

/*igualdad */
#define OP_IGUAL    0
#define OP_DISTINTO 1

/*relacional */
#define OP_MAYOR   0
#define OP_MAYORIG 1
#define OP_MENOR   2
#define OP_MENORIG 3

/*aditivo */
#define OP_SUMA  0
#define OP_RESTA 1

/*multiplicativo */
#define OP_MULT 0
#define OP_DIV  1
#define OP_MOD  2

/*unario */
#define OP_MAS   0
#define OP_MENOS 1
#define OP_NOT   2

/*incremento */
#define OP_INC 0
#define OP_DEC 1
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
