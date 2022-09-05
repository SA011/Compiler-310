SymbolInfo* space(){
    return new SymbolInfo(" ", "SPACE");
}
SymbolInfo* newLine(){
    return new SymbolInfo("\n", "NEWLINE");
}



void writeInFile(string s, bool endline = true, int position = -1){
    //asm file er position s print hobe
    if(endline){
        //if(currentFunctionStackPosition == 0)s += "\n";
        //else s += "; ", s += to_string(currentFunctionStackPosition), s += "\n";
        s += "\n";
    }
    if(position == -1){
        //add at the end
        asmCode << s;
        asmCode.flush();
        return;
    }
    
    asmCode.seekp(position, ios_base :: beg);
    
    asmCode << s;
    asmCode.flush();
    asmCode.seekp(0, ios_base :: end);
}


void writeComment(string s){
    writeInFile(";" + s);
}




void println(){
    ifstream fin("print.asm");
    string s;
    while(!fin.eof()){
        getline(fin, s);
        writeInFile(s);
    }
}

void printStarting(){
    writeInFile(".MODEL SMALL");
    writeInFile(".STACK 4000H");
    writeInFile(".DATA");
    writeInFile("MEM DW ", false);
    memSizePointer = asmCode.tellp();
    curMemSize = 1;
    writeInFile("1         DUP(0000H)");
    writeInFile(".CODE");
    println();
}
void loadIdAddressInCX(SymbolInfo *id){
    writeComment("Loading variable " + id -> getName() + " in CX");
    auto temp = symbols.lookUp(id -> getName());
    if(temp == NULL)return;
    if(symbols.isSymbolInGlobal(id -> getName())){
        writeInFile("LEA CX, MEM");
        writeInFile("ADD CX, " + to_string(temp -> getValue() -> getAddress()));
    }else{
        writeInFile("MOV CX, SP");
        if(currentFunctionStackPosition == temp -> getValue() -> getAddress())return;
        writeInFile("ADD CX, " + to_string(currentFunctionStackPosition));
        writeInFile("SUB CX, " + to_string(temp -> getValue() -> getAddress()));
    }
}
void callPrintln(SymbolInfo *id){
    writeComment("Printing value");
    loadIdAddressInCX(id);
    //writeInFile("PUSH BP");
    writeInFile("MOV BP, CX");
    writeInFile("MOV CX, PTR WORD [BP]");
    //writeInFile("POP BP");
    writeInFile("PUSH CX");
    writeInFile("CALL PRINTLN_BUILTIN");
}

void printEnding(){
    writeComment("Ending program");
    writeInFile("END MAIN");
    if(error_count){
        asmCode.close();
        asmCode.open("code.asm", ios::out);
    }
}

ostream& operator<<(ostream &stream, SymbolInfo *p){
    if(p != NULL){
        stream << (p -> getName());
        stream << (p -> getNext());
    }
    return stream;
}
SymbolInfo* mergeList(SymbolInfo* l){
    return l;
}
template<class... T>
SymbolInfo* mergeList(SymbolInfo* l, T... r){
    if(l == NULL)return mergeList(r...);
    SymbolInfo *ret = l;
    while(l -> getNext() != NULL)l = l -> getNext();
    l -> setNext(mergeList(r...));
    return ret;
}

SymbolInfo* emptyString(string type){
    return new SymbolInfo("", "", type);
}

void deleteAll(SymbolInfo *s){
    if(s == NULL)return;
    deleteAll(s -> getNext());
    delete s;
}

string getRet(string name){
    SymbolInfo *ase = symbols.lookUp(name);
    if(ase == NULL || ase -> getValue() -> getType() != Func && ase -> getValue() -> getType() != Undefined_Func)
        return "unknown";
    //cerr << yylineno << ": "  << typeToString[*(ase -> getValue() -> getParameterList()).begin()] << endl;
    return typeToString[*(ase -> getValue() -> getParameterList()).begin()];
}


bool isSame(list<Type> l1, list<Type> l2, string name){
    if(*l1.begin() != *l2.begin()){
        yyerror(string("Return type mismatch with function declaration in function ") + name);
    }
    if(l1.size() != l2.size()){
        yyerror(string("Total number of arguments mismatch with declaration in function ") + name);
            return false;
    }
    list<Type> :: iterator p1 = ++l1.begin();
    list<Type> :: iterator p2 = ++l2.begin();
    while(p1 != l1.end() && p2 != l2.end()){
        if(*p1 != *p2){
            yyerror(string("Parameter type mismatch in function ") + name);
            return false;
        }
        p1++;
        p2++;
    }
    return true;
}


