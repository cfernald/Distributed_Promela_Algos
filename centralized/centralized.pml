
#define N 5
#define MAX_REQS 3

chan blocking[N] = [0] of {bit};
chan request = [N] of {byte};
chan release = [0] of {bit};
int inCS = 0;
int totCS = 0;

init {
    atomic {
        run central();
        int i;
        for (i : 0 .. N - 1) {
            run server(i);
        }
    }
}

proctype central() {
    int ppid = 0; 
end: do
        :: request ? ppid;
        atomic { 
            blocking[ppid] ? 1;
            release ! 1;
            inCS = inCS - 1;
            assert (inCS == 0); 
        }
    od
}

proctype server(int i) {
    int req = 0;
    do
        :: request ! i;
        req = req + 1;
        blocking[i] ! 1;
        atomic {
            inCS = inCS + 1;
            assert (inCS == 1);
        }
        totCS = totCS + 1;
        release ? 1;
        if :: (req >= MAX_REQS) -> break           
           :: (req < MAX_REQS) -> skip
        fi
    od
}
