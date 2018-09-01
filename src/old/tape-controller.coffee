###
    Definition of the nodes of the AST
    for the TAPE programming language
###

frequencies = [
    440.00, # A
    466.16, # A#
    493.88, # B
    523.25, # C
    554.37, # C#
    587.37, # D
    622.25, # D#
    659.25, # E
    698.46, # F
    739.99, # F#
    783.99, # G
    830.61, # G#
]

# conver javascript numbers into expected format
CONVERTER =
    signedCell:   null
    unsignedCell: null
    waitUnit:     10   # centiseconds
    indexFrequ:   true # indexed frequencies

    init: (type) ->
        if type == 16
            @waitUnit     = 1     # milliseconds
            @indexFrequ   = false # full range of frequencies
            @signedCell   = new Int16Array  1
            @unsignedCell = new Uint16Array 1
        else
            @signedCell   = new Int8Array   1
            @unsignedCell = new Uint8Array  1
    int: (v) ->
        @signedCell[0] = v
        return @signedCell[0]
    uint: (v) ->
        @unsignedCell[0] = v
        return @unsignedCell[0]
    wait: (n) ->
        @unsignedCell[0] = n
        return @unsignedCell[0] * @waitUnit
    audio: (n) ->
        @signedCell[0] = n
        if @indexFrequ
            n = @signedCell[0]
            l = frequencies.length # (12)
            a = (n % l + l) % l
            b = Math.floor(n / l)
            return frequencies[a] * Math.pow(2, b)
        return @signedCell[0]

### CLASS ###
structs = {}

class structs.Register
    constructor: (type) ->
        # array : store the data
        # byte  : keep number in the expected range
        # index : index the array
        if type == 16
            @array = new Int16Array 16
            @type  = 16
        else
            @array = new Int8Array  8
            @type  = 8

    # access the array
    get: (i) -> @array[CONVERTER.uint(i) % @type]
    set: (i, x) ->
        i = CONVERTER.uint(i) % @type
        @array[i] = x
    incr: (i) ->
        i = CONVERTER.uint(i) % @type
        ++@array[i]
    decr: (i) ->
        i = CONVERTER.uint(i) % @type
        --@array[i]

class structs.Tape
    constructor: (type) ->
        # array : store the data
        # byte  : keep number in the expected range
        # index : index the array
        if type == 16
            @array = new Int16Array 0x10000
            @type  = 16
        else
            @array = new Int8Array 0x100
            @type  = 8

    # make a register for a function
    makeReg: (params) ->
        reg = new structs.Register @type
        length = Math.min @type, params.length
        reg.set(i, params[i]) for i in [0...length]
        return reg

    # access the array
    get: (i) -> @array[CONVERTER.uint i]
    set: (i, x) ->
        i = CONVERTER.uint i
        @array[i] = x
        UPDATE_CELL i, x
    incr: (i) ->
        i = CONVERTER.uint i
        UPDATE_CELL i, ++@array[i]
    decr: (i) ->
        i = CONVERTER.uint i
        UPDATE_CELL i, --@array[i]

### OPERATORS ###
op =
    getName: (fun) -> name if fun2 == fun for name, fun2 of @

# unary
op.NOT   = (a) -> unless a then 0 else 1
op.BNOT  = (a) -> CONVERTER.int(~a)
op.ABS   = (a) -> CONVERTER.int Math.abs a # special case |-128| -> 128 > 127 -> -128
op.NEG   = (a) -> CONVERTER.int(-a)        # we may have only positive numbers
# arithmetic
op.ADD = (a, b) -> CONVERTER.int(a + b)
op.SUB = (a, b) -> CONVERTER.int(a - b)
op.MUL = (a, b) -> CONVERTER.int(a * b)
op.DIV = (a, b) -> CONVERTER.int(a / b) # if b == 0 -> 0
op.MOD = (a, b) -> CONVERTER.int(a % b)
# logical
op.AND  = (a, b) -> if  a &&  b then 1 else 0
op.OR   = (a, b) -> if  a ||  b then 1 else 0
op.XOR  = (a, b) -> if !a != !b then 1 else 0
op.NAND = (a, b) -> if  a &&  b then 0 else 1
op.NOR  = (a, b) -> if  a ||  b then 0 else 1
op.XNOR = (a, b) -> if !a != !b then 0 else 1
# bitwise
op.BAND   = (a, b) -> CONVERTER.int(a & b)
op.BOR    = (a, b) -> CONVERTER.int(a | b)
op.BXOR   = (a, b) -> CONVERTER.int(a ^ b)
op.BNAND  = (a, b) -> CONVERTER.int(~(a & b))
op.BNOR   = (a, b) -> CONVERTER.int(~(a | b))
op.BXNOR  = (a, b) -> CONVERTER.int(~(a ^ b))
op.LSHIFT = (a, b) -> CONVERTER.int(a << b)
op.RSHIFT = (a, b) -> CONVERTER.int(a >> b)
# comparator
op.EQU = (a, b) -> if a == b then 1 else 0
op.DIF = (a, b) -> if a != b then 1 else 0
op.GRT = (a, b) -> if a >  b then 1 else 0
op.LST = (a, b) -> if a <  b then 1 else 0
op.GTE = (a, b) -> if a >= b then 1 else 0
op.LSE = (a, b) -> if a <= b then 1 else 0

