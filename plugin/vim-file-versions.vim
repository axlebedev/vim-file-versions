if exists("g:loaded_js_fileversions") || &cp || v:version < 700
    finish
endif
let g:loaded_js_fileversions = 1

function! s:getTargetHash(hashList, curHash, toNext) abort
    if (a:curHash ==# 'HEAD')
        return len(a:hashList) > 1 ? a:hashList[1] : -1
    endif

    let curIndex = index(a:hashList, a:curHash)
    if (curIndex == -1)
        return -1
    endif

    if (curIndex == len(a:hashList) - 1 && !a:toNext)
        return -1
    endif

    if (curIndex == 0 && a:toNext)
        return -1
    endif

    if (a:toNext)
        return a:hashList[curIndex - 1]
    endif
    return a:hashList[curIndex + 1]
endfunction

function! s:getFileName() abort
    let fileName = @%
    if (fileName =~ '^fugitive')
        return fugitive#buffer().path()
    endif
    return fileName
endfunction

function! s:StartFileVersions() abort
    let fileName = s:getFileName()
    let hashList = split(system('git log --follow --pretty="%H" ' . fileName))
    let curHash = fugitive#buffer().containing_commit()
    let prevHash = s:getTargetHash(hashList, curHash, 0)

    tabnew
    execute 'edit!' fileName
    execute 'Gedit ' (curHash . ':%')
    execute 'Gdiff ' prevHash
endfunction

function! s:ContinueFileVersions(toNext) abort
    if (a:toNext)
        wincmd h
    else
        wincmd l
    endif
    bdelete

    let fileName = s:getFileName()
    let hashList = split(system('git log --follow --pretty="%H" ' . fileName))
    let curHash = fugitive#buffer().containing_commit()
    let targetHash = s:getTargetHash(hashList, curHash, a:toNext)

    execute 'Gdiff ' targetHash
endfunction

function! FileVersionNext() abort
    if (!&diff)
        call s:StartFileVersions()
    else
        call s:ContinueFileVersions(0)
    endif
endfunction

function! FileVersionPrev() abort
    if (!&diff)
        call s:StartFileVersions()
    else
        call s:ContinueFileVersions(1)
    endif
endfunction
