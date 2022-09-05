
vector<string> allLines;
vector<vector<string>> parsedLines;
map<string, vector<int>> labelcall;
map<string, int>  labelpos;
string op = ";;;;;;;;;;;;;;;;;;  optimized       ";

vector<string> stringTokenize(string s, string delim){
    string token;
    vector<string> ret;
    for(auto x : s){
        if(delim.find(x) < delim.size()){
            if(!token.empty())ret.push_back(token);
            token.clear();
            continue;
        }
        token += x;
    }

    if(!token.empty())ret.push_back(token);
    return ret;
}


void removeLine(int i){

    //remove i
    allLines[i] = op + allLines[i];
    parsedLines[i][0] = op;
}


bool noInstructionBetween(int a, int b){
    while(a <= b){
        if(parsedLines[a][0][0] != ';')return false;
        a++;
    }
    return true;
}


void changeLabel(vector<int> &lines, string newLabel, string oldLabel){
    int l = oldLabel.size();
    for(auto x : lines){
        int y = l;
        while(allLines[x].back() == ' ')allLines[x].pop_back();
        while(y--)allLines[x].pop_back();
        allLines[x] += newLabel;
    }
}
void optimizer(ifstream &mainCode, ofstream &optimizedCode){
    while(!mainCode.eof()){
        string s;
        getline(mainCode, s);
        if(s.empty())s = ";";
        allLines.push_back(s);

        parsedLines.push_back(stringTokenize(s, " \n\r,"));
        assert(parsedLines.back().size() != 0);
    }

    int n = allLines.size();

    int code = 0;
    while(code < n && parsedLines[code][0] != ".CODE")code++;




    //REMOVE ADD  , 0 SUB , 0   //xor or
    for(int i = code + 1; i < n; i++){
        if(parsedLines[i][0][0] == ';')continue;
        if(parsedLines[i][0] == "ADD" || parsedLines[i][0] == "SUB"){
            if(parsedLines[i].back() == "0"){
                removeLine(i);
            }
        }

    }



    //MOV AX, BX
    //MOV BX, AX
    int last = code + 1;
    while(++last < n && allLines[last][0] == ';');


    for(int i = last + 1; i < n; i++){
        if(parsedLines[i][0][0] == ';')continue;
        if(parsedLines[i][0] != "MOV" || parsedLines[last][0] != "MOV"){
            last = i;
            continue;
        }


        if(parsedLines[last][1] == parsedLines[i][1]){
            if(parsedLines[last].back() == parsedLines[i].back()){
                //same
                removeLine(i);
                continue;
            }
        }else if(parsedLines[last].back() == parsedLines[i][1]){
            if(parsedLines[last][1] == parsedLines[i].back()){
                //almost same
                removeLine(i);
                continue;

            }
        }

        last = i;

    }

    //PUSH BX
    //POP BX
    last = code + 1;
    while(last < n && allLines[last][0] == ';')last++;


    for(int i = last + 1; i < n; i++){
        if(parsedLines[i][0][0] == ';')continue;
        if(parsedLines[i][0] != "POP" || parsedLines[last][0] != "PUSH"){
            last = i;

            continue;
        }


        if(parsedLines[last][1] == parsedLines[i][1]){
            //same
            removeLine(last);
            removeLine(i);

            while(last < n && allLines[last][0] == ';')last++;
            i = last;
            continue;
        }
//        else {
//            string m1 = parsedLines[last][1];
//            string m2 = parsedLines[i][1];
//            removeLine(last);
//            allLines[last] += " ;";
//            allLines[last] += allLines[i];
//            allLines[i] = "MOV " + m1 + ", " + m2;
//            parsedLines[i] = stringTokenize(allLines[i], " \n\r,");
//        }

        last = i;

    }


    for(int i = code + 1; i < n; i++){
        if(parsedLines[i][0][0] == ';')continue;
        if(toupper(parsedLines[i][0][0]) == 'J'){
            //jump
            labelcall[parsedLines[i].back()].push_back(i);
        }else {
            if(parsedLines[i].size() == 1 && parsedLines[i][0].back() == ':')
                labelpos[parsedLines[i][0].substr(0, parsedLines[i][0].size() - 1)] = i;
        }
    }


    //jump to next instruction //or no call

    for(auto x : labelpos){
        if(labelcall[x.first].size() == 0){
            //noCall
            removeLine(x.second);
        }else{
            int t = x.second;
            t--;
            for(int i = labelcall[x.first].size() - 1; i >= 0; i--){
                if(labelcall[x.first][i] != t){
                    t = -2;
                    break;
                }
                t--;
            }
            if(t != -2){
                for(auto x : labelcall[x.first]){
                    removeLine(x);
                }
                removeLine(x.second);
            }
        }
    }



    vector<pair<int, string>> allLabels;

    for(auto x : labelpos){
        if(allLines[x.second][0] != ';'){
            allLabels.emplace_back(x.second, x.first);
        }
    }

    sort(allLabels.begin(), allLabels.end());

    for(int i = 1; i < allLabels.size(); i++){
        if(noInstructionBetween(allLabels[i - 1].first + 1, allLabels[i].first - 1)){
            //remove label i - 1 a
            removeLine(allLabels[i - 1].first);
            changeLabel(labelcall[allLabels[i - 1].second], allLabels[i].second, allLabels[i - 1].second);
        }
    }



    for(auto x : allLines){
        optimizedCode << x << "\n";
    }



}
