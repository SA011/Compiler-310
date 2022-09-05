%option noyywrap
%option yylineno

%x CHAR_LITERAL
%x STRING_LITERAL
%x SINGLE_COMMENT
%x MULTI_COMMENT

%{
#include<bits/stdc++.h>
using namespace std;

enum Type{
     Unknown = 0, Int, Double, Float,  Char, Func
};


extern string *typeToString;
extern map<string, Type> stringToType;
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*
#include "y.tab.h"

extern int error_count, line_count;

string temp, temp2;
extern ofstream err, logfile;
#define EN "\n\n"
extern SymbolTable symbols;


string toUp(string s){
    for(char &c : s)c = toupper(c);
    return s;
}

%}


KEYWORD (if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue)
%%



([ \t\n\r])+                {}

if        {yylval = new SymbolInfo("if", "KEYWORD"); return IF;}
else      {yylval = new SymbolInfo("else", "KEYWORD"); return ELSE;}
for       {yylval = new SymbolInfo("for", "KEYWORD"); return FOR;}
while     {yylval = new SymbolInfo("while", "KEYWORD"); return WHILE;}
do        {yylval = new SymbolInfo("do", "KEYWORD"); return DO;}
break     {yylval = new SymbolInfo("break", "KEYWORD"); return BREAK;}
int       {yylval = new SymbolInfo("int", "KEYWORD"); return INT;}
char      {yylval = new SymbolInfo("char", "KEYWORD"); return CHAR;}
float     {yylval = new SymbolInfo("float", "KEYWORD"); return FLOAT;}
double    {yylval = new SymbolInfo("double", "KEYWORD"); return DOUBLE;}
void      {yylval = new SymbolInfo("void", "KEYWORD"); return VOID;}
return    {yylval = new SymbolInfo("return", "KEYWORD"); return RETURN;}
switch    {yylval = new SymbolInfo("switch", "KEYWORD"); return SWITCH;}
case      {yylval = new SymbolInfo("case", "KEYWORD"); return CASE;}
default   {yylval = new SymbolInfo("default", "KEYWORD"); return DEFAULT;}
continue  {yylval = new SymbolInfo("continue", "KEYWORD"); return CONTINUE;}
printf  {yylval = new SymbolInfo("printf", "KEYWORD"); return PRINTLN;}
println  {yylval = new SymbolInfo("printf", "KEYWORD"); return PRINTLN;}

[\']                    {
                            temp2.clear();
                            temp.clear();
                            line_count = yylineno;
                            BEGIN CHAR_LITERAL;
                        }



<CHAR_LITERAL>[\\](.)   {
                            temp2 += yytext;
                            switch(yytext[1]){
                                case 'n':
                                    temp += '\n';
                                    break;
                                case 't':
                                    temp += '\t';
                                    break;
                                case '\\':
                                    temp += '\\';
                                    break;
                                case '\'':
                                    temp += '\'';
                                    break;
                                case '\"':
                                    temp += '\"';
                                    break;
                                case 'a':
                                    temp += '\a';
                                    break;
                                case 'f':
                                    temp += '\f';
                                    break;
                                case 'r':
                                    temp += '\r';
                                    break;
                                case 'b':
                                    temp += '\b';
                                    break;
                                case 'v':
                                    temp += '\v';
                                    break;
                                case '0':
                                    temp += '\0';
                                    break;
                                default:
                                    temp += yytext[1];
                            }
                        }
                                                
<CHAR_LITERAL>[\']      {
                            if(temp.empty()){
                                err << "Error at line no " << yylineno << ": Empty character constant error ''" << EN;
                                error_count++;
                                return ERROR;
                            }else if(temp.size() > 1){
                                err << "Error at line no " << yylineno << ": Multi character constant error '" << temp2 << "'" << EN;
                                error_count++;
                                return ERROR;
                            }else{
                                yylval = new SymbolInfo(temp, "CONST_CHAR", "char");
                                return CONST_CHAR;
                            }
                            BEGIN INITIAL;
                        }
<CHAR_LITERAL>[\n]      {
                            err << "Error at line no " << line_count << ": Unterminated character '" << temp2 << EN;
                            error_count++;
                            return ERROR;
                        }
<CHAR_LITERAL><<EOF>>   {
                            err << "Error at line no " << line_count << ": Unterminated character '" << temp2 << EN;
                            error_count++;
                            return ERROR;
                        }
<CHAR_LITERAL>.         {
                            temp2 += yytext;
                            temp += yytext;
                        }
                        
[+-]                    {
                            yylval = new SymbolInfo(yytext, "ADDOP");
                            return ADDOP;
                        }
                        
                        
[*/%]                   {
                            yylval = new SymbolInfo(yytext, "MULOP");
                            return MULOP;
                        }
                        
[+]{2}                 {
                            yylval = new SymbolInfo(yytext, "INCOP");
                            return INCOP;
                        }
                        
[-]{2}                 {
                            yylval = new SymbolInfo(yytext, "DECOP");
                            return DECOP;
                        }
                        
([><][=]?)|((!|=)[=])   {
                            yylval = new SymbolInfo(yytext, "RELOP");
                            return RELOP;
                        }
                    
                        
[=]                     {
                            yylval = new SymbolInfo(yytext, "ASSIGNOP");
                            return ASSIGNOP;
                        }
                                                
[&]{2}|[|]{2}           {
                            yylval = new SymbolInfo(yytext, "LOGICOP");
                            return LOGICOP;
                        }
                        
                                                
[!]                     {
                            yylval = new SymbolInfo(yytext, "NOT");
                            return NOT;
                        }
                        
                                                
