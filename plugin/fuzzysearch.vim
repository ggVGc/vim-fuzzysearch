
let g:fuzzysearch_prompt='fuzzy /'
let g:fuzzysearch_hlsearch=1
let g:fuzzysearch_ignorecase=1
let g:fuzzysearch_max_history = 30

function! s:getSearchHistory()
  redir => l:histRedir
  silent history /
  redir END
  let histRedir = substitute(l:histRedir, '#  search history', '', '')
  "let histRedir = substitute(histRedir, '1  ', '', '')
  let histList = split(histRedir)
  let histList[-2] = histList[-1]
  let histList = filter(histList, 'v:key%2==1')
  return histList
endfunction

function! s:restoreHistory(histList)
  let histLen = len(a:histList)
  let oldSearch = @/
  let i=histLen-g:fuzzysearch_max_history
  if i<0
    let i = 0
  endif
  while i<histLen
    let @/=a:histList[i]
    exe "silent! norm! /\<cr>"
    let i+=1
  endwhile
  let @/=oldSearch
endfunction

function! s:update(startPos, part, ignoreCase)
  if a:part == ''
    "nohlsearch
  else
    if a:ignoreCase
      let matchPat = substitute(a:part, '\(\w\)', '[\U\1\L\1]\\w\\{-}', 'g')
    else
      let matchPat = substitute(a:part, '\(\w\)', '\1\\w\\{-}', 'g')
    endif
    let matchPat = substitute(matchPat, '\\w\\{-}$', '', 'g')
    let matchPat = substitute(substitute(matchPat, ' ', '.\\{-\}', 'g'), '\.\*$', '', '')
    if matchPat =~ '\.\*\$$'
      let matchPat = substitute(matchPat, '\.\*\$$', '$', '')
    endif
    call setpos('.', a:startPos)
    let @/=matchPat
    exe "silent! norm! /\<cr>"
  endif
  redraw
  echo g:fuzzysearch_prompt . a:part
endfunc


function! fuzzysearch#start_search()
  let old_hls = &hlsearch
  let old_ic= &ignorecase

  let oldHist = s:getSearchHistory()
  let histLen = len(oldHist)
  let igCase = g:fuzzysearch_ignorecase==1 && &ignorecase

  if g:fuzzysearch_hlsearch==1
    set hlsearch
  endif
  if g:fuzzysearch_ignorecase==1
    set ignorecase
  endif

  let didSearch = 0
  let startPos = getpos('.')
  normal! H
  let startWindow = getpos('.')
  let c = ''
  let partial = ''
  let histStep = histLen
  let lastSearch = @/
  while 1
    call s:update(startPos, partial, igCase)
    let keyCode = getchar()
    let c = nr2char(keyCode)
    if c == "\<cr>"
      let didSearch = 1
      if partial == ''
        let @/=lastSearch
      endif
      break
    elseif c == "\<esc>"
      let partial = ''
      call s:update(startPos, partial, igCase)
      break
    elseif keyCode == 23 "CTRL-W
     let partial = substitute(partial, '[ ]*[^ ]*$', '', '')
    elseif keyCode is# "\<UP>"
      if histStep>0
        let histStep-=1
      endif
        let partial = substitute(substitute(oldHist[histStep], '\\w\*', '', 'g'), '\.\*', ' ', 'g')
        if igCase
          let partial = substitute(partial, '\[\u\(\l\)\]', '\1', 'g')
        endif
    elseif keyCode is# "\<DOWN>"
      if histStep<histLen-1
        let histStep+=1
        let partial = substitute(substitute(oldHist[histStep], '\\w\*', '', 'g'), '\.\*', ' ', 'g')
        if igCase
          let partial = substitute(partial, '\[\u\(\l\)\]', '\1', 'g')
        endif
      else
        let histStep=histLen
        let partial = ''
      endif
    elseif keyCode is# "\<BS>"
      if partial==''
        break
      endif
      let partial = partial[:-2]
    else
      let partial .= c
    endif
  endwhile

  call s:restoreHistory(oldHist)
  call setpos('.', startWindow)
  normal! zt
  call setpos('.', startPos)

  if didSearch == 1
    exe "silent! norm! /".@/."\<cr>"
  endif

  if g:fuzzysearch_hlsearch==1
    let &hlsearch = old_hls
  endif
  if g:fuzzysearch_ignorecase==1
    let &ignorecase = old_ic
  endif
endfunction


command! -range -nargs=0 FuzzySearch call fuzzysearch#start_search()
