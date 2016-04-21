
#define N 3
#define MAX_REQS 5

#define TS_MULT 100

chan requests[N] = [N] of {int};
int acks[N];
int inCS = 0;
int procsRunning = N;
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
    int front, frontPid, frontTS;
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
            :: (requested) -> skip;
        fi

        if
            :: (nempty(requests[p])) ->
                requests[p] ? front;
                if
                    ::  (front % TS_MULT == p)->
                        requests[p] !! front;
                    ::  (front % TS_MULT != p) ->
                        frontPid = front % TS_MULT;
                        frontTS = front / TS_MULT;
                        ts = ((frontTS > ts) -> frontTS : ts);
                        ts = ts + 1;
                        atomic { acks[frontPid] = acks[frontPid] + 1; }
                fi
            :: (empty(requests[p])) -> skip;
        fi

        if
            :: (acks[p] == N - 1) ->
                imInCS = true;
                requested = false;
                acks[p] = 0;
                atomic {
                    inCS = inCS + 1;
progress1:          assert (inCS == 1);
                }
            :: (acks[p] != N - 1) -> skip;  
        fi
        
        :: (imInCS) ->
            // CS code
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
            
            // Check to see if we are done with CS requests
            if  :: reqs >= MAX_REQS ->
                    atomic { procsRunning = procsRunning - 1; }
                    do 
                        :: (procsRunning > 0) ->
                        if
                            :: nempty(requests[p]) ->
                            requests[p] ? front;
                            if
                                ::  (front % TS_MULT != p) ->
                                    frontPid = front % TS_MULT;
                                    frontTS = front / TS_MULT;
                                    ts = ((frontTS > ts) -> frontTS : ts);
                                    ts = ts + 1;
                                    atomic { acks[frontPid] = acks[frontPid] + 1; }
                                :: else -> skip;
                            fi
                            :: empty(requests[p]) -> skip;
                        fi
                        :: (procsRunning <= 0) ->
                            break;
                    od
                    break;
           
                :: reqs < MAX_REQS -> skip;
            fi
    od
}