### ACTION ###
actions = {}

# wait the given number of milliseconds before continuing
actions.WAIT = (v) ->
    # tape 16-bits : milliseconds
    # tape  8-bits : seconds
    new Promise (resolve) ->
        window.setTimeout resolve, CONVERTER.wait(v)

# play a bell sound of given note
actions.BELL = (v) ->
    # tape 16-bits : full range of frequencies
    # tape  8-bits : indexed frequencies
    PLAY_SOUND CONVERTER.audio v

# print the character in the console
actions.PRINT = (v) ->
    # tape 16-bits : UTF-8
    # tape  8-bits : ASCII
    ADD_CHAR String.fromCharCode(CONVERTER.uint v)

### NODES TYPES ###
types = {}

# classes that define the nodes of our AST
class Node
    link: () -> console.log "not implemented"
    run:  () -> console.log "not implemented"
    string: (tabs) -> strTabs(tabs) + "[UNDEFINED!]\n"

# helper functions to print the AST
strTabs = (tabs) ->
    str  = ""
    str += '\t' for [0 ... tabs]
    return str
stringBlock = (tabs, block) ->
    str  = ""
    str += e.string(tabs) for e in block
    return str
strNode = (tabs, n) ->
    return n.string?(tabs) ? strTabs(tabs) + n + "\n"

# program
class types.Program extends Node
    constructor: (@def, @funcs) ->
        super()
        # correct the definition if there was an error
        if @def != 8 and @def != 16 then @def = 8
        # generate a new tape using the definition provided
        @tape = new structs.Tape @def
        # provide a pointer to the program to every node of the tree
        for name of @funcs
            @funcs[name].link @

    string: (tabs) -> "PROGRAM #{@def}:\n" + stringBlock(0, @funcs)
    run: (...params) -> @funcs[null].run @, params

# declare a function
class types.Function extends Node
    constructor: (@name, @block) ->
        super()
        @returnValue = 0

    link: (@program) ->
        instr.link?(@program, @) for instr in @block
        return null

    string: (tabs) ->
        # print function name and content
        str = if @name != null
        then "FUNCTION #{@name}:\n"
        else "MAIN FUNCTION:\n"
        str += stringBlock tabs, @block
        return str

    run: (params) ->
        # generate a register for the function
        reg = @program.tape.makeReg params
        # execute instructions
        await instr.run reg for instr in @block
        return @returnValue

class types.Return extends Node
    constructor: (@val) ->
        super()
        @func = null

    link: (@program, @func) -> @val.link?(@program, @func)

    string: (tabs) ->
        strTabs(tabs) + "RETURN:\n" + strNode(tabs+1, @val)

    run: (reg) -> @func.returnValue = await @val.run?(reg) ? @val


# access a variable
class types.Variable extends Node
    constructor: (@useReg, @ind) -> super()
    link: (@program, @func) -> @ind.link?(@program, @func)

    string: (tabs) ->
        str = stringTabs(tabs) + if @useReg then "REGISTER:\n" else "TAPE:\n"
        return str + strNode tabs+1, @ind

    index: (reg) -> await @ind.run?(reg) ? @ind

    run: (reg) -> await @get reg

    get: (reg) -> # get the value of the variable
        index = await @index reg
        return if @useReg then reg.get index else @program.tape.get index

    set: (reg, val) ->
        index = await @index reg
        if @useReg then reg.set(index, val) else @program.tape.set(index, val)
        return null

    incr: (reg) ->
        index = await @index reg
        if @useReg then reg.incr index else @program.tape.incr index
        return null

    decr: (reg) ->
        index = await @index reg
        if @useReg then reg.decr index else @program.tape.decr index
        return null

    # special set value for strings
    set_str: (reg, text) ->
        index = await @index reg
        array = if @useReg then reg else @program.tape
        for i in [0...text.length]
            array.set(index+i, text.charCodeAt(i))


