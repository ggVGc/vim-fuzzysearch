
let g:fuzzysearch_prompt='fuzzy /'
let g:fuzzysearch_incsearch=1
let g:fuzzysearch_hlsearch=1

function s:update(startPos, part)
  if a:part == ''
    "nohlsearch
  else
    let matchPat = substitute(a:part, '\(\w\)', '\1\\w*', 'g')
    let matchPat = substitute(matchPat, '\\w\*$', '', 'g')
    let matchPat = substitute(substitute(matchPat, ' ', '.*', 'g'), '\.\*$', '', '')
    if matchPat =~ '\.\*\$$'
      let matchPat = substitute(matchPat, '\.\*\$$', '$', '')
    endif
    let @/=matchPat
    call setpos('.', a:startPos)
    exe "silent! norm! /" . matchPat . "\<cr>"
  endif
  redraw
  echo g:fuzzysearch_prompt . a:part
endfunc


function! fuzzysearch#start_search()
  let old_is = &incsearch
  let old_hls = &hlsearch
  if g:fuzzysearch_incsearch==1
    set incsearch
  endif
  if g:fuzzysearch_hlsearch==1
    set hlsearch
  endif

  let startPos = getcurpos()
  let c = ''
  let partial = ''
  while 1
    call s:update(startPos, partial)
    let keyCode = getchar()
    let c = nr2char(keyCode)
    if c == "\<cr>"
      if partial == ''
        call setpos('.', startPos)
        exe "silent! norm! /".@/."\<cr>"
      endif
      break
    elseif c == "\<esc>"
      let partial = ''
      call s:update(startPos, partial)
      break
    elseif keyCode == 23 "CTRL-W
     let partial = substitute(partial, '[ ]*[^ ]*$', '', '')
    elseif c == ''
      let partial = partial[:-2]
    else
      let partial .= c
    endif
  endwhile

  if g:fuzzysearch_incsearch==1
    let &incsearch = old_is
  endif
  if g:fuzzysearch_hlsearch==1
    let &hlsearch = old_hls
  endif
  call setpos('.', startPos)
  exe "silent! norm! /".@/."\<cr>"
  redraw
endfunction


command! -range -nargs=0 FuzzySearch call fuzzysearch#start_search()