[(]                     {
                            yylval = new SymbolInfo(yytext, "LPAREN");
                            return LPAREN;
                        }
                        
                                                
[)]                     {
                            yylval = new SymbolInfo(yytext, "RPAREN");
                            return RPAREN;
                        }
                        
                                                
[{]                     {
                            yylval = new SymbolInfo(yytext, "LCURL");
                            return LCURL;
                        }
                        
                                                
[}]                     {
                            yylval = new SymbolInfo(yytext, "RCURL");
                            return RCURL;
                        }
                        
    
[[]                     {
                            yylval = new SymbolInfo(yytext, "LTHIRD");
                            return LTHIRD;
                        }
                        
                                                
[]]                     {
                            yylval = new SymbolInfo(yytext, "RTHIRD");
                            return RTHIRD;
                        }
                        
                                                
[,]                     {
                            yylval = new SymbolInfo(yytext, "COMMA");
                            return COMMA;
                        }
                        
                                                
[;]                     {
                            yylval = new SymbolInfo(yytext, "SEMICOLON");
                            return SEMICOLON;
                        }
                        
[A-Za-z_][A-Za-z0-9_]*   {
                            yylval = new SymbolInfo(yytext, "ID");
                            return ID;
                        }
[0-9]+                  {
                            yylval = new SymbolInfo(yytext, "CONST_INT", "int");
                            return CONST_INT;
                        }                        

(([0-9]+)([.][0-9]+)?(E[+-]?[0-9]+)?)|([.][0-9]+(E[+-]?[0-9]+)) {
                            yylval = new SymbolInfo(yytext, "CONST_FLOAT", "float");
                            return CONST_FLOAT;
                        }                
                        


(([0-9]*)[.]([0-9]*)(([.][0-9]*)+)(E[+-]?[0-9]+)?) {
                            err << "Error at line no " << yylineno << ": Too many decimal points " << yytext << EN;
                            error_count++;
                            return ERROR;
                        }                        
                        

                        
(([0-9]+)([.][0-9]+)?(E[+-]?([0-9]*)([.][0-9]*)+)+)|([.]([0-9]+)(E[+-]?([0-9]*)([.][0-9]*)+)+) {                        
                            err << "Error at line no " << yylineno << ": Ill formated number " << yytext << EN;
                            error_count++;
                            return ERROR;
                        }  
([0-9]+)[A-Za-z_][A-Za-z0-9_]* {
                            err << "Error at line no " << yylineno << ": Invalid prefix on ID or invalid suffix on Number " << yytext << EN;
                            error_count++;
                            return ERROR;
                        }
                        
["]                     {
                            temp2.clear();
                            temp.clear();
                            line_count = yylineno;
                            BEGIN STRING_LITERAL;
                        }                        
                        
<STRING_LITERAL>[^\\^\"^\n]+ {
                            temp2 += yytext;
                            temp += yytext;
                        }
                        
<STRING_LITERAL>[\\][\r]?[\n]    {
                                temp2 += yytext;
                            }
<STRING_LITERAL>[\\](.) {
                            temp2 += yytext;
                            switch(yytext[1]){
                                case 'n':
                                    temp += '\n';
                                    break;
                                case 't':
                                    temp += '\t';
                                    break;
                                case '\\':
                                    temp += '\\';
                                    break;
                                case '\"':
                                    temp += '\"';
                                    break;
                                case '\'':
                                    temp += '\'';
                                    break;
                                case 'a':
                                    temp += '\a';
                                    break;
                                case 'f':
                                    temp += '\f';
                                    break;
                                case 'r':
                                    temp += '\r';
                                    break;
                                case 'b':
                                    temp += '\b';
                                    break;
                                case 'v':
                                    temp += '\v';
                                    break;
                                case '0':
                                    temp += '\0';
                                    break;
                                default:
                                    temp += yytext;
                            }
                        }
<STRING_LITERAL>[\n]    {
                            err << "Error at line no " << line_count << ": Unterminated string \"" << temp2 << EN;
                            error_count++;
                            return ERROR;
                        }
<STRING_LITERAL><<EOF>> {
                            err << "Error at line no " << line_count << ": Unterminated string \"" << temp2 << EN;
                            error_count++;
                            return ERROR;
                        }
<STRING_LITERAL>[\"]    {
                            yylval = new SymbolInfo(temp, "STRING");
                            return STRING;
                        }

[/][/]                {
                            temp2 = yytext;
                            line_count = yylineno;
                            BEGIN SINGLE_COMMENT;
                        }
<SINGLE_COMMENT>([\\][\r]?[\n]|.)+ {
                        
                            temp2 += yytext;
                        }
                        
<SINGLE_COMMENT>[\n] {
                        BEGIN INITIAL;
                    }
                        
<SINGLE_COMMENT><<EOF>> {
                        BEGIN INITIAL;
                            
                    }

[/][*]              {
                        temp2 = yytext;
                        line_count = yylineno;
                        BEGIN MULTI_COMMENT;
                    }
                    
<MULTI_COMMENT>[^*] {
                        temp2 += yytext;
                    }
                    
<MULTI_COMMENT>[*][^/] {
                        temp2 += yytext;
                    }
                    
<MULTI_COMMENT>[*][/] {
                        temp2 += yytext;
                        BEGIN INITIAL;
                            
                    }
<MULTI_COMMENT><<EOF>> {
                            err << "Error at line no " << line_count << ": Unterminated comment " << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<<EOF>>             {return 0;}

.                   {
                        err << "Error at line no " << yylineno << ": Unrecognized character " << yytext << EN;
                        error_count++;
                    }
            

%%

                          
