use coroutine
import structs/[ArrayList, LinkedList], os/Time, coroutine/Coro

coros := LinkedList<Coroutine> new()
deadCoros := LinkedList<Coroutine> new()

CoroutineStartInfo: class {
    c: Func
    init: func (=c) {}
}
newCoros  := LinkedList<CoroutineStartInfo> new()

mainCoro := Coroutine new()
currentCoro := mainCoro

atexit(scheduler)

GC_add_roots: extern func (Pointer, Pointer)
GC_remove_roots: extern func (Pointer, Pointer)
GC_stackbottom: extern Pointer

scheduler: func {
    mainCoro initializeMainCoro()

    while(true) {
        i := 0
        for(coro in coros) {
            //"Main coro %p dispatching to coro %p, %d/%d" printfln(mainCoro, coro, i + 1, coros size())
            switchTo(coro)
            if(!deadCoros isEmpty() || !newCoros isEmpty()) {
                //"Dead coros / new coros, breaking!" println()
                break
            }
            i += 1
        }

        if(!newCoros isEmpty()) {
            //"Adding %d new coros" printfln(newCoros size())
            for(info in newCoros)  {
                //"Adding coro!" println()
                newCoro := Coroutine new()
                coros add(newCoro)
                oldCoro := currentCoro
                currentCoro = newCoro

                oldCoro startCoro(currentCoro, ||
                    stackBase := (currentCoro as CoroutineStruct*)@ stack
                    stackSize := (currentCoro as CoroutineStruct*)@ allocatedStackSize
                    oldStackBase := GC_stackbottom
                    // Adjust the stackbottom and add our coroutine's stack as a root for the GC
                    GC_stackbottom = stackBase
                    GC_add_roots(stackBase, stackBase + stackSize)
                    //"Coro started!" println()
                    info c()
                    //"Terminating a coro!" printfln()
                    GC_stackbottom = oldStackBase
                    GC_remove_roots(stackBase, stackBase + stackSize)
                    terminate()
                )
            }
            newCoros clear()
        }

        if(!deadCoros isEmpty()) {
            //"Cleaning up %d dead coros" printfln(deadCoros size())
            for(deadCoro in deadCoros) { coros remove(deadCoro) }
            deadCoros clear()
        }
    }
}

Channel: class <T> {

    //queue := LinkedList<T> new()
    queue := ArrayList<T> new()

    send: func (t: T) {
        //"Sending %d" printfln(t as Int)
        queue add(t)
        while(queue size() > 100) {
            //"Queue filled, switching to %p. (Coro = %p)" printfln(mainCoro, currentCoro)
            yield()
        }
    }

    recv: func -> T {
        while(true) {
            if(!queue isEmpty()) {
                val := queue removeAt(0)
                return val
            }
            //"Queue empty, switching to %p. (Coro = %p)" printfln(mainCoro, currentCoro)
            yield()
        }
        // yay hacks
        null
    }

}

operator << <T> (c: Channel<T>, t: T) {
    c send(t)
}

operator ! <T> (c: Channel<T>) -> T {
    c recv()
}

terminate: func {
    deadCoros add(currentCoro)
    yield()
}

yield: func {
    switchTo(mainCoro)
}

switchTo: func (newCoro: Coroutine) {
    oldCoro := currentCoro
    currentCoro = newCoro
    oldCoro switchTo(currentCoro)
}

go: func (c: Func) {
    newCoros add(CoroutineStartInfo new(c))
}

make: func <T> (T: Class) -> Channel<T> {
    Channel<T> new()
}