void insertIntoTable(SymbolInfo *temp){
    //cerr << temp -> getName() << endl;
    if(symbols.insert(temp))return;
    //cerr << "KI" << temp -> getName() << endl;
    SymbolInfo *ase = symbols.lookUp(temp -> getName());
    //cerr << "EKHANE?" << endl;
    if(ase == NULL)return; //eita shudhu shudhu korlam
    //cerr << "ASHSE" << temp -> getName() << endl;
    Type t = temp -> getValue() -> getType();
    if(t == Func){
        if(ase -> getValue() -> getType() == Undefined_Func){
            //age declared, ekhon defined //baki jinish match kora lagbe
            if(isSame(temp -> getValue() -> getParameterList(), ase -> getValue() -> getParameterList(), temp -> getName())){
                //shob thik ase
                symbols.remove(temp -> getName());
                symbols.insert(temp);
                return;
            }
            delete temp;
            //baki jinish match kore nai
            return;
        }
        yyerror(string("Multiple definition of ") + temp -> getName());
        delete temp;
        return;
    }
    
    yyerror(string("Multiple declaration of ") + temp -> getName());
    delete temp;
}


void pushFunction(SymbolInfo *id, SymbolInfo *ret, SymbolInfo *param, string typ){
    bool defined = (typ == "func");
    SymbolInfo *temp = new SymbolInfo(id -> getName(), "ID", typ);
    //cerr << id -> getName() << ' ' << ret -> getName() << endl;
    temp -> getValue() -> addParam(ret -> getName());
    SymbolInfo *t = param;
    int cnt = 0;
    while(t){
        if(t -> getName() == "," || t -> getName() == " " || t -> getValue() -> getToken() == "ID"){
            t = t -> getNext();
            continue;
        }
        temp -> getValue() -> addParam(t -> getName());
        cnt++;
        t = t -> getNext();
        if(defined && (t == NULL || t -> getName() != " ")){
            yyerror(to_string(cnt) + string("th parameter's name not given in function definition of ") + id -> getName());
        }
    }
    insertIntoTable(temp);
    
    if(defined){
        writeComment("Function declaration of " + id -> getName());
        writeInFile(id -> getName() + " PROC");
        if(id -> getName() == "main"){
            writeInFile("MOV AX, @DATA");
            writeInFile("MOV DS, AX");
        }
        //writeInFile("PUSH BP");
        //writeInFile("MOV BP, SP");
    }
    
    
    symbols.enterScope();
    notunScope = true;
    t = param;
    string lastSpec;
    int cur = cnt * 2;
    if(defined)currentFunctionStackPosition = 0;
    while(t){
        if(t -> getName() == "," || t -> getName() == " "){
            t = t -> getNext();
            continue;
        }
        if(t -> getValue() -> getToken() != "ID"){
            lastSpec = t -> getName();
            t = t -> getNext();
            continue;
        }
        if(!symbols.insert(new SymbolInfo(t -> getName(), "ID", lastSpec, -cur))){
            yyerror(string("Multiple declaration of ") + t -> getName() + string(" in parameter"));
        }
        t = t -> getNext();
        cur -= 2;
    }
}

void endFunction(SymbolInfo *id){
    writeComment("Ending Function " + id -> getName());
    SymbolInfo *temp = symbols.lookUp(id -> getName());
    if(temp == NULL)return;
    writeInFile("ADD SP, " + to_string(currentFunctionStackPosition));
    //writeInFile("POP BP");
    writeInFile("POP AX");
    writeInFile("PUSH CX");
    writeInFile("PUSH AX");
    if(id -> getName() == "main"){
        writeInFile("MOV AH, 4CH");
        writeInFile("INT 21H");
    }
    writeInFile("RET");
    writeInFile("ENDP " + id -> getName());
}

void addVar(SymbolInfo *id, int varSize = 1){
    if(!symbols.isGlobalScope()){
        currentFunctionStackPosition += 2 * varSize;
        id -> getValue() -> setAddress(currentFunctionStackPosition);
        writeInFile("SUB SP, " + to_string(2 * varSize));
    }else{
        id -> getValue() -> setAddress(curMemSize * 2);
        curMemSize += varSize;
        writeInFile(to_string(curMemSize), false, memSizePointer);
    }
}

