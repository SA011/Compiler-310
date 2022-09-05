%{
#include<bits/stdc++.h>
using namespace std;


enum Type{
     Unknown = 0, Int, Double, Float,  Char, Func, Undefined_Func, Array, Void
};


string typeToString[] = {"unknown", "int", "double", "float", "char" ,"func", "undefined_func", "array", "void"};
map<string, Type> stringToType = {{"unknown", Unknown}, {"int", Int}, {"double", Double}, {"float", Float},
    {"char", Char}, {"func", Func}, {"undefined_func", Undefined_Func}, {"array", Array}, {"void", Void}};

#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*


int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;
int line_count, error_count;
ofstream err, logfile;
SymbolTable symbols(31);

#define gap "\n\n"
void yyerror(string s)
{
    err << "Error at line " << yylineno << ": " << s << gap;
    logfile << "Error at line " << yylineno << ": " << s << gap;
    error_count++;
}
bool notunScope = false;
#include "functions.h"
SymbolInfo *ret = NULL;
%}

%start start
%token PRINTLN IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE
%token CONST_CHAR CONST_INT CONST_FLOAT ID ERROR STRING
%token ADDOP MULOP INCOP DECOP LOGICOP RELOP ASSIGNOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON

%left COMMA
%right ASSIGNOP
%left LOGICOP
%left RELOP
%left ADDOP
%left MULOP
%right NOT INCOP DECOP
%left LPAREN LTHIRD
%right ELSE THEN
%left SEMICOLON ENDF
%%

start : program {
        $$ = mergeList($1);
        logfile << "Line " << yylineno << ": start : program" << gap;
        symbols.printAllScopeTable(logfile);
        deleteAll($$);
        logfile << "Total Lines: " << yylineno << "\n";
        logfile << "Total Errors: " << error_count << "\n";
	}
	;

program : program unit {
        logfile << "Line " << yylineno << ": program : program unit" << gap;
        $$ = mergeList($1, $2);
        logfile << ($$) << gap;
    }
	| unit  {
        logfile << "Line " << yylineno << ": program : unit" << gap;
        $$ = mergeList($1);
        logfile << ($$) << gap;
    }
	;
	
unit : var_declaration {
        logfile << "Line " << yylineno << ": unit : var_declaration" << gap;
        $$ = mergeList($1);
        logfile << ($$) << gap;
    }
     | func_declaration {
        logfile << "Line " << yylineno << ": unit : func_declaration" << gap;
        $$ = mergeList($1);
        logfile << ($$) << gap;
    }
     | func_definition {
        logfile << "Line " << yylineno << ": unit : func_definition" << gap;
        $$ = $1;
        logfile << ($$) << gap;
    }
    | error %prec ENDF {
        $$ = NULL;
        //deleteAll($1);
        //yyerror("Syntax Error");
    }
    | error SEMICOLON{
        $$ = $2;
        logfile << ($$) << gap;
        //deleteAll($1);
        //yyerror("Syntax Error");
    }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN {
        pushFunction($2, $1, $4, "undefined_func");
    }SEMICOLON {
        logfile << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << gap;
        $$ = mergeList($1, space(), $2, $3, $4, $5, $7, newLine());
        logfile << ($$) << gap;
        symbols.exitScope();
    }
    | type_specifier ID LPAREN RPAREN {
        pushFunction($2, $1, NULL, "undefined_func");
    } SEMICOLON {
        logfile << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << gap;
        $$ = mergeList($1, space(), $2, $3, $4, $6, newLine());
        logfile << ($$) << gap;
        symbols.exitScope();
    }
    
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
            pushFunction($2, $1, $4, "func");
            ret = $1;
            
        } compound_statement {
            logfile << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << gap;
            $$ = mergeList($1, space(), $2, $3, $4, $5, $7);
            logfile << ($$) << gap;
            ret = NULL;
        }
		| type_specifier ID LPAREN RPAREN {
            pushFunction($2, $1, NULL, "func");
            ret = $1;
        }compound_statement {
            logfile << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << gap;
            $$ = mergeList($1, space(), $2, $3, $4, $6);
            logfile << ($$) << gap;
            ret = NULL;
        }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID {
            logfile << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier ID" << gap;
            $$ = mergeList($1, $2, $3, space(), $4);
            logfile << ($$) << gap;
        }
		| parameter_list COMMA type_specifier {
            logfile << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier" << gap;
            $$ = mergeList($1, $2, $3);
            logfile << ($$) << gap;
            
        }
 		| type_specifier ID {
            logfile << "Line " << yylineno << ": parameter_list : type_specifier ID" << gap;
            $$ = mergeList($1, space(), $2);
            logfile << ($$) << gap;
            
        }
		| type_specifier {
            logfile << "Line " << yylineno << ": parameter_list : type_specifier" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
            
        }
        | error {
            $$ = NULL;
            //deleteAll($1);
            //cerr << ($$) << gap;
            //yyerror("Syntax Error");
        }
        | parameter_list error {
            $$ = mergeList($1);
            
            //deleteAll($2);
            logfile << ($$) << gap;
            //cerr << ($$) << gap;
            //yyerror("Syntax Error");
        }
 		;

 		
