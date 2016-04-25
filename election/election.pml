#define N 4
#define MAX_SKIPS 2

byte myleader[N];
bool leader_found[N]
bool awake[N]
//mtype gary = {election, leader};
#define election false
#define leader true
chan msgs[N] = [3] of {bool, byte};

init {
    chan ids = [N] of {byte};
    atomic {
        int i;
        int j;
        for (i : 0 .. N-1) {
            ids ! i;
        }

        for (i : 0 .. N-1) {
            ids ?? j;
            run server(i, j);
            run responder(i, j);
        }
    }
}

proctype responder(byte i; byte rank) {
    byte other;
    byte next = (i + 1) % N;

    do 
        :: msgs[i] ? election, other ->
            atomic {
                if 
                    :: (other > rank) ->
                        msgs[next] ! election, other;
                    :: (other < rank && !awake[i]) ->
                        msgs[next] ! election, rank;
                    :: (other == rank) ->
                        msgs[next] ! leader, rank;
                    :: else -> skip;
                fi
                awake[i] = true;
            }
       
        :: msgs[i] ? leader, other ->
            atomic {
                myleader[i] = other;
                leader_found[i] = true;
            }
            if
                :: (other != rank) -> msgs[next] ! leader, other;
                :: else -> skip;
            fi
            break;
            //(other == i -> skip : msgs[next] ! leader, other);
    od

}

proctype server(byte i; byte rank) {
    byte skipcount = 0;
    do
        :: atomic {(!awake[i]) ->
                awake[i] = true;
                byte right = (i + 1) % N;
                msgs[right] ! election, rank;
            }

        :: (skipcount < MAX_SKIPS) -> skipcount = skipcount + 1;
        :: (leader_found[i]) -> break;
    od

    byte that;
    assert(myleader[i] == N - 1)
progress: for (that : 0 .. N-1) {
        if 
            :: (leader_found[that]) ->
                assert(myleader[i] == myleader[that]);
            :: else -> skip;
        fi
    }
}
