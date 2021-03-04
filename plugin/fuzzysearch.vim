
let g:fuzzysearch_prompt='fuzzy /'
let g:fuzzysearch_hlsearch=1
let g:fuzzysearch_ignorecase=1
let g:fuzzysearch_max_history = 30
let g:fuzzysearch_match_spaces = 0
let g:fuzzysearch_sensitivity = 0

function! s:getSearchHistory()
  return filter(map(range(1, 20), 'histget("/", v:val-20)'), '!empty(v:val)')
endfunction

fun! FuzzGetHist()
  return s:getSearchHistory()
endfun

function! s:restoreHistory(histList)
  let histLen = len(a:histList)
  let oldSearch = @/
  let i=histLen-g:fuzzysearch_max_history
  if i<0
    let i = 0
  endif
  while i<histLen
    set hlsearch
    let @/=a:histList[i]
    exe "silent! norm! /\<cr>"
    let i+=1
  endwhile
  let @/=oldSearch
endfunction

let s:fuzzySensitivity = '-'
if g:fuzzysearch_sensitivity
  let s:fuzzySensitivity = ','.g:fuzzysearch_sensitivity
endif

if g:fuzzysearch_match_spaces
  let s:fuzzyChars = '.\\{'.s:fuzzySensitivity.'}'
else
  let s:fuzzyChars = '\[^\\ ]\\{'.s:fuzzySensitivity.'}'
endif

function! s:update(startPos, part)
  if a:part != ''
    let charPat = '\([^\\ ]\)'
    let matchPat = substitute(a:part, charPat, '\1'.s:fuzzyChars, 'g')
    let matchPat = substitute(matchPat, s:fuzzyChars.' ', s:fuzzyChars.'.\\{-\}', 'g')

    if g:fuzzysearch_match_spaces
      let matchPat = substitute(matchPat, '\\ ', ' '.s:fuzzyChars, 'g')
    endif


" Don't actually remember what these were for..
      "let matchPat = substitute(matchPat, '} \([^ ]\)', '}.\1', 'g')
      "let matchPat = substitute(matchPat, s:fuzzyChars.' \+', s:fuzzyChars.'.\\{-\}', 'g')


    let matchPat = substitute(matchPat, s:fuzzyChars.'$', '', 'g')
    if matchPat =~ '\.\*\$$'
      let matchPat = substitute(matchPat, '\.\*\$$', '$', '')
    endif
    call setpos('.', a:startPos)
    if g:fuzzysearch_ignorecase==1 && !&ignorecase
      let matchPat = matchPat.'\c'
    endif
    let @/=matchPat
    exe "silent! norm! /\<cr>"
  endif
  set hlsearch
  redraw
  echo g:fuzzysearch_prompt . a:part
endfunc

function! s:fixFuzzHistory(entry)
  let ret = substitute(substitute(a:entry, s:fuzzyChars, '', 'g'), '\.\\{-}', ' ', 'g')
  return ret
endfunction

function! fuzzysearch#start_search()
  let old_hls = &hlsearch

  let oldHist = s:getSearchHistory()
  let histLen = len(oldHist)

  if g:fuzzysearch_hlsearch==1
    set hlsearch
  endif

  let didSearch = 0
  let startPos = getpos('.')
  normal! H
  let startWindow = getpos('.')
  call setpos('.', startPos)
  let c = ''
  let partial = ''
  let histStep = histLen
  let lastSearch = @/
  while 1
    call s:update(startPos, partial)
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
      call s:update(startPos, partial)
      break
    elseif keyCode == 23 "CTRL-W
      let oldPartial = partial
      let partial = substitute(partial, '[^ ]*$', '', '')
      if partial == oldPartial
        let partial = substitute(partial, '[^ ]* *$', '', '')
      endif
    elseif keyCode is# "\<UP>" && histLen > 0
      if histStep>0
        let histStep-=1
      endif
      let partial = s:fixFuzzHistory(oldHist[histStep])
    elseif keyCode is# "\<DOWN>" && histLen > 0
      if histStep<histLen-1
        let histStep+=1
        let partial = s:fixFuzzHistory(oldHist[histStep])
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

  set hlsearch
  redraw

  if g:fuzzysearch_hlsearch==1 && !old_hls
    set nohlsearch
  endif
endfunction

command! -range -nargs=0 FuzzySearch call fuzzysearch#start_search()
