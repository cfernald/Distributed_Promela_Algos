
#define N 5
#define MAX_REQS 10000

chan blocking[N] = [0] of {bit};
chan request = [N] of {byte};
chan release = [0] of {bit};
int inCS = 0;
int totCS = 0;

proctype monitor() {
    do
        :: assert(inCS <= 1);
    od
}

init {
    atomic {
        //run monitor();
        run central();
        run server(0);
        run server(1);
        run server(2);
        run server(3);
        run server(4);
    }
}

proctype central() {
    int ppid = 0;
    do
        :: skip
end:    request ? ppid;
        atomic { 
            blocking[ppid] ? 1;
            release ! 1;
            inCS = inCS - 1; 
        }
    od
}

proctype server(int i) {
    int req = 0;
    do
        :: skip
        request ! i;
        req = req + 1;
        blocking[i] ! 1;
        inCS = inCS + 1;
        totCS = totCS + 1;
        release ? 1;
        if :: (req >= MAX_REQS) -> break           
           :: (req < MAX_REQS) -> skip
        fi
    od
}
