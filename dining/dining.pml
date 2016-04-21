
#define N 3
#define MEALS 3

byte forks[N];
bool dirty[N];
bool request[N];
bool inCS[N];
int stillHungry = N;
int totCS = 0;


init {
    atomic {
        int i;
        for (i : 0 .. N - 1) {
            dirty[i] = true;
            forks[i] = i;
            request[i] = false;
            inCS[i] = false;
            run phil(i);
        }
    }
}

proctype phil (int i) {
    bool hungry = false;
    bool thinking = true;
    bool eating = false;
    int left = i;
    int right = (i + 1) % N;
    int mycount = MEALS;
    int first = ((left < right) -> left : right);
    int second = ((first == left) -> right : left);
    int left_person = ((i == 0) -> N - 1 : i - 1);
    int right_person = (i + 1) % N;

    do 
        :: if
            :: (request[left] == true && forks[left] == i && (dirty[left] || thinking)) ->
                dirty[left] = false;
                forks[left] = left_person;
                request[left] = false;
                
            :: (request[right] == true && forks[right] == i && (dirty[right] || thinking)) ->
                dirty[right] = false;
                forks[right] = right_person;
                request[right] = false;

            :: (stillHungry == 0) ->
                assert (totCS == N * MEALS);
                break;

            :: (mycount > 0) ->
                if
                ::  (thinking) -> 
                    hungry = true;
                    thinking = false;

                ::  (hungry) ->
                    do 
                        ::  (forks[first] == i && forks[second] == i) ->
                            break;

                        ::  (request[left] == true && forks[left] == i && dirty[left]) ->
                            dirty[left] = false;
                            forks[left] = left_person;
                            request[left] = false;
                
                        ::  (request[right] == true && forks[right] == i && dirty[right]) ->
                            dirty[right] = false;
                            forks[right] = right_person;
                            request[right] = false;
                        :: else ->
                        if
                        ::  (forks[first] != i && request[first] == false) ->
                            request[first] = true;
                        
                        ::  (forks[second] != i && forks[first] == i && request[second] == false) ->
                            request[second] = true;
                        :: else -> skip;
                        fi
                    od
                    eating = true;
                    hungry = false;
                    
                    atomic {
                        inCS[i] = true;
                        assert ( inCS[left_person] == false );
                        assert ( inCS[right_person] == false );
                    }

                    mycount = mycount - 1;
                    atomic{ totCS = totCS + 1; }
                    if :: (mycount == 0) ->
                        atomic { stillHungry = stillHungry - 1; }
                    :: else -> skip;
                    fi
                    thinking = true;
                    eating = false;
                    dirty[left] = true;
                    dirty[right] = true;
                    inCS[i] = false;

                fi
        fi
    od
}