# change the value of a cell
class types.Assign extends Node
    constructor: (@var, @val) -> super()
    link: (@program, @func) ->
        @var.link?(@program, @func)
        @val.link?(@program, @func)

    string: (tabs) ->
        strTabs(tabs) + "IN:\n"  + strNode(tabs+1, @var) +
        strTabs(tabs) + "PUT:\n" + strNode(tabs+1, @val)

    run: (reg) ->
        val = await @val.run?(reg) ? @val
        @var.set reg, val


class types.SelfAssign extends Node
    constructor: (@var, @val, @op) -> super()
    link: (@program, @func) ->
        @var.link?(@program, @func)
        @val.link?(@program, @func)

    string: (tabs) ->
        strTabs(tabs) + "CHANGE:\n"                + @var.string(tabs+1) +
        strTabs(tabs) + "BY #{op.getName(@op)}:\n" + @val.string(tabs+1)

    run: (reg) ->
        ind  = @var.index reg
        val1 = @var.get   reg
        val2 = await @val.run?(reg) ? @val
        val3 = @op val1, val2
        @var.set ind, @op(val1, val2)

class types.Increment extends Node
    constructor: (@var) -> super()
    link: (@program, @func) -> @var.link?(@program, @func)
    string: (tabs) -> strTabs(tabs) + "INCREMENT:\n" + @var.string(tabs+1)
    run: (reg) -> await @var.incr reg

class types.Decrement extends Node
    constructor: (@var) -> super()
    link: (@program, @func) -> @var.link?(@program, @func)
    string: (tabs) -> strTabs(tabs) + "DECREMENT:\n" + @var.string(tabs+1)
    run: (reg) -> await @var.decr reg

class types.StringAssign extends Node
    constructor: (@var, @text) -> super()
    link: (@program, @func) -> @var.link?(@program, @func)
    string: (tabs) -> strTabs(tabs) + "ASSIGN STRING '#{text}':\n" + @var.string(tabs+1)
    run: (reg) -> await @var.set_str(reg, @text)


# do an action
class types.Action extends Node
    constructor: (@act, @val) ->
        super()
        @name = switch @act
            when actions.WAIT  then "WAIT"
            when actions.BELL  then "BELL"
            when actions.PRINT then "PRINT"
    link: (@program, @func) -> @val.link?(@program, @func)
    string: (tabs) -> strTabs(tabs) + "ACTION {@act}:\n" + @var.string(tabs+1)
    run: (reg) ->
        val = await @val.run?(reg) ? @val
        return await @act val

# conditional
class types.If extends Node
    constructor: (@conds, @blocks) ->
        super()
        if @conds.length != @blocks.length
            console.log "error in if statement"

    link: (@program, @func) ->
        for cond in @conds
            cond.link?(@program, @func)
        for block in @blocks
            if block?
                instr.link?(@program, @func) for instr in block

    string: (tabs) ->
        str = strTabs(tabs) + "IF:\n"
        i = 0
        while i < @conds.length
            cond  = @conds[i]
            block = @blocks[i++]
            if cond != true # condition declared
                str += strTabs(tabs+1) + "ON CONDITION:\n" + cond.string(tabs+2) + strTabs(tabs+1) + "DO:\n"
            else # no condition
                str += strTabs(tabs+1) + "NO CONDITION DO:\n"
            str += stringBlock(tabs+2, block)
        return str

    run: (reg) ->
        i = 0
        while i < @conds.length
            cond  = @conds[i]
            block = @blocks[i++]
            val = await cond.run?(reg) ? cond
            unless val == 0
                if block?
                    await instr.run reg for instr in block
                    break

# loop
class types.Loop extends Node
    constructor: (@cond, @block, @loopType) ->
        super()
        @stopLoop = 0

    link: (@program, @func) ->
        @cond.link?(@program, @func)
        instr.link?(@program, @func) for instr in @block

    string: (tabs) ->
        return if cond != null
            strTabs(tabs) + "LOOP WHILE:\n" + @cond .string(tabs+1) +
            strTabs(tabs) + "DO:\n"         + @block.string(tabs+1)
        else
            strTabs(tabs) + "LOOP:\n" + @block.string(tabs+1)

    run: (reg) ->
        val = await @cond.run?(reg) ? @cond
        until val == 0
            for instr in @block
                await instr.run?(reg)
                if  @stopLoop !=  0 then break
            if      @stopLoop ==  1 then continue
            else if @stopLoop == -1 then break
            val = await @cond.run?(reg) ? @cond
        @stopLoop = 0 # does it work with recursive function call ?

