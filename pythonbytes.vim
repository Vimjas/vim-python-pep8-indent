" Copy bytes from hdima/python-syntax so we can test without bundling the
" whole thing.
syn region pythonBytes start=+[bB]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesError,pythonBytesContent,@Spell  
syn region pythonBytes start=+[bB]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesError,pythonBytesContent,@Spell  
syn region pythonBytes start=+[bB]"""+ end=+"""+ keepend contains=pythonBytesError,pythonBytesContent,pythonDocTest2,pythonSpaceError,@Spell  
syn region pythonBytes start=+[bB]'''+ end=+'''+ keepend contains=pythonBytesError,pythonBytesContent,pythonDocTest,pythonSpaceError,@Spell
syn match pythonBytesError ".\+" display contained  
syn match pythonBytesContent "[\u0000-\u00ff]\+" display contained contains=pythonBytesEscape,pythonBytesEscapeError
syn match pythonBytesEscape +\\[abfnrtv'"\\]+ display contained
syn match pythonBytesEscape "\\\o\o\=\o\=" display contained
syn match pythonBytesEscapeError "\\\o\{,2}[89]" display contained
syn match pythonBytesEscape "\\x\x\{2}" display contained
syn match pythonBytesEscapeError "\\x\x\=\X" display contained