compound_statement : LCURL {
            if(!notunScope)symbols.enterScope();
            notunScope = false;
        } statements RCURL {
            logfile << "Line " << yylineno << ": compound_statement : LCURL statements RCURL" << gap;
            $$ = mergeList($1, newLine(), $3, $4, newLine());
            logfile << ($$) << gap;
            symbols.printAllScopeTable(logfile);
            symbols.exitScope();
                    
        }
        | LCURL {
            if(!notunScope)symbols.enterScope();
            notunScope = false;
        } RCURL {
                
            logfile << "Line " << yylineno << ": compound_statement : LCURL RCURL" << gap;
            $$ = mergeList($1, newLine(), $3, newLine());
            logfile << ($$) << gap;
            symbols.printAllScopeTable(logfile);
            symbols.exitScope();
            
        }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
                logfile << "Line " << yylineno << ": var_declaration : type_specifier declaration_list SEMICOLON" << gap;
                pushVariables($1, $2);
                $$ = mergeList($1, space(), $2, $3, newLine());
                logfile << ($$) << gap;
                
            }
 		 ;
 		 
type_specifier	: INT {
            logfile << "Line " << yylineno << ": type_specifier : INT" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        } 
 		| FLOAT {
            logfile << "Line " << yylineno << ": type_specifier : FLOAT" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
 		| VOID {
            logfile << "Line " << yylineno << ": type_specifier : VOID" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
 		;
 		
declaration_list : declaration_list COMMA ID {
                logfile << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID" << gap;
                $$ = mergeList($1, $2, $3);
                logfile << ($$) << gap;
            }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
                logfile << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << gap;
                $$ = mergeList($1, $2, $3, $4, $5, $6);
                logfile << ($$) << gap;
            }
 		  | ID {
                logfile << "Line " << yylineno << ": declaration_list : ID" << gap;
                $$ = mergeList($1);
                logfile << ($$) << gap;
            }
 		  | ID LTHIRD CONST_INT RTHIRD {
                logfile << "Line " << yylineno << ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << gap;
                $$ = mergeList($1, $2, $3, $4);
                logfile << ($$) << gap;
            }
          | error {
              $$ = NULL;
                //deleteAll($1);
              //yyerror("Syntax Error");
          }
          | declaration_list error {  
              $$ = mergeList($1);
                //deleteAll($2);
                logfile << ($$) << gap;
              //yyerror("Syntax Error");
          }
 		  ;
 		  
statements : statement {
            logfile << "Line " << yylineno << ": statements : statement" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
	   | statements statement {
            logfile << "Line " << yylineno << ": statements : statements statement" << gap;
            $$ = mergeList($1, $2);
            logfile << ($$) << gap;
        }
	   ;
	   
statement : var_declaration {
            logfile << "Line " << yylineno << ": statement : var_declaration" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
        | expression_statement {
            logfile << "Line " << yylineno << ": statement : expression_statement" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
        | compound_statement {
            logfile << "Line " << yylineno << ": statement : compound_statement" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
        | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
            logfile << "Line " << yylineno << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << gap;
            pop($3);
            pop($4);
            $$ = mergeList($1, $2, $3, $4, $5, $6, $7);
            logfile << ($$) << gap;
        }
        | IF LPAREN expression RPAREN statement %prec THEN {
            logfile << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement" << gap;
            $$ = mergeList($1, space(), $2, $3, $4, $5);
            logfile << ($$) << gap;
        }
        | IF LPAREN expression RPAREN statement ELSE statement {
            logfile << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement ELSE statement" << gap;
            $$ = mergeList($1, space(), $2, $3, $4, $5, $6, space(), $7);
            logfile << ($$) << gap;
        }
        | WHILE LPAREN expression RPAREN statement {
            logfile << "Line " << yylineno << ": statement : WHILE LPAREN expression RPAREN statement" << gap;
            $$ = mergeList($1, $2, $3, $4, $5);
            logfile << ($$) << gap;
        }
        | PRINTLN LPAREN ID RPAREN SEMICOLON {
            logfile << "Line " << yylineno << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << gap;
            $3 = variableCheck($3);
            $$ = mergeList($1, $2, $3, $4, $5, newLine());
            logfile << ($$) << gap;
        }
        | RETURN expression SEMICOLON {
            logfile << "Line " << yylineno << ": statement : RETURN expression SEMICOLON" << gap;
            if(ret == NULL){
                yyerror("Return statement in global space");
            }else if(ret -> getName() != typeToString[($2) -> getValue() -> getType()]){
                yyerror("Return type mismatch");
            }
            $$ = mergeList($1, space(), $2, $3, newLine());
            logfile << ($$) << gap;
        } 
        | error {
            $$ = NULL;
            //deleteAll($1);
            //yyerror("Syntax Error");
        }
	  ;
	  
expression_statement : SEMICOLON {
            logfile << "Line " << yylineno << ": expression_statement : SEMICOLON" << gap;
            $$ = mergeList($1, newLine());
            logfile << ($$) << gap;
        } 	
        | expression SEMICOLON  {
            logfile << "Line " << yylineno << ": expression_statement : expression SEMICOLON" << gap;
            $$ = mergeList($1, $2, newLine());
            logfile << ($$) << gap;
        } 	
			;
	  
variable : ID {
            logfile << "Line " << yylineno << ": variable : ID" << gap;
            $$ = mergeList($1);
            $$ = variableCheck($$);
            logfile << ($$) << gap;
            
        } 	 		
        | ID LTHIRD expression RTHIRD {
            logfile << "Line " << yylineno << ": variable : ID LTHIRD expression RTHIRD" << gap;
            $$ = mergeList($1, $2, $3, $4);
            
            if(($3) -> getValue() -> getType() != Int){
                yyerror("Expression inside third brackets not an integer");
            }
            
            $$ = arrayCheck($$);
            logfile << ($$) << gap;
        } 	 		
	 ;
	 
 expression : logic_expression	{
            logfile << "Line " << yylineno << ": expression : logic_expression" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
	   | variable ASSIGNOP logic_expression {
            logfile << "Line " << yylineno << ": expression : variable ASSIGNOP logic_expression" << gap;
            //cerr << yylineno << ": " << ($3) -> getValue() -> getType() << endl;
            //cerr << yylineno << ": " << ($1) -> getValue() -> getType() << endl;
            if(($3) -> getValue() -> getType() == Void || ($1) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($1) -> getValue() -> setType(Unknown);
            }
            else if(($1) -> getValue() -> getType() == Float && ($3) -> getValue() -> getType() == Int || ($1) -> getValue() -> getType() == Unknown || ($3) -> getValue() -> getType() == Unknown ){
                ;
            }
            else if(($1) -> getValue() -> getType() != ($3) -> getValue() -> getType()){
                yyerror("Type Mismatch");
            }
            $$ = mergeList($1, $2, $3);
            logfile << ($$) << gap;
        } 	
	   ;
			
logic_expression : rel_expression 	{
            logfile << "Line " << yylineno << ": logic_expression : rel_expression" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        } 	
		 | rel_expression LOGICOP rel_expression {
            logfile << "Line " << yylineno << ": logic_expression : rel_expression LOGICOP rel_expression" << gap;
            if(($3) -> getValue() -> getType() == Void || ($1) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($1) -> getValue() -> setType(Unknown);
            }
            $$ = mergeList(emptyString("int"), $1, $2, $3);
            logfile << ($$) << gap;
        } 	
		 ;
			
rel_expression	: simple_expression {
            logfile << "Line " << yylineno << ": rel_expression : simple_expression" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        } 	
		| simple_expression RELOP simple_expression {
            logfile << "Line " << yylineno << ": rel_expression : simple_expression RELOP simple_expression" << gap;
            if(($3) -> getValue() -> getType() == Void || ($1) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($1) -> getValue() -> setType(Unknown);
            }
            $$ = mergeList(emptyString("int"), $1, $2, $3);
            logfile << ($$) << gap;
        }	
		;
				
simple_expression : term {
            logfile << "Line " << yylineno << ": simple_expression : term" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }	
        | simple_expression ADDOP term {
            logfile << "Line " << yylineno << ": simple_expression : simple_expression ADDOP term" << gap;
            if(($3) -> getValue() -> getType() == Void || ($1) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($1) -> getValue() -> setType(Unknown);
            }
            $$ = mergeList($1, $2, $3);
            if(($3) -> getValue() -> getType() == Float)($$) -> getValue() -> setType(Float);
            logfile << ($$) << gap;
        }	
		  ;
					
term :	unary_expression {
            logfile << "Line " << yylineno << ": term : unary_expression" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }	
        |  term MULOP unary_expression {
            logfile << "Line " << yylineno << ": term : term MULOP unary_expression" << gap;
            if(($3) -> getValue() -> getType() == Void || ($1) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($1) -> getValue() -> setType(Unknown);
            }
            if(($2) -> getName() == "%" && (($3) -> getValue() -> getType() != Int || ($1) -> getValue() -> getType() != Int)){
                yyerror("Non-Integer operand on modulus operator");
                ($1) -> getValue() -> setType(Unknown);
            }else if(($2) -> getName() == "%" && ($3) -> getName() == "0"){
                yyerror("Modulus by Zero");
                ($1) -> getValue() -> setType(Unknown);
            }else if(($2) -> getName() == "/" && ($3) -> getName() == "0"){
                yyerror("Divide by Zero");
                ($1) -> getValue() -> setType(Unknown);
            }else if(($3) -> getValue() -> getType() == Float){
                ($1) -> getValue() -> setType(Float);
            }
            $$ = mergeList($1, $2, $3);
            logfile << ($$) << gap;
        }
     ;

unary_expression : ADDOP unary_expression {
            logfile << "Line " << yylineno << ": unary_expression : ADDOP unary_expression" << gap;
            if(($2) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($2) -> getValue() -> setType(Unknown);
            }
            $$ = mergeList(emptyString(typeToString[($2) -> getValue() -> getType()]), $1, $2);
            logfile << ($$) << gap;
        }  
		 | NOT unary_expression  {
            logfile << "Line " << yylineno << ": unary_expression : NOT unary_expression" << gap;
            if(($2) -> getValue() -> getType() == Void){
                yyerror("Void function used in expression");
                ($2) -> getValue() -> setType(Unknown);
            }
            
            $$ = mergeList(emptyString(typeToString[($2) -> getValue() -> getType()]), $1, $2);
            logfile << ($$) << gap;
        }  
		 | factor {
            logfile << "Line " << yylineno << ": unary_expression : factor" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }  
		 ;
	
factor	: variable {
            logfile << "Line " << yylineno << ": factor : variable" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }  
        | ID LPAREN argument_list RPAREN {
            logfile << "Line " << yylineno << ": factor : ID LPAREN argument_list RPAREN" << gap;
            checkFuncCall($1, $3);
            $$ = mergeList(emptyString(getRet(($1) -> getName())), $1, $2, $3, $4);
            logfile << ($$) << gap;
        }  
        | LPAREN expression RPAREN {
            logfile << "Line " << yylineno << ": factor : LPAREN expression RPAREN" << gap;
            $$ = mergeList(emptyString(typeToString[($2) -> getValue() -> getType()]), $1, $2, $3);
            logfile << ($$) << gap;
        }  
        | CONST_INT  {
            logfile << "Line " << yylineno << ": factor : CONST_INT" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }  
        | CONST_FLOAT {
            logfile << "Line " << yylineno << ": factor : CONST_FLOAT" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }  
        | variable INCOP {
            logfile << "Line " << yylineno << ": factor : variable INCOP" << gap;
            $$ = mergeList($1, $2);
            logfile << ($$) << gap;
        }    
        | variable DECOP {
            logfile << "Line " << yylineno << ": factor : variable DECOP" << gap;
            $$ = mergeList($1, $2);
            logfile << ($$) << gap;
        }  
	;
	
argument_list : arguments {
            logfile << "Line " << yylineno << ": argument_list : arguments" << gap;
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }  
        | {
            logfile << "Line " << yylineno << ": argument_list : " << gap;
            $$ = NULL;
            logfile << ($$) << gap;
           
        }
        ;
	
arguments : arguments COMMA logic_expression {
            logfile << "Line " << yylineno << ": arguments : arguments COMMA logic_expression" << gap;
            ($3) -> getValue() -> setToken("ARG");
            $$ = mergeList($1, $2, $3);
            logfile << ($$) << gap;
        }
        | logic_expression {
            logfile << "Line " << yylineno << ": arguments : logic_expression" << gap;
            ($1) -> getValue() -> setToken("ARG");
            $$ = mergeList($1);
            logfile << ($$) << gap;
        }
        ;

%%
int main(int argc,char *argv[])
{
    FILE *fp;
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
    
    if(argc >= 4)err.open(argv[3], ios::out);
    else err.open("error.txt", ios::out);
    if(argc >= 3)logfile.open(argv[2], ios::out);
    else logfile.open("log.txt", ios::out);
    err.close();
    logfile.close();
    if(argc >= 4)err.open(argv[3], ios::app);
    else err.open("error.txt", ios::app);
    if(argc >= 3)logfile.open(argv[2], ios::app);
    else logfile.open("log.txt", ios::app);
    
    

	yyin=fp;
	yyparse();
	

    err.close();
    logfile.close();
	
	return 0;
}