class types.Break extends Node
    constructor: (@isStop, @loopType) ->
        super()
        @loop = null

    link: (@program, @func) ->

    string: (tabs) -> strTabs(tabs) + "BREAK " + if @isStop then "▼" else "▲"

    run: (reg) ->
        @loop.stopLoop = if @isStop then -1 else 1

# call function
class types.Call extends Node
    constructor: (@name, @params) ->
        super()
        @params = @params or []
        @call = null

    # prepare a pointer to the function to call
    # reduce a part of the AST if useless
    link: (@program, @func) ->
        for name of @program.funcs
            @call = @program.funcs[name] if name == @name
        unless @call? then console.log "function #{@name} not found !"
        @params.splice @program.def, @params.length
        for param in @params
            param.link?(@program, @func)

    string: (tabs) -> strTabs(tabs) + "CALL #{@name} WITH PARAMS:\n" + stringBlock(tabs+1, @params)

    run: (reg) -> await @call.run?(@params)

# apply operations to values
class types.Monadic extends Node
    constructor: (@op, @expr) -> super()

    link: (@program, @func) -> @expr.link?(@program, @func)

    string: (tabs) -> strTabs(tabs) + "MONADIC #{op.getName(@op)}:\n" + @expr.string(tabs+1)

    run: (reg) ->
        val = await @expr.run?(reg) ? @expr
        @op val

class types.Dyadic extends Node
    constructor: (@op, @left, @right) -> super()

    link: (@program, @func) ->
        @left .link?(@program, @func)
        @right.link?(@program, @func)

    string: (tabs) ->
        strTabs(tabs  ) + "DYADIC #{op.getName(@op)}:\n" +
        strTabs(tabs+1) + "LEFT:\n"  + strExpr(tabs+2, @left ) +
        strTabs(tabs+1) + "RIGHT:\n" + strExpr(tabs+2, @right)

    run: (reg) ->
        left  = await @left.run?(reg)  ? @left
        right = await @right.run?(reg) ? @right
        @op left, right

### FORMATERS ###
formaters = {}

# store our functions into the global scope
GLOBAL = exports ? this
GLOBAL.TAPE = {op, types, formaters, actions, structs}

# program structure
formaters._program = (def, funcs) ->
    CONVERTER.init def
    program = new types.Program(def, funcs)
    GLOBAL.TAPE.program = program
    return program

# gather functions
formaters.namedGather = (map, element) ->
    map = map or {}
    map[element.name] = element
    return map

# gather a list of elements
formaters.gather = (list, element) ->
    list = list or []
    list.push element
    return list

# conditionals
formaters._if = (cond, block, elses) ->
    if elses?
        elses.conds .unshift cond
        elses.blocks.unshift block
    else return new types.If([cond], [block])
    return new types.If(elses.conds, elses.blocks)
formaters._elseif = (cond, block, elses) ->
    if elses?
        elses.conds .unshift cond
        elses.blocks.unshift block
    else return
        conds:  [cond]
        blocks: [block]
    return elses
formaters._else = (block) ->
    return
        conds:  [true]
        blocks: [block]

formaters._callDyadic = (name, params, param) ->
    fullList = @_callDyadicList name, params, param
    delete params.name
    return new types.Call name, params

formaters._callDyadicList = (name, params, param) ->
    if params instanceof Array # list of params
        if params.name == name # same operator
            params.push param
            return params
        else # different operators
            newList = [new types.Call(params.name, params), param]
            delete params.name
            newList.name = name
            return newList
    else # single param
        newList = [params, param]
        newList.name = name
        return newList

# loops
findBreaks = (lp, block) ->
    for instr in block
        if instr is types.If
            findBreaks(lp.loopType, b) for b in instr.blocks
        else if instr is types.Break and instr.loopType == lp.loopType
            instr.loop = lp
        else if instr is types.Loop  and instr.loopType != lp.loopType
            findBreaks(lp.loopType, instr.block)
formaters._loop = (type, cond, block) ->
    lp = new types.Loop(cond, block, type)
    findBreaks lp, block
    return lp

# parse number
formaters._number = (type, value) ->
    val = value.substring 2
    return switch type
        when "decimal"     then parseInt(value)
        when "octal"       then parseInt(val,  8)
        when "hexadecimal" then parseInt(val, 16)
        when "binary"      then parseInt(val,  2)
        when "character"   then value.charCodeAt(1)
        else 0