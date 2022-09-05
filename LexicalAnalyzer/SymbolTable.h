#include<string>
using namespace std;

class SymbolInfo{
    string name, type;
    SymbolInfo *next;

public:
    SymbolInfo(string name, string type){
        this -> name = name;
        this -> type = type;
        next = NULL;
    }
    string getName(){
        return name;
    }
    string getType(){
        return type;
    }
    SymbolInfo* getNext(){
        return next;
    }
    void setNext(SymbolInfo *next){
        this -> next = next;
    }

    
    ~SymbolInfo(){
        
    }
};

class ScopeTable{
    SymbolInfo **table;
    int totalBuckets, p;
    ScopeTable *parentScope;
    string id;
    unsigned long hash(string &str){
        unsigned long hash = 0;

        for(int i = 0; i < str.size(); i++)
                hash = str[i] + (hash << 6) + (hash << 16) - hash;
        return hash;
    }

public:
    ScopeTable(int totalBuckets){
        this -> totalBuckets = totalBuckets;
        p = 0;
        table = new SymbolInfo*[totalBuckets];
        for(int i = 0; i < totalBuckets; i++)
            table[i] = NULL;
        id = "1";
        parentScope = NULL;
    }

    string getId(){
        return id;
    }

    ScopeTable* getParentScope(){
        return parentScope;
    }

    void setParentScope(ScopeTable *parentScope){
        this -> parentScope = parentScope;
        if(parentScope == NULL){
            id = "1";
        }else{
            (parentScope -> p)++;
            id = parentScope -> getId() + "." + to_string(parentScope -> p);
        }
    }

    bool insert(string name, string type){
        int h = hash(name) % totalBuckets;

        if(table[h] == NULL){
            table[h] = new SymbolInfo(name, type);
            //cout << "Inserted in ScopeTable# " << id << " at position " << h << ", " << 0 << "\n";
        
            return true;
        }

        SymbolInfo* x = table[h];
        int cnt = 1;
        while(x -> getName() != name && x -> getNext() != NULL)
            x = x -> getNext(), cnt++;

        if(x -> getName() == name){
            //cout << "This word already exists\n";
            //cout << "< " << x ->getName() << ", " << x -> getType() << " > already exist in the currentScopeTable\n"; 
            return false;
        }
        x -> setNext(new SymbolInfo(name, type));
        
        //cout << "Inserted in ScopeTable# " << id << " at position " << h << ", " << cnt << "\n";
        return true;
    }

    SymbolInfo* lookUp(string name){
        int h = hash(name) % totalBuckets;
        SymbolInfo* x = table[h];
        int cnt = 0;
        while(x != NULL && x -> getName() != name)
            x = x -> getNext(), cnt++;
        
        //if(x != NULL)
            //cout << "Found in ScopeTable# " << id << " at position " << h << ", " << cnt << "\n";
        return x;
    }

    bool Delete(string name){
        int h = hash(name) % totalBuckets;
        SymbolInfo *x = table[h], *y = NULL;
        int cnt = 0;
        while(x != NULL && x -> getName() != name)
            y = x, x = x -> getNext(), cnt++;
        
        if(x == NULL){
            //cout << name << " is not found\n";
            return false;
        }

        //cout << "Deleted entry at " << h << ", " << cnt << " in the current scopetable\n";
        if(y == NULL){
            table[h] = x -> getNext();
        }else{
            y -> setNext(x -> getNext());
        }

        delete x;
        return true;
    }

    void print(ostream &logfile){
        logfile << "Scopetable# " << id << "\n";
        for(int i = 0; i < totalBuckets; i++){
            SymbolInfo *x = table[i];
            if(x == NULL)continue;
            logfile << i << " --> ";
            while(x != NULL){
                logfile << "< " << x -> getName() << " : " << x -> getType() << " >";
                x = x -> getNext();
            }
            logfile << "\n";
        }
    }

    ~ScopeTable(){
        //cout << "Destroying the ScopeTable\n";
        SymbolInfo *temp;
        for(int i = 0; i < totalBuckets; i++){
            while(table[i] != NULL){
                temp = table[i];
                table[i] = table[i] -> getNext();
                delete temp;
            }
        }
        delete [] table;
    }

};

class SymbolTable{
    ScopeTable *currentScopeTable;
    int totalBuckets;
public:
    SymbolTable(int totalBuckets){
        currentScopeTable = NULL;
        this -> totalBuckets = totalBuckets;
    }
    
    void enterScope(){
        ScopeTable *temp = new ScopeTable(totalBuckets);
        temp -> setParentScope(currentScopeTable);
        currentScopeTable = temp;
        //cout << "New ScopeTable with id# " << currentScopeTable -> getId() << " is created\n"; 
    }

    void exitScope(){
        if(currentScopeTable == NULL){
            //cout << "NO CURRENT SCOPE\n";
            return;
        }
        //cout << "ScopeTable with id " << currentScopeTable -> getId() << " is removed\n";
        ScopeTable *temp = currentScopeTable;
        currentScopeTable = currentScopeTable -> getParentScope();
        delete temp;
    }

    bool insert(string name, string type){
        if(currentScopeTable == NULL)enterScope();
        return currentScopeTable -> insert(name, type);
    }

    bool remove(string name){
        if(currentScopeTable == NULL)return false;
        return currentScopeTable -> Delete(name);
    }

    SymbolInfo* lookUp(string name){
        ScopeTable *temp = currentScopeTable;
        while(temp != NULL){
            SymbolInfo *x = temp -> lookUp(name);
            if(x != NULL)return x;
            temp = temp -> getParentScope();
        }
        //cout << "Not Found\n";
        return NULL;
    }

    void printCurrentScopeTable(ostream &logfile){
        if(currentScopeTable != NULL){
            currentScopeTable -> print(logfile);
        }
    }

    void printAllScopeTable(ostream &logfile){
        ScopeTable *temp = currentScopeTable;
        while(temp != NULL){
            temp -> print(logfile);
            temp = temp -> getParentScope();
            logfile << "\n";
        }
    }

    ~SymbolTable(){
        ScopeTable *temp = currentScopeTable;
        ScopeTable *x;
        while(temp != NULL){
            x = temp -> getParentScope();
            delete temp;
            temp = x;
        }
    }
};
