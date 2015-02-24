
let g:fuzzy_search_prompt='fuzzy /'

function s:update(part)
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
    exe "silent! norm! /" . matchPat . "\<cr>"
  endif
  redraw
  echo g:fuzzy_search_prompt . a:part
endfunc


function! fuzzy_search#start_search()
  "let old_is = &incsearch
  "let old_hls = &hlsearch
  "set incsearch hlsearch

  let c = ''
  let partial = ''
  while 1
    call s:update(partial)
    let keyCode = getchar()
    let c = nr2char(keyCode)
    if c == "\<cr>"
      if partial == ''
        exe "silent! norm! /".@/."\<cr>"
      endif
      break
    elseif c == "\<esc>"
      let partial = ''
      call s:update(partial)
      break
    elseif keyCode == 23 "CTRL-W
     let partial = substitute(partial, '[ ]*[^ ]*$', '', '')
    elseif c == ''
      let partial = partial[:-2]
    else
      let partial .= c
    endif
  endwhile
  "let &incsearch = old_is
  "let &hlsearch = old_hls
  "exe "silent! norm! /".@/."\<cr>"
endfunction


command! -range -nargs=0 FuzzySearch call fuzzy_search#start_search()
