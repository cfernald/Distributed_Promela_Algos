
#define N 5
#define MAX_REQS 10

#define TS_MULT 100

chan requests[N] = [N] of {int};
int acks[N];
int inCS = 0;
//int totCS = 0;

init {
    int i;
    atomic {
    for (i : 0 .. N - 1) {
        run server(i);
        acks[i] = 0;
    }
    }
}

proctype server(int p) {
    int ts = 0;
    bool imInCS = false;
    int i;
    int reqTS = 0;
    bool requested = false;
    int front;
    int reqs = 0;

    do
        :: !(imInCS) -> 

        if 
            :: (!requested) ->
                // send requests
                reqTS = (TS_MULT * ts) + p
                for (i : 0 .. N-1) {
                    requests[i] !! reqTS;
                }
                ts = ts + 1;
                requested = true;
            :: else -> skip;
        fi

        if
            :: requests[p] ? front ->
                if
                    ::  (front % TS_MULT == p)->
                        requests[p] !! front;
                    ::  else ->
                        int frontPid = front % TS_MULT;
                        int frontTS = front / TS_MULT;
                        ts = ((frontTS > ts) -> frontTS : ts);
                        ts = ts + 1;
                        atomic { acks[frontPid] = acks[frontPid] + 1; }
                fi
            :: else -> skip;
        fi

        if
            :: (acks[p] == N - 1) ->
                imInCS = true;
                requested = false;
                acks[p] = 0;
                inCS = inCS + 1;
                assert (inCS == 1);
            :: else -> skip;  
        fi
        
        :: (imInCS) ->
            if 
                ::  atomic {
                    imInCS = false;
                    inCS = inCS - 1;
                    assert (inCS == 0);
                }
                requests[p] ? front;
progress2:      assert (front % TS_MULT == p);
                reqs = reqs + 1;
            fi
            if  :: reqs >= MAX_REQS ->
                    break;
                :: else -> skip;
            fi
    od
}
