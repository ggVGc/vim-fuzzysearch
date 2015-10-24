
let g:fuzzysearch_prompt='fuzzy /'
let g:fuzzysearch_hlsearch=1
let g:fuzzysearch_ignorecase=1
let g:fuzzysearch_max_history = 30

function! s:getSearchHistory()
  redir => l:histRedir
  silent history /
  redir END
  let histRedir = substitute(l:histRedir, '#  search history', '', '')
  let histList = split(histRedir)
  if len(histList) > 0
    let histList[-2] = histList[-1]
    let histList = filter(histList, 'v:key%2==1')
  endif
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
    set hlsearch
    let @/=a:histList[i]
    exe "silent! norm! /\<cr>"
    let i+=1
  endwhile
  let @/=oldSearch
endfunction

let s:matchSeparateWords=0

if s:matchSeparateWords
  let s:fuzzyChars = '\\w\\{-}'
else
  let s:fuzzyChars = '.\\{-}'
endif

function! s:update(startPos, part)
  if a:part != ''
    let charPat = '\([^\\ ]\)'
    let matchPat = substitute(a:part, charPat, '\1'.s:fuzzyChars, 'g')
    let matchPat = substitute(matchPat, s:fuzzyChars.' ', s:fuzzyChars.'.\\{-\}', 'g')

    if s:matchSeparateWords == 1
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
