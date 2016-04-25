#define N 4
#define MAX_SKIPS 1

byte myleader[N];
bool leader_found[N]
bool awake[N]
//mtype gary = {election, leader};
#define election false
#define leader true
chan msgs[N] = [3] of {bool, byte};

init {
    atomic {
        int i;
        for (i : 0 .. N-1) {
            run server(i);
            run responder(i);
        }
    }
}

proctype responder(byte i) {
    byte other;
    byte next = (i + 1) % N;

   do 
        :: msgs[i] ? election, other ->
            atomic {
                if 
                    :: (other > i /*&& awake[i]*/) ->
                        msgs[next] ! election, other;
                    :: (other < i && !awake[i]) ->
                        msgs[next] ! election, i;
                    :: (other == i) ->
                        msgs[next] ! leader, i;
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
                :: (other != i) -> msgs[next] ! leader, other;
                :: else -> skip;
            fi
            break;
            //(other == i -> skip : msgs[next] ! leader, other);
    od

}

proctype server(byte i) {
    byte skipcount = 0;
    do
        :: atomic {(!awake[i]) ->
                awake[i] = true;
                byte right = (i + 1) % N;
                msgs[right] ! election, i;
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