void pushVariables(SymbolInfo *type, SymbolInfo *id){
    if(type -> getName() == "void"){
        yyerror("Variable type cannot be void");
        return;
    }
    while(id){
        if(id -> getName() == ","){
            id = id -> getNext();
        }
        
        
        if(id -> getNext() != NULL && id -> getNext() -> getName() == "["){
            //array
            SymbolInfo *temp = new SymbolInfo(id -> getName(), "ID", "array", id -> getValue() -> getAddress());
            temp -> getValue() -> addParam(type -> getName());
            id = id -> getNext() -> getNext();
            temp -> getValue() -> addParam(id -> getName());
            id = id -> getNext();
            insertIntoTable(temp);
        }else{
            //normal var
            insertIntoTable(new SymbolInfo(id -> getName(), "ID", type -> getName(), id -> getValue() -> getAddress()));
        }
        id = id -> getNext();
    }
}


SymbolInfo *variableCheck(SymbolInfo *id){
    SymbolInfo *ase = symbols.lookUp(id -> getName());
    if(ase == NULL){
        //nai
        yyerror(string("Undeclared variable ") + (id -> getName()));
        return id;
    }
    Type type = ase -> getValue() -> getType();
    if(type == Func || type == Undefined_Func || type == Array){
        yyerror(string("Type mismatch ") + id -> getName() + string(" is a ") + typeToString[type]);
        return id;
    }
    id -> getValue() -> setType(type);
    return id;
}

SymbolInfo *arrayCheck(SymbolInfo *id){
    SymbolInfo *ase = symbols.lookUp(id -> getName());
    if(ase == NULL){
        //nai
        yyerror(string("Undeclared variable ") + (id -> getName()));
        return id;
    }
    Type type = ase -> getValue() -> getType();
    if(type != Array){
        yyerror(string("Type mismatch ") + id -> getName() + string(" is a ") + typeToString[type]);
        return id;
    }
    id -> getValue() -> setType(*(ase -> getValue() -> getParameterList()).begin());
    return id;
}

int newTemp(){
    writeComment("Creating New Temporary Variable");
    writeInFile("PUSH CX");
    currentFunctionStackPosition += 2;
    return currentFunctionStackPosition;
}

int delTemp(){
    writeComment("Deleting Temporary Variable");
    writeInFile("ADD SP, 2");
    currentFunctionStackPosition -= 2;
    return currentFunctionStackPosition;
}

void checkFuncCall(SymbolInfo *id, SymbolInfo *args){
    SymbolInfo *ase = symbols.lookUp(id -> getName());
    if(ase == NULL){
        yyerror(string("Undeclared function call ") + (id -> getName()));
        return;
    }
    Type type = ase -> getValue() -> getType();
    if(type != Undefined_Func && type != Func){
        yyerror(string("Type mismatch ") + id -> getName() + string(" is a ") + typeToString[type]);
        return;
    }
    
    list<Type> params = ase -> getValue() -> getParameterList();
    list<Type>::iterator it = ++params.begin();
    int cnt = 1;
    while(it != params.end()){
        if(args == NULL)break;
        if(args -> getValue() -> getToken() != "ARG"){
            args = args -> getNext();
            continue;
        }
        if(*it == Float && args -> getValue() -> getType() == Int){
            ;
        }
        else if(*it != args -> getValue() -> getType()){
            yyerror(to_string(cnt) + string("th argument mismatch in function ") + id -> getName());
        }
        delTemp();
        cnt++;
        it++;
        args = args -> getNext();
    }
    while(args != NULL && args -> getValue() -> getToken() != "ARG")args = args -> getNext();
    if(it != params.end() || args != NULL){
        yyerror(string("Total number of arguments mismatch in function ") + id -> getName());
    }
}

void pop(SymbolInfo *l){
    if(l == NULL || l -> getNext() == NULL)return;
    while(l -> getNext() -> getNext() != NULL)l = l -> getNext();
    if(l -> getNext() -> getName() == "\n"){
        deleteAll(l -> getNext());
        l -> setNext(NULL);
    }
}

void backPatch(list<int> &l, string label){
    for(int x : l)
        writeInFile(label, false, x);
    l.clear();
}

string newLabel(){
    return "L" + to_string(labelCount++);
}


void checkBackPatch(SymbolInfo *s, int i = 1){
    list<int>& temp = s -> getValue() -> getRefList(i);
    if(!temp.empty()){
        string label = newLabel();
        backPatch(temp, label);
        writeInFile(label + ":");
    }
}

void checkNoBackPatch(SymbolInfo *s){
    if(s -> getValue() -> getRefList(0).empty() && s -> getValue() -> getRefList(1).empty()){
        writeInFile("JCXZ ", false);
        s -> getValue() -> addListElement(0, asmCode.tellp());
        writeInFile(labelgap);
        writeInFile("JMP ", false);
        s -> getValue() -> addListElement(1, asmCode.tellp());
        writeInFile(labelgap);
    }
    
}




