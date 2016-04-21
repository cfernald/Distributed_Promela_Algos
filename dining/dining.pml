
#define N 5
#define MEALS 4

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


    do 
        :: if
            :: (!eating && request[left] == true && forks[left] == i && (dirty[left] || thinking)) ->
                dirty[left] = false;
                int owner = ((i == 0) -> N - 1 : i - 1);
                forks[left] = owner;
                request[left] = false;
                
            :: (!eating && request[right] == true && forks[right] == i && (dirty[right] || thinking)) ->
                dirty[right] = false;
                forks[right] = (i + 1) % N;
                request[right] = false;

            :: (eating) ->
                inCS[i] = true;
                if :: (mycount == 0) ->
                        atomic { stillHungry = stillHungry - 1; }
                   :: else -> skip;
                fi
                atomic{ totCS = totCS + 1; }
                printf("%d\n", mycount);
                mycount = mycount - 1;
                thinking = true;
                eating = false;
                dirty[left] = true;
                dirty[right] = true;
                inCS[i] = false;

            :: (stillHungry == 0) ->
                break;

            :: (mycount > 0) ->
                if
                ::  (thinking) -> 
                    hungry = true;
                    thinking = false;

                ::  (hungry) ->
                    do
                        ::  (forks[first] != i && request[first] == false) ->
                            request[first] = true;
                        ::  (forks[second] != i && forks[first] == i && request[second] == false) ->
                            request[second] = true;
                        :: (forks[first] == i && forks[second] == i) ->
                            break;

                        :: (!eating && request[left] == true && forks[left] == i && dirty[left]) ->
                            dirty[left] = false;
                            int owner2 = ((i == 0) -> N - 1 : i - 1);
                            forks[left] = owner2;
                            request[left] = false;
                
                        :: (!eating && request[right] == true && forks[right] == i && dirty[right]) ->
                            dirty[right] = false;
                            forks[right] = (i + 1) % N;
                            request[right] = false;

                    od
                    eating = true;
                    hungry = false;
                fi
        fi
    od


}
